import AppKit
import CoreText
import Testing
import NaberiusCore
@testable import Naberius

@MainActor struct EditorTests {
    @Test func `rich text roundtrip preserves marks styles inline nodes and block identity`()throws{
        _=NSApplication.shared
        var d=NabDocument.example;var bold=TextRun("Importante",bold:true,italic:true);bold.link="https://example.org";d.blocks.append(Block());d.blocks[d.blocks.count-1].runs=[bold]
        var math=AcademicNode(.equation);math.math.operation = .fraction;math.math.first="α + β";math.math.second="2";d.insert(math)
        let value=RichText.attributed(d,citations:CitationOutput())
        let decoded=RichText.blocks(value)
        #expect(decoded.map(\.id)==d.blocks.map(\.id));#expect(decoded.map(\.style)==d.blocks.map(\.style));#expect(decoded.last?.runs.first?.nodeID==math.id)
        let restored=try #require(decoded.first(where:{$0.runs.contains{$0.text=="Importante"}})?.runs.first)
        #expect(restored.bold);#expect(restored.italic);#expect(restored.link=="https://example.org")
    }
    @Test func `native typing stable identifiers undo and heading return`()throws{
        _=NSApplication.shared
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let session=Session(supportDirectory:folder);session.new()
        let t=NativeTextView(frame:NSRect(x:0,y:0,width:700,height:900));t.session=session
        let coordinator=NativeEditor.Coordinator(session);t.delegate=coordinator
        t.textStorage?.setAttributedString(RichText.attributed(session.document!,citations:CitationOutput()))
        t.typingAttributes=RichText.attributes(style:.heading1,template:session.document!.template);session.selectedStyle = .heading1
        t.insertText("Introducción",replacementRange:NSRange(location:0,length:0));let firstID=try #require(session.document?.blocks.first?.id)
        t.insertText(" al tema",replacementRange:NSRange(location:t.string.utf16.count,length:0))
        #expect(session.document?.blocks.first?.id==firstID)
        t.insertNewline(nil)
        #expect(session.selectedStyle == .paragraph)
        t.insertText("Texto del párrafo",replacementRange:t.selectedRange())
        #expect(session.document?.blocks.last?.style == .paragraph)
        #expect(session.document?.blocks.first?.style == .heading1)
        #expect(session.undo.canUndo)
        session.autosaveForTestingCleanup()
        try? FileManager.default.removeItem(at:folder)
    }
}
@MainActor struct ListEditingTests {
    @Test(arguments:[BlockStyle.bullet,BlockStyle.numbered]) func `semantic list formatting is immediate and empty return exits the list`(_ style:BlockStyle)throws{
        _=NSApplication.shared
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let session=Session(supportDirectory:folder);session.new()
        let t=NativeTextView(frame:NSRect(x:0,y:0,width:700,height:900));t.session=session
        let coordinator=NativeEditor.Coordinator(session);t.delegate=coordinator;t.typingAttributes=RichText.attributes(style:.paragraph,template:session.document!.template)
        t.insertText("Elemento",replacementRange:NSRange(location:0,length:0));t.applyStyle(style)
        #expect(t.string.hasPrefix(style == .bullet ? "•\t" : "1.\t"));#expect(session.document?.blocks.first?.text=="Elemento")
        t.setSelectedRange(NSRange(location:t.string.utf16.count,length:0));t.insertNewline(nil)
        #expect(t.string.hasSuffix(style == .bullet ? "•\t" : "2.\t"));t.insertNewline(nil)
        #expect(session.selectedStyle == .paragraph);#expect(session.document?.blocks.last?.style == .paragraph)
        session.autosaveForTestingCleanup()
    }
}
@MainActor struct OutlineTests {
    @Test func `outline navigation uses semantic identity after list markers`()throws{
        _=NSApplication.shared
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let session=Session(supportDirectory:folder);session.new(example:true)
        let document=try #require(session.document),target=try #require(document.blocks.last(where:{$0.style == .heading1}))
        let text=NativeTextView(frame:NSRect(x:0,y:0,width:700,height:900));text.session=session;session.editor=text
        text.textStorage?.setAttributedString(RichText.attributed(document,citations:CitationOutput()))
        session.reveal(blockID:target.id)
        let actual=text.attributedString().attribute(NSAttributedString.Key("nab.block"),at:text.selectedRange().location,effectiveRange:nil) as? String
        #expect(actual==target.id.uuidString)
        session.autosaveForTestingCleanup()
    }
}
@MainActor struct FigureTests {
    @Test func `tall figure preview preserves aspect ratio when height is bounded`()throws{
        _=NSApplication.shared
        let image=NSImage(size:NSSize(width:100,height:400),flipped:false){rect in NSColor.white.setFill();NSBezierPath(rect:rect).fill();return true}
        let data=try #require(image.tiffRepresentation)
        let asset=Asset(name:"Tall.tiff",mediaType:"image/png",data:data)
        var d=NabDocument();d.assets=[asset];var n=AcademicNode(.figure);n.assetID=asset.id;n.width=400;d.insert(n)
        let value=RichText.attachment(n,document:d,citations:CitationOutput(),attrs:RichText.attributes(style:.paragraph,template:d.template))
        let attachment=try #require(value.attribute(.attachment,at:0,effectiveRange:nil) as? NSTextAttachment)
        let cell=try #require(attachment.attachmentCell as? NSTextAttachmentCell),size=try #require(cell.image?.size)
        #expect(abs(size.width/(size.height-54)-0.25)<0.001)
    }
}

@MainActor struct TypographyTests {
    @Test func `document headings body and emphasis use bundled Latin Modern`() throws {
        _=NSApplication.shared
        let template=DocumentTemplate.builtins[0]
        for style in [BlockStyle.paragraph,.title,.heading1,.heading2] {
            let font=try #require(RichText.attributes(style:style,template:template)[.font] as? NSFont)
            #expect(font.fontName.hasPrefix("LMRoman10-"))
            #expect(NSFontManager.shared.traits(of:font).contains(.boldFontMask) == (style != .paragraph))
        }
    }
    @Test func `LaTeX logo changes glyphs without changing editing or exported characters`() throws {
        _=NSApplication.shared
        var d=NabDocument();d.blocks=[Block("Compuesto con Latex y TeX.")]
        let value=RichText.attributed(d,citations:CitationOutput())
        #expect(value.string==d.blocks[0].text)
        let text=NativeTextView(frame:NSRect(x:0,y:0,width:700,height:500));text.layoutManager?.delegate=text
        text.textStorage?.setAttributedString(value)
        let source=value.string as NSString
        let logo=source.range(of:"Latex")
        let font=try #require(value.attribute(.font,at:logo.location+1,effectiveRange:nil) as? NSFont)
        #expect(font.pointSize < (value.attribute(.font,at:logo.location,effectiveRange:nil) as! NSFont).pointSize)
        let lm=try #require(text.layoutManager)
        lm.ensureLayout(for:text.textContainer!)
        let actual=lm.glyph(at:lm.glyphIndexForCharacter(at:logo.location+1))
        let ct=CTFontCreateWithName(font.fontName as CFString,font.pointSize,nil)
        var capital:UniChar=65,glyph:CGGlyph=0
        #expect(CTFontGetGlyphsForCharacters(ct,&capital,&glyph,1))
        #expect(actual==glyph)
        let decoded=RichText.blocks(value)
        #expect(decoded[0].text==d.blocks[0].text)
        #expect(decoded[0].runs.count==1)
        d.blocks=decoded
        #expect(LaTeX.source(d).contains("\\LaTeX{}"))
    }
    @Test(.enabled(if:ProcessInfo.processInfo.environment["NABERIUS_COMPOSE"] == "1"))
    func `equation preview is cropped from an actual TeX PDF`() async throws {
        _=NSApplication.shared
        var math=MathExpression();math.operation = .fraction;math.first="α + β";math.second="2"
        let engine=try #require(Composer.detectedEngine())
        let output=try await Composer.compileMath(math,engine:engine,allowNetwork:true)
        let image=try EquationTypesetter.image(from:output.pdf)
        #expect(image.size.width>20);#expect(image.size.width<400)
        #expect(image.size.height>20);#expect(image.size.height<160)
        #expect(output.elapsed>0)
        print("MATH_TEST_OUTPUT \(output.pdf.path)")
    }
}

@MainActor struct LongDocumentEditingTests {
    @Test func `native edits preserve a long document and stable block identities`() throws {
        _=NSApplication.shared
        let support=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let session=Session(supportDirectory:support);session.new()
        let sentence=Array(repeating:"palabra",count:50).joined(separator:" ")
        session.mutate("Documento largo") {$0.blocks=(0..<1000).map {Block("\($0) "+sentence)}}
        let original=try #require(session.document)
        let text=NativeTextView(frame:NSRect(x:0,y:0,width:740,height:1000));text.session=session
        let coordinator=NativeEditor.Coordinator(session);text.delegate=coordinator
        text.textStorage?.setAttributedString(RichText.attributed(original,citations:CitationOutput()))
        text.typingAttributes=RichText.attributes(style:.paragraph,template:original.template)
        text.setSelectedRange(NSRange(location:text.string.utf16.count,length:0))
        let start=ContinuousClock.now
        for _ in 0..<40 {text.insertText("x",replacementRange:text.selectedRange())}
        let elapsed=start.duration(to:.now)
        let updated=try #require(session.document)
        #expect(updated.blocks.count==1000)
        #expect(updated.blocks.map(\.id)==original.blocks.map(\.id))
        #expect(updated.blocks.last?.text.hasSuffix(String(repeating:"x",count:40)) == true)
        #expect(updated.blocks.dropLast()==original.blocks.dropLast())
        print("NATIVE_TYPING_BENCHMARK 1000 paragraphs, 51000 words, 40 edits: \(elapsed)")
        session.autosaveForTestingCleanup()
    }
}

@MainActor struct ParagraphProjectionTests {
    @Test func `incremental edits handle middle paragraphs multiline insertion and final empty paragraph`() throws {
        _=NSApplication.shared
        let support=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let session=Session(supportDirectory:support);session.new()
        session.mutate {$0.blocks=[Block("Uno"),Block("Dos"),Block()]}
        let text=NativeTextView(frame:NSRect(x:0,y:0,width:700,height:800));text.session=session
        let coordinator=NativeEditor.Coordinator(session);text.delegate=coordinator
        text.textStorage?.setAttributedString(RichText.attributed(session.document!,citations:CitationOutput()))
        text.typingAttributes=RichText.attributes(style:.paragraph,template:session.document!.template)
        text.insertText("Final",replacementRange:NSRange(location:text.string.utf16.count,length:0))
        #expect(session.document?.blocks.map(\.text)==["Uno","Dos","Final"])
        let middle=(text.string as NSString).range(of:"Dos")
        text.insertText("DOS",replacementRange:middle)
        #expect(session.document?.blocks.map(\.text)==["Uno","DOS","Final"])
        text.insertText("Segunda\n",replacementRange:NSRange(location:4,length:0))
        #expect(session.document?.blocks.map(\.text)==["Uno","Segunda","DOS","Final"])
        session.autosaveForTestingCleanup()
    }
}

@MainActor struct ProofProtectionTests {
    @Test func `PDF proof protects the hidden editor from direct formatting and insertion`() throws {
        _=NSApplication.shared
        let session=Session(supportDirectory:FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString));session.new(example:true)
        let original=try #require(session.document)
        let text=NativeTextView(frame:NSRect(x:0,y:0,width:700,height:800));text.session=session;session.editor=text
        text.textStorage?.setAttributedString(RichText.attributed(original,citations:CitationOutput()))
        text.setSelectedRange(NSRange(location:0,length:4))
        let before=text.attributedString()
        session.showProof=true
        text.toggleBold();text.toggleItalic();text.applyStyle(.heading2);session.insert(AcademicNode(.separator))
        #expect(session.document==original)
        #expect(text.attributedString()==before)
        if let heading=original.blocks.first(where:{$0.style.headingLevel != nil}) {
            session.reveal(blockID:heading.id)
            #expect(!session.showProof)
        }
        session.autosaveForTestingCleanup()
    }
}

@MainActor struct InlineTableTests {
    @Test func `table preview stays bounded while complete data remains in the document`() throws {
        _=NSApplication.shared
        var node=AcademicNode(.table);node.rows=(0..<200).map{["Fila \($0)",String(repeating:"Contenido largo ",count:30)]};node.normalizeTableIdentity()
        let layout=TablePreviewLayout(node:node,width:520)
        #expect(layout.abbreviated);#expect(layout.heights.count==8);#expect(layout.height<=808)
        var document=NabDocument();document.insert(node)
        let restored=try NabArchive.decode(NabArchive.encode(document))
        #expect(restored.nodes.first?.rows.count==200)
        #expect(LaTeX.source(restored).contains("Fila 199"))
    }
    @Test func `inline edits group undo by cell and tab on the final cell appends a row`() throws {
        _=NSApplication.shared
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:folder)}
        let session=Session(supportDirectory:folder);session.new()
        var node=AcademicNode(.table);node.normalizeTableIdentity();session.mutate("Insertar tabla"){$0.insert(node)}
        session.undo.removeAllActions()
        let owner=NativeTextView(frame:NSRect(x:0,y:0,width:700,height:900));owner.session=session
        let overlay=InlineTableEditor(owner:owner,session:session,node:node)
        let field=TableCellField();field.rowID=node.rowIDs[1];field.columnID=node.columnIDs[1]
        field.stringValue="Uno";overlay.controlTextDidChange(Notification(name:NSControl.textDidChangeNotification,object:field))
        field.stringValue="Uno dos";overlay.controlTextDidChange(Notification(name:NSControl.textDidChangeNotification,object:field))
        #expect(session.document?.nodes.first?.rows[1][1]=="Uno dos")
        session.undo.undo();#expect(session.document?.nodes.first?.rows[1][1]=="")
        overlay.sync(try #require(session.document?.nodes.first))
        #expect(overlay.control(field,textView:NSTextView(),doCommandBy:#selector(NSResponder.insertTab(_:))))
        #expect(session.document?.nodes.first?.rows.count==3)
        #expect(session.document?.nodes.first?.rowIDs.prefix(2)==node.rowIDs.prefix(2))
        session.autosaveForTestingCleanup()
    }
}

@MainActor struct BibliographyReviewTests {
    @Test func `review imports only selected references into the document library`() throws {
        _=NSApplication.shared
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:folder)}
        let session=Session(supportDirectory:folder);session.new()
        let report=try BibliographyImporter.bibTeX("@book{first,title={First}} @book{second,title={Second},usera={Preserved}}")
        session.bibliographyImport=report;session.sheet = .library
        session.acceptBibliography([report.references[1].id])
        #expect(session.document?.references.count==1)
        #expect(session.document?.references.first?.imported?.fields["usera"]=="Preserved")
        #expect(session.library.isEmpty);#expect(session.sheet == .library);#expect(session.bibliographyImport==nil)
        session.autosaveForTestingCleanup()
    }
}
