import Foundation

public enum DocumentFragment {
    /// Carries only resources needed by the copied selection; no paths or personal library.
    public static func selection(_ blocks:[Block], from source:NabDocument) -> NabDocument {
        var fragment=NabDocument(template:source.template)
        fragment.id=source.id
        fragment.blocks=blocks
        let nodes=Set(blocks.flatMap(\.runs).compactMap(\.nodeID))
        fragment.nodes=source.nodes.filter {nodes.contains($0.id)}
        let assets=Set(fragment.nodes.compactMap(\.assetID))
        fragment.assets=source.assets.filter {assets.contains($0.id)}
        let references=Set(fragment.nodes.flatMap(\.referenceIDs))
        fragment.references=source.references.filter {references.contains($0.id)}
        fragment.schemaVersion=fragment.minimumSchemaVersion
        return fragment
    }
    /// Clones semantic identities and reconnects dependencies before inserting the text.
    public static func importBlocks(_ fragment:NabDocument, into destination:inout NabDocument) throws -> [Block] {
        try NabArchive.validate(fragment)
        let allIDs=fragment.blocks.map(\.id)+fragment.nodes.map(\.id)+fragment.assets.map(\.id)+fragment.references.map(\.id)
        guard Set(allIDs).count==allIDs.count else{throw NabError.invalid(L10n.text("El fragmento contiene identidades ambiguas."))}
        var identities=Dictionary(uniqueKeysWithValues:(fragment.blocks.map(\.id)+fragment.nodes.map(\.id)).map {($0,UUID())})
        for asset in fragment.assets {
            if let existing=destination.assets.first(where:{$0.mediaType==asset.mediaType && $0.data==asset.data && $0.originalData==asset.originalData}) {identities[asset.id]=existing.id}
            else {var copy=asset;copy.id=UUID();identities[asset.id]=copy.id;destination.assets.append(copy)}
        }
        for reference in fragment.references {
            if let existing=destination.references.first(where:{var candidate=$0;candidate.id=reference.id;return candidate==reference}) {identities[reference.id]=existing.id}
            else {var copy=reference;copy.id=UUID();identities[reference.id]=copy.id;destination.references.append(copy)}
        }
        for node in fragment.nodes {
            var copy=node;copy.id=identities[node.id]!
            copy.assetID=node.assetID.flatMap {identities[$0]}
            copy.referenceIDs=node.referenceIDs.compactMap {identities[$0]}
            if let target=node.targetID {
                copy.targetID=identities[target] ?? (fragment.id==destination.id ? target : nil)
            }
            copy.rowIDs=node.rowIDs.map {_ in UUID()};copy.columnIDs=node.columnIDs.map {_ in UUID()}
            destination.nodes.append(copy)
        }
        return fragment.blocks.map {block in
            var copy=block;copy.id=identities[block.id]!
            copy.runs=block.runs.map {run in var run=run;run.nodeID=run.nodeID.flatMap {identities[$0]};return run}
            return copy
        }
    }
}
