import Foundation
public struct TemplateAnalysis: Sendable {
    public var compatible: Bool
    public var partial: Bool
    public var messages: [String]
    public var template: DocumentTemplate
}
public enum TemplateImporter {
    public static func analyze(_ url: URL) throws -> TemplateAnalysis {
        let data = try Data(contentsOf:url,options:.mappedIfSafe)
        guard data.count <= 10*1024*1024 else { throw NabError.invalid(L10n.text("La plantilla supera 10 MB.")) }
        var source = ""; var notes: [String] = []
        if url.pathExtension.lowercased() == "zip" {
            let entries = try safeZIPEntries(data)
            notes.append(L10n.format("ZIP inspeccionado sin extraer archivos. %@ entradas.",entries.count))
            let textFiles = entries.filter { ["tex","cls","sty"].contains(($0 as NSString).pathExtension.lowercased()) }
            for name in textFiles {
                let p = Process(); p.executableURL = URL(fileURLWithPath:"/usr/bin/unzip"); p.arguments = ["-p",url.path,name]
                let pipe = Pipe(); p.standardOutput = pipe; p.standardError = FileHandle.nullDevice; try p.run()
                var content=Data()
                while let chunk=try pipe.fileHandleForReading.read(upToCount:65536),!chunk.isEmpty {
                    content.append(chunk)
                    if content.count>2*1024*1024 {p.terminate();p.waitUntilExit();throw NabError.invalid(L10n.text("La entrada del ZIP excede el límite de expansión."))}
                }
                p.waitUntilExit()
                guard p.terminationStatus == 0, content.count <= 2*1024*1024 else { throw NabError.invalid(L10n.text("No se pudo leer una entrada del ZIP.")) }
                source += String(data:content,encoding:.utf8) ?? ""
            }
            guard !source.isEmpty else { throw NabError.invalid(L10n.text("No se encontró una plantilla .tex, .cls o .sty legible en el ZIP.")) }
        } else {
            guard ["tex","cls","sty"].contains(url.pathExtension.lowercased()), let s = String(data:data,encoding:.utf8) else { throw NabError.invalid(L10n.text("Selecciona .tex, .cls, .sty o .zip UTF-8.")) }; source = s
        }
        let unsafe = ["\\write18","\\openout","\\openin","\\read","\\catcode","\\directlua","\\csname","\\input|","/etc/","../","\\immediate"]
        let found = unsafe.filter { source.contains($0) }
        let macros = source.contains("\\newcommand") || source.contains("\\def") || source.contains("\\usepackage")
        var t = DocumentTemplate(id:UUID().uuidString,name:url.deletingPathExtension().lastPathComponent,detail:L10n.text("Importada con mapeo semántico seguro; no ejecuta código externo.")); t.category = L10n.text("Importadas")
        let compatible = found.isEmpty
        if !found.isEmpty { notes.append(L10n.text("No compatible: contiene instrucciones que requieren acceso o ejecución no admitidos: ")+found.joined(separator:", ")) }
        if macros { notes.append(L10n.text("Compatibilidad parcial: paquetes y macros externos no se ejecutan. Se instala una variante semántica basada en los estilos de Naberius; revisar el documento de prueba.")) }
        if compatible && !macros { notes.append(L10n.text("Compatible con el mapeo básico de artículo. Se conserva el contenido del documento al aplicar.")) }
        func captures(_ pattern:String)->[[String]] {
            guard let regex=try? NSRegularExpression(pattern:pattern)else{return []}
            let ns=source as NSString
            return regex.matches(in:source,range:NSRange(location:0,length:ns.length)).map {match in (1..<match.numberOfRanges).map {match.range(at:$0).location == NSNotFound ? "" : ns.substring(with:match.range(at:$0))}}
        }
        if let match=captures(#"\\documentclass(?:\[([^\]]*)\])?\{([^}]+)\}"#).first {
            if let kind=DocumentClass(rawValue:match[1]) {t.effectiveLayout=DocumentLayout(documentClass:kind);notes.append(L10n.text("Clase mapeada: ")+kind.rawValue+".")}
            else {notes.append(L10n.text("Clase externa no incorporada: ")+match[1]+L10n.text(". La variante usa article; verificar el documento de prueba."))}
            if let size=captures(#"(?:\[|,)(10|11|12)pt(?:,|\])"#).first.flatMap({Double($0[0])}) {t.fontSize=size}
        }
        if source.contains("letterpaper") {t.paper="letterpaper"}
        if source.contains("legalpaper") {t.paper="legalpaper"}
        if let margin=captures(#"margin\s*=\s*([0-9]+(?:\.[0-9]+)?)\s*(mm|cm)"#).first,let value=Double(margin[0]) {
            let mm=value*(margin[1]=="cm" ? 10 : 1)
            if (10...50).contains(mm) {t.marginMM=mm;notes.append(L10n.format("Márgenes mapeados: %@ mm.",mm))}
        }
        if let font=captures(#"\\setmainfont(?:\[[^\]]*\])?\{([^}]+)\}"#).first?.first {
            if DocumentTypography.supportedFonts.contains(font) {t.font=font}
            else {notes.append(L10n.text("Fuente externa no incluida: ")+font+L10n.text(". La variante usa Latin Modern."))}
        }
        let dependencies=captures(#"\\usepackage(?:\[[^\]]*\])?\{([^}]+)\}"#).flatMap {$0[0].split(separator:",").map(String.init)}
        if !dependencies.isEmpty {notes.append(L10n.text("Dependencias detectadas: ")+dependencies.joined(separator:", ")+L10n.text(". No se ejecutan ni instalan durante el análisis."))}

        notes.append(L10n.text("La importación nunca instala ejecutables ni compila el archivo recibido."))
        return TemplateAnalysis(compatible:compatible,partial:macros || notes.contains(where:{$0.contains(L10n.text("no incorporada")) || $0.contains(L10n.text("no incluida"))}),messages:notes,template:t)
    }
    private static func safeZIPEntries(_ data: Data) throws -> [String] {
        let b = [UInt8](data)
        func u16(_ i:Int) -> Int { Int(b[i]) | Int(b[i+1])<<8 }
        func u32(_ i:Int) -> Int { u16(i) | u16(i+2)<<16 }
        var i = 0; var entries:[String] = []; var total = 0
        while i+46 <= b.count {
            guard u32(i) == 0x02014b50 else { i += 1; continue }
            guard u16(i+8) & 1 == 0,[0,8].contains(u16(i+10)) else{throw NabError.invalid(L10n.text("ZIP cifrado o compresión no admitida."))}
            let size = u32(i+24), nameLen = u16(i+28), extra = u16(i+30), comment = u16(i+32)
            guard i+46+nameLen+extra+comment <= b.count, size <= 2*1024*1024, entries.count < 100 else { throw NabError.invalid(L10n.text("ZIP inseguro o demasiado grande.")) }
            let name = String(decoding:b[(i+46)..<(i+46+nameLen)],as:UTF8.self)
            guard !name.hasPrefix("/"), !name.contains("\\"), !name.split(separator:"/").contains(".."), !name.contains(":"), !name.contains("\u{0}") else { throw NabError.invalid(L10n.text("El ZIP contiene rutas peligrosas.")) }
            let mode = u32(i+38)>>16
            guard mode & 0xf000 != 0xa000 else { throw NabError.invalid(L10n.text("El ZIP contiene enlaces simbólicos.")) }
            total += size; guard total <= 10*1024*1024 else { throw NabError.invalid(L10n.text("La expansión del ZIP supera 10 MB.")) }
            entries.append(name); i += 46+nameLen+extra+comment
        }
        guard !entries.isEmpty else { throw NabError.invalid(L10n.text("ZIP dañado o ZIP64 no compatible.")) }; return entries
    }
}
