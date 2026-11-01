import Foundation
import Testing
import PDFKit
@testable import NaberiusCore

struct TemplateCompatibilityTests {
    private func package(_ source:String,_ resources:[TemplateFile]=[])throws->LaTeXTemplatePackage {
        try LaTeXTemplatePackage.analyze(files:[TemplateFile(path:"main.tex",data:Data(source.utf8))]+resources,sourceName:"independent-fixture.zip")
    }
    @Test func `explicit bibliography style after the body wins over bundled styles`()throws {
        let source="\\documentclass{article}\n\\begin{document}\\section{Start}Body\\bibliographystyle{unsrt}\\bibliography{sample}\\end{document}"
        let package=try package(source,[TemplateFile(path:"other.bst",data:Data("unused".utf8))])
        let document=TemplatePackageTests.document(package)
        let result=LaTeX.source(document)
        #expect(result.contains("\\bibliographystyle{unsrt}"));#expect(!result.contains("\\bibliographystyle{other}"))
        #expect(package.files.first?.data==Data(source.utf8))
    }
    @Test func `title funding and bilingual environments remain separate editable fields`()throws {
        let source=#"""
        \documentclass{article}
        \title{Short title\thanks{Funding note}}
        \begin{document}\maketitle
        \begin{englishabstract}English text\end{englishabstract}
        \begin{frenchabstract}Texte français\end{frenchabstract}
        \begin{keywords}\item first\item second\end{keywords}
        \section{Start}Body\end{document}
        """#
        let package=try package(source)
        var metadata=package.initialMetadata()
        #expect(metadata.title=="Short title");#expect(metadata.abstract=="English text")
        #expect(metadata.keywords=="first; second")
        #expect(package.customFields.contains{$0.macro=="thanks"})
        #expect(package.customFields.contains{$0.macro=="frenchabstract"})
        metadata.title="New & safe";metadata.keywords="alpha; beta & gamma"
        let prefix=package.prefix(metadata:metadata)
        #expect(prefix.contains("\\title{New \\& safe\\thanks{Funding note}}"))
        #expect(prefix.contains("\\item alpha\n\\item beta \\& gamma"))
        #expect(prefix.contains("Texte français"))
        let funding=try #require(package.customFields.first{$0.macro=="thanks"})
        metadata.templateFields=[funding.id:""]
        #expect(!package.prefix(metadata:metadata).contains("\\thanks{"))
    }
    @Test func `IEEE keyword environment is detected without exposing author macros as title text`()throws {
        let package=try package(#"\documentclass{article}\title{Title}\author{\IEEEauthorblockN{One}\IEEEauthorblockA{University}}\begin{document}\maketitle\begin{IEEEkeywords}Alpha, Beta\end{IEEEkeywords}\section{Start}Body\end{document}"#)
        #expect(package.initialMetadata().keywords=="Alpha, Beta")
        #expect(package.customFields.contains{$0.macro=="IEEEauthorblockN"})
    }
    @Test func `completion retains the main source and validates resource paths`()throws {
        let source=#"\documentclass{journal}\begin{document}\section{Start}Body\end{document}"#
        let original=try package(source);#expect(original.hasExternalClass)
        let completed=try original.addingResources([TemplateFile(path:"journal.cls",data:Data(#"\LoadClass[10pt,twocolumn]{article}\RequirePackage{mathptmx}"#.utf8)),TemplateFile(path:"main.tex",data:Data("replacement".utf8))])
        #expect(!completed.hasExternalClass);#expect(completed.files.first?.data==Data(source.utf8))
        #expect(completed.editingDefaults().columns==2);#expect(completed.editingDefaults().fontSize==10);#expect(completed.editingDefaults().font=="Times New Roman")
        #expect(throws:NabError.self){try original.addingResources([TemplateFile(path:"../outside.cls",data:Data())])}
    }
    @Test func `free variants preserve editing hints and unlock a separate design`() {
        var template=DocumentTemplate.builtins[0];template.locked=true;template.lockedProperties=TemplateProperty.allCases
        let copy=template.freeVariant()
        #expect(copy.id != template.id);#expect(copy.package==nil);#expect(!copy.locked)
        #expect(copy.font==template.font);#expect(copy.allows(.layout))
    }
    @Test func `columns and asymmetric margins round trip with schema three`()throws {
        var document=NabDocument();var layout=document.template.effectiveLayout
        layout.columnCount=2;layout.columnSeparationMM=8;layout.marginLeftMM=18;layout.marginRightMM=23
        document.template.layout=layout
        let restored=try NabArchive.decode(NabArchive.encode(document))
        #expect(restored.schemaVersion==3);#expect(restored.template.layout==layout)
        let source=LaTeX.source(restored)
        #expect(source.contains(",twocolumn]{article}"));#expect(source.contains("left=18.0mm,right=23.0mm"));#expect(source.contains("\\columnsep}{8.0mm}"))
        document.template.layout?.columns=3
        #expect(throws:NabError.self){try NabArchive.validate(document)}
    }
    @Test(.enabled(if:ProcessInfo.processInfo.environment["NABERIUS_COMPOSE"] == "1"))
    func `two column layout composes asymmetric margins and all long table rows`()async throws {
        var document=NabDocument(template:try #require(DocumentTemplate.builtins.first{$0.id=="article-two-columns"}))
        document.metadata.title="Two column validation"
        document.blocks=[Block(document.metadata.title,style:.title)]+(1...25).map{Block("Paragraph \($0). "+String(repeating:"Synthetic text verifies column flow and spacing. ",count:8))}
        document.template.layout?.marginLeftMM=18;document.template.layout?.marginRightMM=23
        document.template.layout?.columnSeparationMM=8
        var table=AcademicNode(.table);table.caption="All rows";table.rows=[["Row","Value"]]+(1...90).map{["Row \($0)","Marker \($0)"]};document.insert(table)
        let result=try await Composer.compile(document,engine:try #require(Composer.detectedEngine()),allowNetwork:true)
        let pdf=try #require(PDFDocument(url:result.pdf))
        #expect(pdf.pageCount>1);#expect(pdf.string?.contains("Marker 90")==true)
        print("TWO_COLUMN_PDF \(result.pdf.path)")
    }
    @Test func `temporary cleanup removes only a Naberius compiler workspace`()async throws {
        let root=FileManager.default.temporaryDirectory
        let owned=root.appendingPathComponent("Naberius-"+UUID().uuidString),unrelated=root.appendingPathComponent(UUID().uuidString)
        for folder in [owned,unrelated] {try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)}
        defer{try? FileManager.default.removeItem(at:owned);try? FileManager.default.removeItem(at:unrelated)}
        let engine=URL(fileURLWithPath:"/synthetic")
        for folder in [owned,unrelated] {
            let result=Compilation(pdf:folder.appendingPathComponent("main.pdf"),log:"",engine:engine,completedAt:Date(),elapsed:0)
            await Composer.discard(result)
        }
        #expect(!FileManager.default.fileExists(atPath:owned.path));#expect(FileManager.default.fileExists(atPath:unrelated.path))
    }

    @Test func `legacy class font encoding is prepared without changing its font family`()throws {
        let source=#"\documentclass{journal}\begin{document}\section{Start}Body\end{document}"#
        let cls=TemplateFile(path:"journal.cls",data:Data(#"\LoadClass{article}\renewcommand{\rmdefault}{ptm}"#.utf8))
        let package=try package(source,[cls]);#expect(package.needsLegacyFontEncoding)
        let result=LaTeX.source(TemplatePackageTests.document(package))
        #expect(result.hasPrefix("\\RequirePackage[T1]{fontenc}\n\\documentclass"))
        #expect(package.files.last?.data==cls.data)
        let unicode=try self.package(source.replacingOccurrences(of:"\\begin{document}",with:"\\usepackage{fontspec}\\begin{document}"),[cls])
        #expect(!unicode.needsLegacyFontEncoding)
    }

}
