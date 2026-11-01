import Foundation
import Testing
@testable import NaberiusCore

struct TypesettingTests {
    @Test func `old template data remains readable with explicit typography preserved`() throws {
        var old=DocumentTemplate.builtins[0];old.font="Times New Roman";old.layout=nil
        let data=try JSONEncoder().encode(old)
        let decoded=try JSONDecoder().decode(DocumentTemplate.self,from:data)
        #expect(decoded.font=="Times New Roman")
        #expect(decoded.effectiveLayout.documentClass == .article)
        var book=old;book.id="book"
        #expect(book.effectiveLayout.documentClass == .book)
    }
    @Test func `layouts survive archive roundtrip and reject unsafe dimensions`() throws {
        var d=NabDocument();var layout=d.template.effectiveLayout
        layout.header="Informe de LaTeX";layout.footer="Borrador";layout.paragraphIndentMM=5
        d.template.layout=layout
        #expect(try NabArchive.decode(NabArchive.encode(d)).template.layout==layout)
        d.template.layout?.paragraphIndentMM = .infinity
        #expect(throws:NabError.self) {try NabArchive.validate(d)}
    }
    @Test func `typographic logos are boundary aware escaped and preserve adjacent text`() {
        #expect(LaTeX.bodyText("LaTeX & TeX, Latex.")=="\\LaTeX{} \\& \\TeX{}, \\LaTeX{}.")
        #expect(LaTeX.bodyText("LaTeXero latex \\write18")=="LaTeXero latex \\textbackslash{}write18")
        var d=NabDocument();d.blocks=[Block()];d.blocks[0].runs=[TextRun("La"),TextRun("TeX")]
        #expect(LaTeX.source(d).contains("\\LaTeX{}"))
    }
    @Test(arguments:DocumentTemplate.builtins)
    func `builtins export their actual class with safe portable font setup`(_ template:DocumentTemplate) throws {
        let d=NabDocument(template:template),source=LaTeX.source(d)
        #expect(source.contains("{\(template.effectiveLayout.documentClass.rawValue)}"))
        #expect(source.contains("Path=fonts/") == (template.font == DocumentTypography.defaultFont))
        for file in DocumentTypography.fontFiles {#expect(try Data(contentsOf:DocumentTypography.fontURL(file)).count>100_000)}
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:folder)}
        try LaTeX.writeProject(d,at:folder)
        #expect(FileManager.default.fileExists(atPath:folder.appendingPathComponent("fonts/GUST-FONT-LICENSE.TXT").path))
        #expect(try Data(contentsOf:folder.appendingPathComponent("fonts/lmroman10-regular.otf"))==Data(contentsOf:DocumentTypography.fontURL("lmroman10-regular.otf")))
    }
    @Test(arguments:["Académico","Simple","Cuadrícula"])
    func `table styles have distinct real LaTeX rules`(_ style:String) {
        var d=NabDocument();var table=AcademicNode(.table);table.tableStyle=style;d.insert(table)
        let source=LaTeX.source(d)
        #expect(source.contains("\\begin{tabularx}"))
        #expect(source.contains("\\toprule") == (style == "Académico"))
        #expect(source.contains("\\hline") == (style == "Cuadrícula"))
    }
}

struct FragmentTests {
    @Test func `copied academic objects bring resources references and internal targets`() throws {
        var source=NabDocument();let asset=Asset(name:"a.png",mediaType:"image/png",data:Data([1,2,3]));source.assets=[asset]
        var reference=Reference();reference.title="Obra citada";source.references=[reference]
        var figure=AcademicNode(.figure);figure.assetID=asset.id;source.insert(figure)
        var citation=AcademicNode(.citation);citation.referenceIDs=[reference.id];source.insert(citation)
        var cross=AcademicNode(.crossReference);cross.targetID=figure.id;source.insert(cross)
        let fragment=DocumentFragment.selection(Array(source.blocks.dropFirst()),from:source)
        let portable=try NabArchive.decode(NabArchive.encode(fragment))
        var target=NabDocument();let original=target.blocks
        let pasted=try DocumentFragment.importBlocks(portable,into:&target)
        #expect(target.blocks==original)
        target.blocks += pasted
        try NabArchive.validate(target)
        #expect(target.assets.count==1);#expect(target.references.count==1)
        let newFigure=try #require(target.nodes.first(where:{$0.kind == .figure}))
        #expect(newFigure.id != figure.id)
        #expect(target.nodes.first(where:{$0.kind == .crossReference})?.targetID==newFigure.id)
        #expect(target.nodes.first(where:{$0.kind == .citation})?.referenceIDs==target.references.map(\.id))
        let again=try DocumentFragment.importBlocks(portable,into:&target);target.blocks += again
        #expect(target.assets.count==1);#expect(target.references.count==1)
        #expect(Set(target.nodes.map(\.id)).count==target.nodes.count)
        try NabArchive.validate(target)
    }
    @Test func `external fragment targets become explicit missing references and ambiguous identities are rejected`() throws {
        var source=NabDocument();let heading=Block("Destino",style:.heading1);source.blocks=[heading]
        var cross=AcademicNode(.crossReference);cross.targetID=heading.id;source.insert(cross)
        var fragment=DocumentFragment.selection([source.blocks[1]],from:source),target=NabDocument()
        _=try DocumentFragment.importBlocks(fragment,into:&target)
        #expect(target.nodes.first?.targetID == nil)
        fragment.blocks[0].id=fragment.nodes[0].id
        #expect(throws:NabError.self) {try DocumentFragment.importBlocks(fragment,into:&target)}
    }
}
struct StructuralTests {
    @Test func `appendices and separators export as semantic LaTeX commands`() {
        var d=NabDocument(template:DocumentTemplate.builtins[4]);d.blocks=[Block("Principal",style:.heading1),Block("Datos",style:.appendix),Block("Más datos",style:.appendix)]
        d.insert(AcademicNode(.separator))
        let source=LaTeX.source(d)
        #expect(source.components(separatedBy:"\\appendix").count==2)
        #expect(source.contains("\\chapter{Datos}"))
        #expect(source.contains("\\rule{\\linewidth}{0.4pt}"))
        #expect(d.blocks[1].style.headingLevel==1)
    }
    @Test func `template importer maps class geometry and reports dependencies without running source`() throws {
        let url=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".tex")
        defer{try? FileManager.default.removeItem(at:url)}
        try #"\documentclass[11pt,letterpaper]{book}\usepackage[margin=3cm]{geometry}\setmainfont{Latin Modern Roman}"#.write(to:url,atomically:true,encoding:.utf8)
        let result=try TemplateImporter.analyze(url)
        #expect(result.compatible);#expect(result.partial)
        #expect(result.template.effectiveLayout.documentClass == .book)
        #expect(result.template.fontSize==11);#expect(result.template.marginMM==30)
        #expect(result.messages.contains(where:{$0.contains("geometry")}))
    }
    @Test func `failed TeX composition leaves a document serializable`() async throws {
        let document=NabDocument.example,original=document
        do {
            _=try await Composer.compile(document,engine:URL(fileURLWithPath:"/usr/bin/false"))
            Issue.record("El motor de fallo no debe producir un PDF")
        } catch {#expect(!error.localizedDescription.isEmpty)}
        #expect(document==original)
        let restored=try NabArchive.decode(NabArchive.encode(document))
        #expect(restored.blocks==original.blocks);#expect(restored.template==original.template)
        #expect(restored.metadata==original.metadata);#expect(restored.nodes==original.nodes)
    }
}

struct TemplateProtectionTests {
    @Test func `template locks are per property and survive existing archive format`() throws {
        var document=NabDocument();document.template.lockedProperties=[.font,.layout]
        #expect(!document.template.allows(.font));#expect(!document.template.allows(.layout))
        #expect(document.template.allows(.paper))
        let restored=try NabArchive.decode(NabArchive.encode(document))
        #expect(restored.template.lockedProperties==[.font,.layout])
        document.template.locked=true
        #expect(TemplateProperty.allCases.allSatisfy{!document.template.allows($0)})
    }
}
