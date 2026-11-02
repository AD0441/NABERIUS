import Foundation
import PDFKit
import Testing
@testable import NaberiusCore

struct PDFSynchronizationTests {
    @Test func `synchronized sources preserve paragraph identities and ordinary export remains self contained`()throws {
        var document=NabDocument();document.blocks=[Block("Árbol & control"),Block("Resultado",style:.heading1),Block("Una muestra",style:.bullet)]
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:root)}
        let project=try LaTeX.writeProject(document,at:root,synchronized:true)
        #expect(Set(project.sources.keys)==Set(document.blocks.map(\.id)))
        for block in document.blocks {
            let url=try #require(project.sources[block.id]),content=try String(contentsOf:url,encoding:.utf8)
            #expect(content.hasSuffix("\n\n"))
            #expect(url.lastPathComponent==block.id.uuidString+".tex")
        }
        #expect(LaTeX.source(document).contains("naberius-source-")==false)
        #expect(LaTeX.source(document).contains("Árbol \\& control"))
        #expect(try NabArchive.decode(NabArchive.encode(document)).blocks==document.blocks)
    }
    @Test func `missing or malformed synchronization fails safely and unknown blocks do not fall back`()async throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        defer{try? FileManager.default.removeItem(at:root)}
        let block=UUID(),map=PDFSynchronization(documentID:UUID(),pdf:root.appendingPathComponent("main.pdf"),sources:[block:root.appendingPathComponent(block.uuidString+".tex")])
        #expect(try await map.locations(for:UUID()).isEmpty)
        await #expect(throws:NabError.self){try await map.locations(for:block)}
        try Data("not a SyncTeX stream".utf8).write(to:map.dataURL)
        await #expect(throws:NabError.self){try await map.locations(for:block)}
        #expect(try await map.source(at:.zero,page:-1)==nil)
        #expect(try await map.source(at:CGPoint(x:Double.infinity,y:0),page:0)==nil)
    }
    @Test(.enabled(if:ProcessInfo.processInfo.environment["NABERIUS_COMPOSE"]=="1"),arguments:["blank","report","article-two-columns","letter","zip"])
    func `real SyncTeX maps a paragraph forward and back across pages and editorial classes`(_ kind:String)async throws {
        var document=NabDocument()
        if kind=="zip" {
            var package=try TemplatePackageTests.package()
            // A nested main file exercises paths produced by ZIP materialization.
            package=try LaTeXTemplatePackage.analyze(files:package.files.map {TemplateFile(path:"journal/"+$0.path,data:$0.data)},sourceName:"nested.zip")
            document=TemplatePackageTests.document(package)
        } else {document.template=try #require(DocumentTemplate.builtins.first{$0.id==kind})}
        document.blocks=[Block("Primer destino estable. Una oración breve para comprobar la sincronización."),Block("",style:.pageBreak),Block("Último destino con acentos: información, análisis y comparación.")]
        let original=document
        let result=try await Composer.compile(document,engine:#require(Composer.detectedEngine()),allowNetwork:true)
        let sync=try #require(result.synchronization),pdf=try #require(PDFDocument(url:result.pdf))
        #expect(FileManager.default.fileExists(atPath:sync.dataURL.path))
        #expect(pdf.pageCount >= (kind=="article-two-columns" ? 1 : 2))
        for block in [document.blocks[0],document.blocks[2]] {
            let locations=try await sync.locations(for:block.id)
            let location=try #require(locations.first)
            #expect(location.bounds.width>0);#expect(location.bounds.height>0)
            let back=try #require(await sync.source(at:CGPoint(x:location.bounds.midX,y:location.bounds.midY),page:location.page))
            #expect(back.blockID==block.id)
        }
        #expect(document==original)
        await Composer.discard(result)
        #expect(FileManager.default.fileExists(atPath:sync.dataURL.path)==false)
    }
}
