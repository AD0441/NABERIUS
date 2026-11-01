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
        let coordinator=ComparisonWorkspace.Coordinator();split.delegate=coordinator
        coordinator.configure(split,combined:true)
        #expect(abs(left.frame.width-(split.bounds.width-split.dividerThickness)/2)<2)
        split.setPosition(650,ofDividerAt:0)
        coordinator.splitViewDidResizeSubviews(Notification(name:NSSplitView.didResizeSubviewsNotification,object:split))
        coordinator.configure(split,combined:true)
        #expect(abs(left.frame.width-650)<2)
        session.setEditorMode(.writing,persist:false);coordinator.configure(split,combined:false)
        split.setPosition(900,ofDividerAt:0)
        session.setEditorMode(.combined,persist:false);coordinator.configure(split,combined:true)
        #expect(abs(left.frame.width-650)<2)
        split.setFrameSize(NSSize(width:1200,height:700))
        coordinator.splitView(split,resizeSubviewsWithOldSize:NSSize(width:1000,height:700))
        #expect(abs(left.frame.width/(split.bounds.width-split.dividerThickness)-650/999.0)<0.02)
        split.setFrameSize(NSSize(width:800,height:700))
        coordinator.splitView(split,resizeSubviewsWithOldSize:NSSize(width:1200,height:700))
        #expect(left.frame.width>=320);#expect(right.frame.width>=320)
    }
}
