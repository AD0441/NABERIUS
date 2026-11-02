import AppKit
import PDFKit
import Testing
@testable import NaberiusCore
@testable import Naberius

@MainActor private final class NavigationCompiler:DocumentCompiling {
    private(set) var outputs:[URL]=[]
    func engine()->URL? {URL(fileURLWithPath:"/synthetic")}
    func run(_ document:NabDocument,_ engine:URL,_ allowNetwork:Bool)async throws->Compilation {
        let url=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".pdf")
        let pdf=PDFDocument(),page=PDFPage();page.setBounds(CGRect(x:0,y:0,width:595,height:842),for:.mediaBox);pdf.insert(page,at:0)
        #expect(pdf.write(to:url));outputs.append(url)
        var result=Compilation(pdf:url,log:"synthetic",engine:engine,completedAt:Date(),elapsed:0)
        result.synchronization=PDFSynchronization(documentID:document.id,pdf:url,sources:Dictionary(uniqueKeysWithValues:document.blocks.map{($0.id,url.deletingPathExtension().appendingPathComponent($0.id.uuidString+".tex"))}))
        return result
    }
}
@MainActor private final class NavigationService:PDFNavigating {
    var requested:[UUID]=[]
    var inverseID:UUID?
    var delay=0.0
    func locations(_ map:PDFSynchronization,_ blockID:UUID,_ pageHint:Int)async throws->[PDFSourceLocation] {
        requested.append(blockID)
        if delay>0 {try? await Task.sleep(for:.seconds(delay))}
        return [PDFSourceLocation(page:0,bounds:CGRect(x:30,y:50,width:200,height:15),blockID:blockID)]
    }
    func source(_ map:PDFSynchronization,_ point:CGPoint,_ page:Int)async throws->PDFSourceLocation? {
        if delay>0 {try? await Task.sleep(for:.seconds(delay))}
        return inverseID.map{PDFSourceLocation(page:0,bounds:CGRect(x:30,y:50,width:200,height:15),blockID:$0)}
    }
}
@MainActor struct PDFNavigationTests {
    private func prepare(_ compiler:NavigationCompiler,_ navigation:NavigationService)async->Session {
        _=NSApplication.shared
        let preferences=UserDefaults(suiteName:"NaberiusNavigation."+UUID().uuidString)!
        preferences.set(false,forKey:"automaticPreview")
        let session=Session(supportDirectory:FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),compilationService:compiler,preferences:preferences,navigationService:navigation)
        session.new();session.mutate{$0.blocks=[Block("Primer párrafo"),Block("Segundo párrafo")]} ;session.undo.removeAllActions()
        let editor=NativeTextView();editor.session=session;session.editor=editor
        if let document=session.document {editor.textStorage?.setAttributedString(RichText.attributed(document,citations:CitationOutput()))}
        session.compile(presentProof:false);await session.waitForPreviewForTesting()
        return session
    }
    private func cleanup(_ session:Session,_ compiler:NavigationCompiler) {
        session.autosaveForTestingCleanup();try? FileManager.default.removeItem(at:session.support)
        for url in compiler.outputs {try? FileManager.default.removeItem(at:url)}
    }
    @Test func `forward and inverse navigation preserve content and undo while selecting the correct paragraph`()async throws {
        let compiler=NavigationCompiler(),navigation=NavigationService(),session=await prepare(compiler,navigation)
        defer{cleanup(session,compiler)}
        let document=try #require(session.document),target=document.blocks[1].id
        session.selectedBlock=target;session.locateSelectionInPDF();await session.waitForNavigationForTesting()
        #expect(session.pdfNavigation?.location.blockID==target);#expect(session.editorMode == .combined)
        navigation.inverseID=document.blocks[0].id
        session.locatePDFSource(at:CGPoint(x:60,y:60),page:0);await session.waitForNavigationForTesting()
        let editor=try #require(session.editor),range=editor.selectedRange()
        #expect(range.length>0)
        #expect(editor.attributedString().attribute(NSAttributedString.Key("nab.block"),at:range.location,effectiveRange:nil) as? String==document.blocks[0].id.uuidString)
        #expect(session.document?.blocks==document.blocks);#expect(session.undo.canUndo==false)
    }
    @Test func `stale PDF cannot navigate and a late result cannot move the next revision`()async throws {
        let compiler=NavigationCompiler(),navigation=NavigationService(),session=await prepare(compiler,navigation)
        defer{cleanup(session,compiler)}
        session.selectedBlock=try #require(session.document?.blocks.first?.id)
        navigation.delay=0.15;session.locateSelectionInPDF();await Task.yield()
        session.mutate{$0.blocks[0].runs=[TextRun("Texto cambiado")]} ;await session.waitForNavigationForTesting()
        #expect(session.pdfNavigation==nil)
        let count=navigation.requested.count
        session.locateSelectionInPDF();await session.waitForNavigationForTesting()
        #expect(navigation.requested.count==count);#expect(session.synchronizationMessage?.contains("Actualiza")==true)
        session.locatePDFSource(at:.zero,page:0);await session.waitForNavigationForTesting()
        #expect(session.pdfNavigation==nil)
    }
    @Test func `recomposition replaces the map and queries from another document are discarded`()async throws {
        let compiler=NavigationCompiler(),navigation=NavigationService(),session=await prepare(compiler,navigation)
        defer{cleanup(session,compiler)}
        session.selectedBlock=try #require(session.document?.blocks.first?.id)
        session.locateSelectionInPDF();await session.waitForNavigationForTesting()
        let old=try #require(session.pdfNavigation?.pdf)
        session.compile(presentProof:false);await session.waitForPreviewForTesting()
        session.locateSelectionInPDF();await session.waitForNavigationForTesting()
        #expect(session.pdfNavigation?.pdf==session.previewURL);#expect(session.pdfNavigation?.pdf != old)
        navigation.delay=0.15;session.locateSelectionInPDF();await Task.yield();session.new();await session.waitForNavigationForTesting()
        #expect(session.pdfNavigation==nil);#expect(session.compilation==nil)
    }
    @Test func `unmapped PDF regions do not select an unrelated paragraph and coordinates flip correctly`()async {
        let compiler=NavigationCompiler(),navigation=NavigationService(),session=await prepare(compiler,navigation)
        defer{cleanup(session,compiler)}
        navigation.inverseID=UUID()
        session.locatePDFSource(at:.zero,page:0);await session.waitForNavigationForTesting()
        #expect(session.pdfNavigation==nil);#expect(session.synchronizationMessage?.contains("No hay un párrafo editable")==true)
        #expect(FittingPDFView.pageRect(CGRect(x:20,y:50,width:100,height:15),mediaBounds:CGRect(x:10,y:20,width:595,height:842))==CGRect(x:30,y:797,width:100,height:15))
    }
}
