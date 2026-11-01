import SwiftUI
import AppKit
import NaberiusCore

/// AppKit owns pane frames; SwiftUI owns their content and document state.
struct ComparisonWorkspace:NSViewRepresentable {
    let session:Session
    let mode:EditorMode
    let columnWidth:Bool
    @Environment(\.colorScheme) private var colorScheme

    func makeCoordinator()->Coordinator {Coordinator()}
    func makeNSView(context:Context)->NSSplitView {
        let split=NSSplitView();split.isVertical=true;split.dividerStyle = .thin;split.delegate=context.coordinator
        let editor=NSHostingView(rootView:editorContent),proof=NSHostingView(rootView:proofContent)
        editor.sizingOptions=[];proof.sizingOptions=[]
        split.addSubview(editor);split.addSubview(proof)
        context.coordinator.editor=editor;context.coordinator.proof=proof
        context.coordinator.configure(split,combined:mode == .combined)
        return split
    }
    func updateNSView(_ split:NSSplitView,context:Context) {
        context.coordinator.editor?.rootView=editorContent
        context.coordinator.proof?.rootView=proofContent
        context.coordinator.configure(split,combined:mode == .combined)
    }
    private var editorContent:ComparisonEditorPane {ComparisonEditorPane(session:session,columnWidth:columnWidth,scheme:colorScheme)}
    private var proofContent:ComparisonProofPane {ComparisonProofPane(session:session,active:mode == .combined,scheme:colorScheme)}

    final class Coordinator:NSObject,NSSplitViewDelegate {
        var editor:NSHostingView<ComparisonEditorPane>?
        var proof:NSHostingView<ComparisonProofPane>?
        private var combined=false
        private var fraction=0.5
        private var applying=false
        func configure(_ split:NSSplitView,combined:Bool) {
            let changed=self.combined != combined
            self.combined=combined
            applying=true
            if split.subviews.count==2,split.subviews[1].isHidden == combined {split.subviews[1].isHidden = !combined}
            applying=false
            if changed || split.subviews.first?.frame.width==0 {resize(split)}
        }
        private func resize(_ split:NSSplitView) {
            guard !applying,split.subviews.count==2 else{return}
            applying=true;defer{applying=false}
            let available=max(0,split.bounds.width-(combined ? split.dividerThickness : 0))
            let minimum=min(320,available/2)
            let left=combined ? min(available-minimum,max(minimum,available*fraction)) : available
            split.subviews[0].frame=NSRect(x:0,y:0,width:left,height:split.bounds.height)
            split.subviews[1].frame=NSRect(x:left+(combined ? split.dividerThickness : 0),y:0,width:max(0,available-left),height:split.bounds.height)
        }
        func splitView(_ splitView:NSSplitView,resizeSubviewsWithOldSize oldSize:NSSize) {resize(splitView)}
        func splitViewDidResizeSubviews(_ notification:Notification) {
            guard combined,!applying,let split=notification.object as? NSSplitView,split.subviews.count==2 else{return}
            let available=split.bounds.width-split.dividerThickness
            if available>0 {fraction=min(0.95,max(0.05,split.subviews[0].frame.width/available))}
        }
        func splitView(_ splitView:NSSplitView,constrainMinCoordinate proposedMinimumPosition:CGFloat,ofSubviewAt dividerIndex:Int)->CGFloat {
            min(320,max(0,(splitView.bounds.width-splitView.dividerThickness)/2))
        }
        func splitView(_ splitView:NSSplitView,constrainMaxCoordinate proposedMaximumPosition:CGFloat,ofSubviewAt dividerIndex:Int)->CGFloat {
            let available=max(0,splitView.bounds.width-splitView.dividerThickness)
            return max(available/2,available-320)
        }
        func splitView(_ splitView:NSSplitView,shouldHideDividerAt dividerIndex:Int)->Bool {!combined}
        func splitView(_ splitView:NSSplitView,canCollapseSubview subview:NSView)->Bool {false}
    }
}

struct ComparisonEditorPane:View {
    @Bindable var session:Session
    let columnWidth:Bool
    let scheme:ColorScheme
    var body:some View {
        NativeEditor(session:session)
            .frame(maxWidth:session.pageMode ? (columnWidth && session.document?.template.effectiveLayout.columnCount==2 ? 450 : 780) : .infinity)
            .padding(.horizontal,session.pageMode ? 12 : 0)
            .frame(maxWidth:.infinity,maxHeight:.infinity)
            .environment(\.colorScheme,scheme)
    }
}
struct ComparisonProofPane:View {
    @Bindable var session:Session
    let active:Bool
    let scheme:ColorScheme
    var body:some View {
        Group {if active {CombinedProofView(session:session)} else {Color.clear}}
            .environment(\.colorScheme,scheme)
    }
}
