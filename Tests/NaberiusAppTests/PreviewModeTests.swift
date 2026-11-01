import Foundation
import Testing
@testable import NaberiusCore
@testable import Naberius

@MainActor private final class PreviewCompiler:DocumentCompiling {
    var requests:[NabDocument]=[]
    var fail=false
    var delay=0.0
    let pdf=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".pdf")
    func engine()->URL? {URL(fileURLWithPath:"/synthetic-engine")}
    func run(_ document:NabDocument,_ engine:URL,_ allowNetwork:Bool)async throws->Compilation {
        #expect(!allowNetwork)
        requests.append(document)
        if delay>0 {try await Task.sleep(for:.seconds(delay))}
        if fail {throw NabError.invalid("Synthetic compilation failure")}
        return Compilation(pdf:pdf,log:"synthetic",engine:engine,completedAt:Date(),elapsed:0)
    }
}

@MainActor struct PreviewModeTests {
    private func session(_ compiler:PreviewCompiler)->Session {
        let preferences=UserDefaults(suiteName:"NaberiusTests."+UUID().uuidString)!
        let session=Session(supportDirectory:FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),compilationService:compiler,preferences:preferences)
        session.new();session.previewDelay=0.02
        return session
    }
    private func cleanup(_ session:Session) {session.autosaveForTestingCleanup();try? FileManager.default.removeItem(at:session.support)}

    @Test func `rapid edits compile the latest snapshot once without changing mode`()async throws {
        let compiler=PreviewCompiler(),session=session(compiler);defer{cleanup(session)}
        session.setEditorMode(.combined)
        for index in 1...5 {session.mutate(registerUndo:false){$0.blocks=[Block("Edit \(index)")]}}
        await session.waitForPreviewForTesting()
        #expect(compiler.requests.count==1)
        #expect(compiler.requests.last?.blocks.first?.text=="Edit 5")
        #expect(session.editorMode == .combined)
        #expect(!session.proofNeedsUpdate)
        #expect(session.error==nil)
    }
    @Test func `automatic preview sleeps while inactive and manual refresh works when disabled`()async {
        let compiler=PreviewCompiler(),session=session(compiler);defer{cleanup(session)}
        session.setPreviewActive(false);session.setEditorMode(.combined)
        session.mutate(registerUndo:false){$0.metadata.title="Inactive"}
        await session.waitForPreviewForTesting();#expect(compiler.requests.isEmpty)
        session.setPreviewActive(true);await session.waitForPreviewForTesting();#expect(compiler.requests.count==1)
        session.setAutomaticPreview(false)
        session.mutate(registerUndo:false){$0.metadata.title="Manual"}
        await session.waitForPreviewForTesting();#expect(compiler.requests.count==1)
        session.compile(presentProof:false);await session.waitForPreviewForTesting()
        #expect(compiler.requests.count==2);#expect(!session.proofNeedsUpdate)
    }
    @Test func `automatic failures stay inline and do not retry the same revision`()async {
        let compiler=PreviewCompiler();compiler.fail=true
        let session=session(compiler);defer{cleanup(session)}
        session.setEditorMode(.combined);await session.waitForPreviewForTesting()
        #expect(session.previewIssue != nil);#expect(session.error==nil)
        session.setPreviewActive(true);await session.waitForPreviewForTesting()
        #expect(compiler.requests.count==1)
        compiler.fail=false;session.mutate(registerUndo:false){$0.metadata.title="Recovered"}
        await session.waitForPreviewForTesting()
        #expect(compiler.requests.count==2);#expect(session.previewIssue==nil)
    }
    @Test func `leaving combined mode cancels a pending compilation`()async {
        let compiler=PreviewCompiler(),session=session(compiler);defer{cleanup(session)}
        session.setEditorMode(.combined);session.setEditorMode(.writing)
        await session.waitForPreviewForTesting()
        #expect(compiler.requests.isEmpty);#expect(session.previewURL==nil)
    }
    @Test func `a cancelled composition cannot replace the next document PDF`()async throws {
        let compiler=PreviewCompiler();compiler.delay=0.2
        let session=session(compiler);defer{cleanup(session)}
        session.setEditorMode(.combined)
        session.compile(presentProof:false,automatic:true)
        await Task.yield()
        session.setEditorMode(.writing);session.new()
        try await Task.sleep(for:.seconds(0.25))
        #expect(session.previewURL==nil);#expect(!session.compiling)
    }
    @Test func `a completed manual snapshot leaves later edits marked as stale`()async throws {
        let compiler=PreviewCompiler();compiler.delay=0.05
        let session=session(compiler);defer{cleanup(session)}
        session.setAutomaticPreview(false);session.setEditorMode(.combined)
        session.compile(presentProof:false)
        await Task.yield()
        session.mutate(registerUndo:false){$0.metadata.title="Later edit"}
        await session.waitForPreviewForTesting()
        #expect(session.previewURL != nil);#expect(session.proofNeedsUpdate)
        #expect(compiler.requests.count==1)
    }

    @Test func `reopening without a cached PDF schedules a new proof even at the same revision`()async {
        let compiler=PreviewCompiler(),session=session(compiler);defer{cleanup(session)}
        session.setEditorMode(.combined);await session.waitForPreviewForTesting()
        #expect(!session.proofNeedsUpdate)
        session.previewURL=nil
        #expect(session.proofNeedsUpdate)
        session.setEditorMode(.combined);await session.waitForPreviewForTesting()
        #expect(compiler.requests.count==2);#expect(!session.proofNeedsUpdate)
    }

}
