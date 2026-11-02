import Foundation

/// One semantic transaction. Full arrays are included only when they changed.
struct RecoveryDelta:Codable,Sendable {
    var documentID:UUID
    var changedBlocks:[Block]
    var order:[UUID]?
    var nodes:[AcademicNode]?
    var assets:[Asset]?
    var references:[Reference]?
    var metadata:Metadata?
    var template:DocumentTemplate?
    var cursor:Cursor
    var modified:Date
    init(from old:NabDocument,to new:NabDocument) {
        documentID=new.id;let previous=Dictionary(uniqueKeysWithValues:old.blocks.map{($0.id,$0)})
        changedBlocks=new.blocks.filter{previous[$0.id] != $0}
        order=old.blocks.map(\.id)==new.blocks.map(\.id) ? nil : new.blocks.map(\.id)
        nodes=old.nodes==new.nodes ? nil : new.nodes;assets=old.assets==new.assets ? nil : new.assets;references=old.references==new.references ? nil : new.references
        metadata=old.metadata==new.metadata ? nil : new.metadata;template=old.template==new.template ? nil : new.template;cursor=new.cursor;modified=new.modified
    }
    func apply(to d:inout NabDocument)throws {
        guard d.id==documentID else{throw NabError.invalid(L10n.text("El diario pertenece a otro documento."))}
        var blocks=Dictionary(uniqueKeysWithValues:d.blocks.map{($0.id,$0)})
        for b in changedBlocks{blocks[b.id]=b}
        let ids=order ?? d.blocks.map(\.id)
        guard ids.allSatisfy({blocks[$0] != nil}),Set(ids).count==ids.count else{throw NabError.invalid(L10n.text("El diario de recuperación contiene una transacción inválida."))}
        d.blocks=ids.compactMap{blocks[$0]};if let nodes{d.nodes=nodes};if let assets{d.assets=assets};if let references{d.references=references};if let metadata{d.metadata=metadata};if let template{d.template=template};d.cursor=cursor;d.modified=modified
        d.schemaVersion=max(d.schemaVersion,d.minimumSchemaVersion)
    }
}
extension DocumentDisk {
    /// Replay complete transactions and ignore only a torn final append after interruption.
    public func readRecovery(_ url:URL)throws->NabDocument {
        var d=try read(url).0
        let journal=url.appendingPathExtension("journal")
        guard FileManager.default.fileExists(atPath:journal.path)else{return d}
        let attrs=try FileManager.default.attributesOfItem(atPath:journal.path)
        guard (attrs[.size] as? NSNumber)?.intValue ?? 0 <= NabArchive.maxSize else{throw NabError.invalid(L10n.text("El diario supera el límite de recuperación."))}
        let data=try Data(contentsOf:journal);let decoder=JSONDecoder();decoder.dateDecodingStrategy = .millisecondsSince1970
        let complete=data.split(separator:10,omittingEmptySubsequences:false)
        for line in complete.dropLast() where !line.isEmpty{let delta=try decoder.decode(RecoveryDelta.self,from:Data(line));try delta.apply(to:&d)}
        try NabArchive.validate(d);return d
    }
}
