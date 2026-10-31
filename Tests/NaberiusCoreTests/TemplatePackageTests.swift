import Foundation
import PDFKit
import Testing
@testable import NaberiusCore

struct TemplatePackageTests {
    static func package(_ name:String="example-journal")throws->LaTeXTemplatePackage {
        let main="""
        % A publisher-independent fixture owned by Naberius tests.
        % \\documentclass{ignored-comment}
        \\documentclass[11pt]{\(name)}
        \\usepackage{natbib}
        \\bibliographystyle{plainnat}
        \\title[Original title]{Original title}
        \\author{Original Author}
        \\begin{document}
        \\maketitle
        \\begin{abstract}Original abstract\\end{abstract}
        \\section{Introduction}
        Original sample text, replaced by document content.
        \\bibliography{original}
        \\end{document}
        """
        let files=[TemplateFile(path:"main.tex",data:Data(main.utf8)),TemplateFile(path:name+".cls",data:Data("\\NeedsTeXFormat{LaTeX2e}\n\\ProvidesClass{\(name)}\n\\LoadClassWithOptions{article}\n\\let\\baseTitle\\title\n\\renewcommand{\\title}[2][]{\\baseTitle{#2}}\n".utf8)),TemplateFile(path:"original.bib",data:Data("@book{sample,title={Example}}".utf8)),TemplateFile(path:"figures/reference.pdf",data:Data("synthetic reference bytes".utf8))]
        return try LaTeXTemplatePackage.analyze(files:files,sourceName:name+".zip")
    }
    static func document(_ package:LaTeXTemplatePackage)->NabDocument {
        var template=DocumentTemplate.builtins[0];template.package=package
        var d=NabDocument(template:template);d.metadata=package.initialMetadata();d.metadata.title="A real journal document";d.metadata.authors="Author, Example";d.metadata.abstract="Synthetic abstract."
        d.blocks=[Block("Introduction",style:.heading1),Block("Native document text is composed in the supplied class.")]
        return d
    }
    @Test(arguments:["example-journal","another-publisher"])
    func `package detection is independent of the journal name`(_ name:String)throws {
        let package=try Self.package(name)
        #expect(package.plan.mainFile=="main.tex");#expect(package.plan.documentClass==name)
        #expect(package.files.count==4);#expect(package.plan.firstHeading=="Introduction")
        let d=Self.document(package),source=LaTeX.source(d)
        #expect(source.contains("{\(name)}"));#expect(source.contains("\\title[A real journal document]{A real journal document}"))
        #expect(source.contains("Synthetic abstract."));#expect(source.contains("Native document text"));#expect(source.contains("Original sample text") == false)
        #expect(source.contains("\\usepackage[margin=") == false);#expect(source.contains("\\setmainfont") == false)
        let restored=try NabArchive.decode(NabArchive.encode(d));#expect(restored.template.package==package)
    }
    @Test func `structured publisher fields retain formatting and escape edited data`()throws {
        let source="\\documentclass{article}\n\\begin{document}\n\\title{Example}\n\\author*[1]{\\fnm{First} \\sur{Last}}\\email{example@example.org}\n\\maketitle\n\\section{Introduction}\nText\n\\end{document}"
        let package=try LaTeXTemplatePackage.analyze(files:[TemplateFile(path:"article.tex",data:Data(source.utf8))],sourceName:"test.zip")
        let first=try #require(package.customFields.first(where:{$0.macro=="fnm"}))
        var metadata=package.initialMetadata();metadata.templateFields=[first.id:"Name & \\input{private}"]
        let prefix=package.prefix(metadata:metadata)
        #expect(prefix.contains("\\fnm{Name \\& \\textbackslash{}input\\{private\\}}"))
        #expect(prefix.contains("\\sur{Last}"));#expect(prefix.contains("\\input{private}") == false)
    }
    @Test func `export preserves resources and the original entry separately`()throws {
        let package=try Self.package(),d=Self.document(package)
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:directory)}
        let main=try LaTeX.writeProject(d,at:directory)
        #expect(main.lastPathComponent=="main.tex")
        #expect(try Data(contentsOf:directory.appendingPathComponent("original-template/main.tex"))==package.files[0].data)
        #expect(try Data(contentsOf:directory.appendingPathComponent("figures/reference.pdf"))==package.files[3].data)
    }
    @Test func `editorial bibliography retains chapter containers editions editors and publication places`()throws {
        let original=try #require(BibliographyImporter.bibTeX("@incollection{chapter,title={A chapter},author={Author, Anne},booktitle={Collected examples},year={2024},editor={Editor, Evan},edition={2},location={Santiago},publisher={Example Press}}").references.first)
        let generated=try Self.package().bibliography([original])
        let restored=try #require(BibliographyImporter.bibTeX(generated).references.first)
        #expect(restored.container=="Collected examples")
        #expect(restored.csl["edition"] as? String=="2")
        #expect(restored.csl["publisher-place"] as? String=="Santiago")
        #expect((restored.csl["editor"] as? [[String:String]])?.first?["family"]=="Editor")
    }
    @Test(.enabled(if:ProcessInfo.processInfo.environment["NABERIUS_COMPOSE"]=="1"))
    func `standard journal citations do not assume natbib from the presence of BST files`()async throws {
        var files=try Self.package().files
        files[0].data=Data(String(decoding:files[0].data,as:UTF8.self).replacingOccurrences(of:"\\usepackage{natbib}",with:"").replacingOccurrences(of:"{plainnat}",with:"{plain}").utf8)
        files.append(TemplateFile(path:"unused.bst",data:Data("Unused style fixture".utf8)))
        let package=try LaTeXTemplatePackage.analyze(files:files,sourceName:"standard.zip")
        var document=Self.document(package)
        var reference=Reference();reference.title="Resolved standard reference";reference.authors="Doe, Jane";reference.year="2024";document.references=[reference]
        var citation=AcademicNode(.citation);citation.referenceIDs=[reference.id];citation.prefix="see";citation.locator="12";document.insert(citation)
        #expect(LaTeX.source(document).contains("see \\cite[12]"))
        let result=try await Composer.compile(document,engine:#require(Composer.detectedEngine()),allowNetwork:true)
        let text=try #require(PDFDocument(url:result.pdf)?.string)
        #expect(text.contains("Resolved standard reference"));#expect(text.contains("[?]") == false)
    }
    @Test(.enabled(if:ProcessInfo.processInfo.environment["NABERIUS_COMPOSE"]=="1"))
    func `two column journal tables retain every row across repeated floats`()async throws {
        var files=try Self.package().files
        files[0].data=Data(String(decoding:files[0].data,as:UTF8.self).replacingOccurrences(of:"[11pt]",with:"[11pt,twocolumn]").utf8)
        let package=try LaTeXTemplatePackage.analyze(files:files,sourceName:"two-column.zip")
        var document=Self.document(package)
        var table=AcademicNode(.table);table.caption="Long journal table";table.rows=[["Record","Value"]]+(0..<90).map{["Entry"+String($0),"Value"+String($0)]};document.insert(table)
        let result=try await Composer.compile(document,engine:#require(Composer.detectedEngine()),allowNetwork:true)
        let text=try #require(PDFDocument(url:result.pdf)?.string)
        for index in 0..<90 {#expect(text.contains("Entry"+String(index)))}
        #expect(result.log.contains("Overfull \\vbox") == false)
    }
    @Test(.enabled(if:ProcessInfo.processInfo.environment["NABERIUS_COMPOSE"]=="1"))
    func `an imported class composes actual native content in the restricted engine`()async throws {
        let package=try Self.package(),d=Self.document(package)
        let result=try await Composer.compile(d,engine:#require(Composer.detectedEngine()),allowNetwork:true)
        let pdf=try #require(PDFDocument(url:result.pdf)),text=pdf.string ?? ""
        #expect(text.contains("A real journal document"));#expect(text.contains("Native document text"));#expect(text.contains("Original sample text") == false)
    }
    @Test(.enabled(if:ProcessInfo.processInfo.environment["NABERIUS_COMPOSE"]=="1"))
    func `the supplied Springer ZIP configures and composes its real class`()async throws {
        let path=ProcessInfo.processInfo.environment["NABERIUS_TEMPLATE_FIXTURE"]
        guard let path else {return}
        let analysis=try TemplateImporter.analyze(URL(fileURLWithPath:path))
        let package=try #require(analysis.template.package)
        #expect(package.plan.documentClass=="sn-jnl");#expect(package.plan.options.contains("sn-mathphys-num"));#expect(package.plan.bibliographyStyles.count==9)
        var d=Self.document(package);d.template=analysis.template
        var reference=Reference();reference.title="Synthetic bibliography entry";reference.authors="Doe, Jane";reference.year="2024";d.references=[reference]
        var citation=AcademicNode(.citation);citation.referenceIDs=[reference.id];d.insert(citation)
        var equation=AcademicNode(.equation);equation.math.operation = .fraction;d.insert(equation)
        var table=AcademicNode(.table);table.caption="Synthetic table";d.insert(table)
        let result=try await Composer.compile(d,engine:#require(Composer.detectedEngine()),allowNetwork:true)
        let pdf=try #require(PDFDocument(url:result.pdf)),text=pdf.string ?? ""
        #expect(text.contains("A real journal document"));#expect(text.contains("Synthetic bibliography entry"));#expect(text.contains("[?]") == false)
        print("EDITORIAL_PDF \(result.pdf.path)")
    }
}
