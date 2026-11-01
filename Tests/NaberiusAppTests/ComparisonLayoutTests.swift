import AppKit
import Foundation
import Testing
@testable import Naberius

@MainActor struct ComparisonLayoutTests {
    @Test func `comparison starts balanced and restores a manually adjusted divider across modes`()async throws {
        _=NSApplication.shared
        let preferences=UserDefaults(suiteName:"NaberiusSplitTests."+UUID().uuidString)!
        preferences.set(false,forKey:"automaticPreview")
        let support=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let session=Session(supportDirectory:support,preferences:preferences)
        session.new();session.setEditorMode(.combined,persist:false)
        defer{session.autosaveForTestingCleanup();try? FileManager.default.removeItem(at:support)}
        let split=NSSplitView(frame:NSRect(x:0,y:0,width:1000,height:700));split.isVertical=true
        let left=NSView(frame:NSRect(x:0,y:0,width:800,height:700)),right=NSView(frame:NSRect(x:801,y:0,width:199,height:700))
        split.addSubview(left);split.addSubview(right);split.setPosition(800,ofDividerAt:0)
        let coordinator=NativeEditor.Coordinator(session)
        coordinator.updateComparisonLayout(from:left,combined:true)
        await coordinator.splitBalanceTask?.value
        #expect(abs(left.frame.width-(split.bounds.width-split.dividerThickness)/2)<2)
        split.setPosition(650,ofDividerAt:0)
        NotificationCenter.default.post(name:NSSplitView.didResizeSubviewsNotification,object:split)
        coordinator.updateComparisonLayout(from:left,combined:true)
        #expect(abs(left.frame.width-650)<2)
        session.setEditorMode(.writing,persist:false);coordinator.updateComparisonLayout(from:left,combined:false)
        split.setPosition(900,ofDividerAt:0)
        session.setEditorMode(.combined,persist:false);coordinator.updateComparisonLayout(from:left,combined:true)
        await coordinator.splitBalanceTask?.value
        #expect(abs(left.frame.width-650)<2)
    }
}
