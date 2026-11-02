import Foundation
import CSyncTeX

public struct PDFSourceLocation:Equatable,Sendable {
    /// Zero-based PDF page and a rectangle in 72 dpi points from its top-left corner.
    public let page:Int
    public let bounds:CGRect
    public let blockID:UUID
    public let line:Int
    public init(page:Int,bounds:CGRect,blockID:UUID,line:Int=1) {
        self.page=page;self.bounds=bounds;self.blockID=blockID;self.line=line
    }
}

/// A composition owns this immutable map. Paths are generated source files only;
/// imported class files and arbitrary names from SyncTeX never become editor targets.
public struct PDFSynchronization:Sendable {
    public let documentID:UUID
    public let pdf:URL
    public let sources:[UUID:URL]
    public init(documentID:UUID,pdf:URL,sources:[UUID:URL]) {
        self.documentID=documentID;self.pdf=pdf;self.sources=sources
    }
    public var dataURL:URL {pdf.deletingPathExtension().appendingPathExtension("synctex.gz")}
    private func block(for name:String)->UUID? {
        let file=URL(fileURLWithPath:name,relativeTo:pdf.deletingLastPathComponent()).standardizedFileURL.resolvingSymlinksInPath()
        guard let id=UUID(uuidString:file.deletingPathExtension().lastPathComponent),let allowed=sources[id],
              allowed.standardizedFileURL.resolvingSymlinksInPath()==file else{return nil}
        return id
    }
    private func scanner()throws->OpaquePointer {
        guard let attributes=try? FileManager.default.attributesOfItem(atPath:dataURL.path),
              (attributes[.size] as? NSNumber)?.intValue ?? 0 <= 64*1024*1024,
              let scanner=pdf.path.withCString({nab_synctex_scanner_new($0)}) else {
            throw NabError.invalid(L10n.text("No se pudieron leer los datos de sincronización de este PDF. Vuelve a componerlo."))
        }
        return scanner
    }
    private func location(_ node:OpaquePointer,scanner:OpaquePointer)->PDFSourceLocation? {
        guard let name=synctex_scanner_get_name(scanner,synctex_node_tag(node)),
              let name=String(validatingCString:name),let id=block(for:name) else{return nil}
        let page=Int(synctex_node_page(node))-1
        let x=Double(synctex_node_box_visible_h(node)),y=Double(synctex_node_box_visible_v(node))
        let width=Double(synctex_node_box_visible_width(node)),height=Double(synctex_node_box_visible_height(node)),depth=Double(synctex_node_box_visible_depth(node))
        guard page>=0,[x,y,width,height,depth].allSatisfy(\.isFinite) else{return nil}
        return PDFSourceLocation(page:page,bounds:CGRect(x:x,y:y-height,width:width,height:height+depth).standardized,blockID:id,line:Int(synctex_node_line(node)))
    }
    @concurrent public func locations(for blockID:UUID,pageHint:Int=0)async throws->[PDFSourceLocation] {
        try Task.checkCancellation()
        guard let source=sources[blockID] else{return []}
        let scanner=try scanner();defer{synctex_scanner_free(scanner)}
        let status=source.path.withCString{synctex_display_query(scanner,$0,1,0,Int32(min(max(0,pageHint),Int(Int32.max)-1)+1))}
        guard status>0 else{return []}
        var result:[PDFSourceLocation]=[]
        while let node=synctex_scanner_next_result(scanner),result.count<64 {
            try Task.checkCancellation()
            if let match=location(node,scanner:scanner),match.blockID==blockID {result.append(match)}
        }
        return result
    }
    @concurrent public func source(at point:CGPoint,page:Int)async throws->PDFSourceLocation? {
        try Task.checkCancellation()
        guard page>=0,page<Int(Int32.max),point.x.isFinite,point.y.isFinite,abs(point.x)<100_000,abs(point.y)<100_000 else{return nil}
        let scanner=try scanner();defer{synctex_scanner_free(scanner)}
        guard synctex_edit_query(scanner,Int32(page+1),Float(point.x),Float(point.y))>0 else{return nil}
        while let node=synctex_scanner_next_result(scanner) {
            try Task.checkCancellation()
            if let match=location(node,scanner:scanner) {return match}
        }
        return nil
    }
}
