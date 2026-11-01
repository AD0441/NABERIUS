import AppKit
import PDFKit
import Testing
@testable import Naberius

@MainActor struct PDFViewportTests {
    @Test func `fit mode keeps the whole page within a narrow viewport and manual zoom remains explicit`()throws {
        _=NSApplication.shared
        let image=NSImage(size:NSSize(width:600,height:840),flipped:false){rect in NSColor.white.setFill();rect.fill();return true}
        let document=PDFDocument();document.insert(try #require(PDFPage(image:image)),at:0)
        let view=FittingPDFView(frame:NSRect(x:0,y:0,width:400,height:500))
        view.autoScales=false;view.document=document;view.layout()
        let page=try #require(document.page(at:0)),size=page.bounds(for:view.displayBox).size
        #expect(size.width*view.scaleFactor<=400)
        #expect(size.height*view.scaleFactor<=500)
        view.fitsPage=false;view.scaleFactor=1.25;view.layout()
        #expect(abs(view.scaleFactor-1.25)<0.001)
    }
}
