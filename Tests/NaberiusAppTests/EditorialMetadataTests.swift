import AppKit
import Foundation
import Testing
import NaberiusCore
@testable import Naberius

@MainActor struct EditorialMetadataTests {
    @Test func `editorial title edits stay synchronized with properties and undo`()throws {
        _=NSApplication.shared
        let support=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:support)}
        let source="\\documentclass{article}\n\\title{Original}\n\\author{Example}\n\\begin{document}\\maketitle\\section{Introduction}Sample\\end{document}"
        var template=DocumentTemplate.builtins[0]
        template.package=try LaTeXTemplatePackage.analyze(files:[TemplateFile(path:"main.tex",data:Data(source.utf8))],sourceName:"independent.zip")
        let session=Session(supportDirectory:support);session.new(template:template);session.undo.groupsByEvent=false
        defer{session.autosaveForTestingCleanup()}
        #expect(session.document?.schemaVersion==2)
        session.undo.beginUndoGrouping()
        session.mutate("Property title"){$0.metadata.title="Property title"}
        session.undo.endUndoGrouping()
        #expect(session.document?.blocks.first?.text=="Property title")
        session.undo.beginUndoGrouping()
        session.mutate("Typed title"){$0.blocks[0].runs=[TextRun("Typed title")]}
        session.undo.endUndoGrouping()
        #expect(session.document?.metadata.title=="Typed title")
        #expect(LaTeX.source(try #require(session.document)).contains("\\title{Typed title}"))
        session.undo.undo()
        #expect(session.document?.metadata.title=="Property title")
        #expect(session.document?.blocks.first?.text=="Property title")
    }
}
