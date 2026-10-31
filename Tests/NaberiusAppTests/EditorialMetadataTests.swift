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

@MainActor struct EditorialCaretTests {
    @Test func `typing in the final empty paragraph does not inherit the preceding heading`()throws {
        _=NSApplication.shared
        let support=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let session=Session(supportDirectory:support);session.new()
        defer{session.autosaveForTestingCleanup();try? FileManager.default.removeItem(at:support)}
        session.mutate {$0.blocks=[Block("Heading",style:.heading1),Block()]}
        let document=try #require(session.document),last=try #require(document.blocks.last)
        let text=NativeTextView(frame:NSRect(x:0,y:0,width:700,height:800));text.session=session
        let coordinator=NativeEditor.Coordinator(session);text.delegate=coordinator
        text.textStorage?.setAttributedString(RichText.attributed(document,citations:CitationOutput()))
        text.typingAttributes=RichText.attributes(style:.heading1,template:document.template)
        text.setSelectedRange(NSRange(location:text.string.utf16.count,length:0))
        coordinator.textViewDidChangeSelection(Notification(name:NSTextView.didChangeSelectionNotification,object:text))
        #expect(session.selectedStyle == .paragraph)
        #expect(session.selectedBlock==last.id)
        text.insertText("Cuerpo de prueba",replacementRange:text.selectedRange())
        #expect(session.document?.blocks.last?.style == .paragraph)
        #expect(session.document?.blocks.last?.text=="Cuerpo de prueba")
        #expect(session.document?.blocks.last?.id==last.id)
    }
}
