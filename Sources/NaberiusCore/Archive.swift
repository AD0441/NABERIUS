import Foundation
import CryptoKit
import Compression

/// Single-file container: magic, big-endian uncompressed size, SHA-256, LZFSE JSON.
public enum NabArchive {
    public static let maxSize = 128 * 1024 * 1024
    private static let magic = Data("NABERIUS\u{0}1\n".utf8)
    public static func encode(_ document: NabDocument) throws -> Data {
        var stored=document
        stored.schemaVersion=max(stored.schemaVersion,stored.minimumSchemaVersion)
        try validate(stored)
        let e = JSONEncoder(); e.outputFormatting = [.sortedKeys]; e.dateEncodingStrategy = .iso8601
        let json = try e.encode(stored)
        guard json.count <= maxSize else { throw NabError.invalid(L10n.text("El documento supera el límite de 128 MB.")) }
        var compressed = Data(count: json.count + 65536)
        let size = compressed.withUnsafeMutableBytes { output in json.withUnsafeBytes { input in
            compression_encode_buffer(output.bindMemory(to:UInt8.self).baseAddress!, output.count, input.bindMemory(to:UInt8.self).baseAddress!, input.count, nil, COMPRESSION_LZFSE)
        }}
        guard size > 0 else { throw NabError.invalid(L10n.text("No se pudo comprimir el documento.")) }
        compressed.count = size
        var data = magic
        var length = UInt64(json.count).bigEndian
        withUnsafeBytes(of:&length) { data.append(contentsOf:$0) }
        data.append(contentsOf:SHA256.hash(data:json)); data.append(compressed)
        return data
    }
    public static func decode(_ data: Data) throws -> NabDocument {
        let offset = magic.count + 8 + 32
        guard data.count > offset, data.count <= maxSize, data.starts(with:magic) else { throw NabError.invalid(L10n.text("El archivo no es un documento .nab válido o usa una versión no admitida.")) }
        let bytes = data[magic.count..<(magic.count+8)]
        let length = bytes.reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
        guard length > 0, length <= maxSize else { throw NabError.invalid(L10n.text("El documento declara un tamaño inseguro.")) }
        var json = Data(count:Int(length))
        let source = data.subdata(in:offset..<data.count)
        let size = json.withUnsafeMutableBytes { output in source.withUnsafeBytes { input in
            compression_decode_buffer(output.bindMemory(to:UInt8.self).baseAddress!, output.count, input.bindMemory(to:UInt8.self).baseAddress!, input.count, nil, COMPRESSION_LZFSE)
        }}
        guard size == length, Data(SHA256.hash(data:json)) == data.subdata(in:magic.count+8..<offset) else { throw NabError.invalid(L10n.text("El archivo está incompleto o dañado. Abre una copia de recuperación.")) }
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601
        let document = try d.decode(NabDocument.self,from:json); try validate(document); return document
    }
    public static func validate(_ d: NabDocument) throws {
        guard [1,2,3].contains(d.schemaVersion) else { throw NabError.invalid(L10n.text("Esta versión de documento requiere una versión más reciente de Naberius.")) }
        guard d.blocks.count <= 100_000, d.assets.count <= 2000, d.nodes.count <= 50_000 else { throw NabError.invalid(L10n.text("El documento contiene demasiados elementos.")) }
        guard Set(d.blocks.map(\.id)).count == d.blocks.count, Set(d.nodes.map(\.id)).count == d.nodes.count, Set(d.assets.map(\.id)).count == d.assets.count, Set(d.references.map(\.id)).count == d.references.count else { throw NabError.invalid(L10n.text("El documento contiene identificadores duplicados.")) }
        guard d.assets.allSatisfy({ $0.data.count <= 32*1024*1024 && ($0.originalData?.count ?? 0) <= 32*1024*1024 }), d.assets.reduce(0, { $0 + $1.data.count + ($1.originalData?.count ?? 0) }) <= 80*1024*1024 else { throw NabError.invalid(L10n.text("Los recursos superan el tamaño admitido (32 MB por imagen; 80 MB en total).")) }
        guard d.template.fontSize.isFinite, (8...36).contains(d.template.fontSize), d.template.marginMM.isFinite, (10...50).contains(d.template.marginMM), d.template.lineSpacing.isFinite, (1...3).contains(d.template.lineSpacing), d.template.font.count <= 100 else { throw NabError.invalid(L10n.text("La plantilla contiene valores fuera de rango.")) }
        try d.template.package?.validate()
        let layout = d.template.effectiveLayout
        guard [1,2].contains(layout.columnCount),layout.columnSeparationMM.isFinite,(3...20).contains(layout.columnSeparationMM),[layout.marginTopMM,layout.marginBottomMM,layout.marginLeftMM,layout.marginRightMM].compactMap({$0}).allSatisfy({$0.isFinite && (10...60).contains($0)}) else {throw NabError.invalid(L10n.text("Las columnas o los márgenes del documento están fuera de rango."))}
        guard layout.paragraphIndentMM.isFinite, (0...20).contains(layout.paragraphIndentMM), layout.paragraphSpacingPT.isFinite, (0...30).contains(layout.paragraphSpacingPT), [layout.header, layout.footer, layout.recipient, layout.opening, layout.closing].allSatisfy({ $0.count <= 4000 }) else { throw NabError.invalid(L10n.text("El diseño documental contiene valores fuera de rango.")) }
        for n in d.nodes {
            guard n.width.isFinite, (32...1600).contains(n.width), n.rows.count <= 200, n.rows.allSatisfy({ $0.count <= 30 }) else { throw NabError.invalid(L10n.text("Un objeto contiene dimensiones fuera de rango.")) }
            if n.kind == .table {
                guard let first = n.rows.first, !first.isEmpty, n.rows.allSatisfy({ $0.count == first.count }) else { throw NabError.invalid(L10n.text("La tabla tiene filas incompatibles.")) }
            }
        }
        let nodeIDs = Set(d.nodes.map(\.id)), assetIDs = Set(d.assets.map(\.id))
        guard d.blocks.flatMap(\.runs).allSatisfy({ $0.nodeID == nil || nodeIDs.contains($0.nodeID!) }), d.nodes.allSatisfy({ $0.assetID == nil || assetIDs.contains($0.assetID!) }) else { throw NabError.invalid(L10n.text("Faltan objetos o recursos dentro del documento.")) }
    }
    public static func fingerprint(_ data: Data) -> Data { Data(SHA256.hash(data:data)) }
}

public actor DocumentDisk {
    private var journalStates:[UUID:NabDocument]=[:]
    public init() {}
    public func read(_ url: URL) throws -> (NabDocument, Data) {
        let attrs = try FileManager.default.attributesOfItem(atPath:url.path)
        guard (attrs[.size] as? NSNumber)?.intValue ?? 0 <= NabArchive.maxSize else { throw NabError.invalid(L10n.text("El archivo es demasiado grande.")) }
        let data = try Data(contentsOf:url,options:.mappedIfSafe)
        return (try NabArchive.decode(data),NabArchive.fingerprint(data))
    }
    public func save(_ document: NabDocument, to url: URL, expected: Data?) throws -> Data {
        if let expected {
            guard let current = try? Data(contentsOf:url,options:.mappedIfSafe), NabArchive.fingerprint(current) == expected else { throw NabError.conflict }
        }
        let data = try NabArchive.encode(document)
        try data.write(to:url,options:.atomic)
        return NabArchive.fingerprint(data)
    }
    public func recovery(_ document: NabDocument, directory: URL) throws {
        let latest=journalStates[document.id].map{$0.modified>document.modified ? $0 : document} ?? document
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        let url=directory.appendingPathComponent(document.id.uuidString+".nab")
        try NabArchive.encode(latest).write(to:url,options:.atomic)
        let journal=url.appendingPathExtension("journal")
        if FileManager.default.fileExists(atPath:journal.path){try FileManager.default.removeItem(at:journal)}
        journalStates[document.id]=latest
        if journalStates.count>3,let oldest=journalStates.values.filter({$0.id != document.id}).min(by:{$0.modified<$1.modified}){journalStates.removeValue(forKey:oldest.id)}
    }
    public func journal(_ document:NabDocument,directory:URL)throws {
        guard let old=journalStates[document.id] else{try recovery(document,directory:directory);return}
        guard document.modified>=old.modified else{return}
        let encoder=JSONEncoder();encoder.dateEncodingStrategy = .millisecondsSince1970
        var data=try encoder.encode(RecoveryDelta(from:old,to:document));data.append(10)
        let url=directory.appendingPathComponent(document.id.uuidString+".nab").appendingPathExtension("journal")
        if !FileManager.default.fileExists(atPath:url.path){FileManager.default.createFile(atPath:url.path,contents:nil)}
        let handle=try FileHandle(forWritingTo:url);defer{try? handle.close()}
        try handle.seekToEnd();try handle.write(contentsOf:data);try handle.synchronize()
        journalStates[document.id]=document
    }
}
