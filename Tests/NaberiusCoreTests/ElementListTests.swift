import Foundation
import PDFKit
import Testing
@testable import NaberiusCore

struct ElementListTests {
    private func sample()->NabDocument {
        var d=NabDocument();d.metadata.title="Listas automáticas";d.metadata.bibliography=false
        d.insert(AcademicNode(.figureList));d.insert(AcademicNode(.tableList));d.blocks.append(Block("",style:.pageBreak))
        var a=AcademicNode(.table);a.caption="Muestra & control";a.rows=[["Variable","Valor"],["A","12"]];d.insert(a)
        var b=AcademicNode(.table);b.caption="Segunda muestra";d.insert(b)
        return d
    }
    @Test func `new lists require schema four and survive archive fragment and reordering`()throws {
        let d=sample(),restored=try NabArchive.decode(NabArchive.encode(d))
        #expect(restored.schemaVersion==4);#expect(restored.nodes==d.nodes)
        let fragment=DocumentFragment.selection(d.blocks,from:d)
        #expect(fragment.schemaVersion==4)
        var destination=NabDocument();destination.blocks=try DocumentFragment.importBlocks(fragment,into:&destination)
        #expect(destination.orderedNodes.map(\.kind)==d.orderedNodes.map(\.kind))
        #expect(destination.minimumSchemaVersion==4)
        var reordered=restored;let tables=reordered.orderedNodes.filter{$0.kind == .table}
        let first=try #require(reordered.blocks.firstIndex(where:{$0.runs.contains{$0.nodeID==tables[0].id}}))
        let second=try #require(reordered.blocks.firstIndex(where:{$0.runs.contains{$0.nodeID==tables[1].id}}))
        reordered.blocks.swapAt(first,second)
        #expect(reordered.number(of:tables[0].id)==2)
        #expect(try NabArchive.decode(NabArchive.encode(NabDocument())).schemaVersion==1)
        var future=restored;future.schemaVersion=5
        #expect(throws:NabError.self){try NabArchive.validate(future)}
    }
    @Test func `interrupted recovery upgrades an old snapshot when lists are added`()async throws {
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:folder)}
        let disk=DocumentDisk();var d=NabDocument();try await disk.journal(d,directory:folder)
        d.insert(AcademicNode(.figureList));d.insert(AcademicNode(.tableList));d.modified=Date().addingTimeInterval(1)
        try await disk.journal(d,directory:folder)
        let url=folder.appendingPathComponent(d.id.uuidString+".nab")
        let handle=try FileHandle(forWritingTo:url.appendingPathExtension("journal"))
        try handle.seekToEnd();try handle.write(contentsOf:Data("{interrupted".utf8));try handle.close()
        let recovered=try await disk.readRecovery(url)
        #expect(recovered.schemaVersion==4);#expect(recovered.nodes==d.nodes);#expect(recovered.blocks==d.blocks)
        let encoded=try NabArchive.encode(recovered);var corrupt=encoded;corrupt[corrupt.count-1] ^= 0xff
        #expect(throws:(any Error).self){try NabArchive.decode(corrupt)}
    }
    @Test func `exports standard LaTeX lists with escaped fallback captions and pages`() {
        let source=LaTeX.source(sample())
        #expect(source.contains("\\listoffigures"));#expect(source.contains("\\listoftables"))
        #expect(source.contains("Muestra \\& control"));#expect(source.contains("\\pageref{n"))
    }
    @Test(.enabled(if:ProcessInfo.processInfo.environment["NABERIUS_COMPOSE"]=="1"),arguments:["article","report","book","letter","article-two-columns"])
    func `lists compile with real pages and exactly one entry per multipage table`(_ templateID:String)async throws {
        var d=sample();d.template=try #require(DocumentTemplate.builtins.first(where:{$0.id==templateID}))
        if templateID=="article-two-columns" {
            let index=try #require(d.nodes.firstIndex(where:{$0.kind == .table}))
            d.nodes[index].rows += (0..<30).map{["Fila \($0)","Control"]};d.nodes[index].normalizeTableIdentity()
        }
        let result=try await Composer.compile(d,engine:#require(Composer.detectedEngine()),allowNetwork:true)
        defer{Task{await Composer.discard(result)}}
        let pdf=try #require(PDFDocument(url:result.pdf))
        let pages=(0..<pdf.pageCount).compactMap{pdf.page(at:$0)?.string}
        #expect(pages.contains{$0.contains("Lista de figuras")})
        let list=try #require(pages.first{$0.contains("Lista de tablas")})
        // PDFKit may group linked text by glyph positions rather than line order.
        #expect(list.contains("Muestra"));#expect(list.contains("control"));#expect(list.contains("Segunda"))
        #expect(list.components(separatedBy:"control").count-1==1)
        #expect(!pages.joined().contains("??"))
    }
}
