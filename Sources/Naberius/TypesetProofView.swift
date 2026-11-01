import SwiftUI
import PDFKit
import NaberiusCore

struct TypesetProofView: View {
    @Bindable var session: Session
    @State private var details = false
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.text("PDF compuesto con LaTeX")).font(.headline)
                    if let result = session.compilation {
                        Text(L10n.format("Tectonic · %@ s · %@",String(format:"%.1f",result.elapsed),result.completedAt.formatted(date:.omitted,time:.shortened)))
                            .font(.caption).foregroundStyle(.secondary)
                    } else { Text(L10n.text("La composición determina fuentes, ecuaciones y páginas finales.")).font(.caption).foregroundStyle(.secondary) }
                }
                Spacer()
                if session.compiling {
                    ProgressView().controlSize(.small)
                    Button(L10n.text("Cancelar")) { session.cancelCompile() }
                } else {
                    Button(L10n.text("Actualizar PDF")) { session.compile() }
                }
                Button { session.showProof = false } label: { Label(L10n.text("Escribir"), systemImage: "square.and.pencil") }
            }.padding(16)
            Divider()
            if session.previewURL != nil && session.proofNeedsUpdate {
                HStack {
                    Label(L10n.text("El documento cambió desde esta composición."), systemImage: "clock.arrow.circlepath")
                    Spacer()
                    Text(L10n.text("Actualiza para ver los cambios."))
                }.font(.caption).foregroundStyle(.secondary).padding(.horizontal,16).padding(.vertical,9)
                Divider()
            }
            if let url = session.previewURL {
                ProofPDFView(url: url, session: session)
                Divider()
                HStack {
                    Button { session.proofPage = max(0,session.proofPage-1) } label: { Image(systemName:"chevron.left") }.disabled(session.proofPage == 0).help(L10n.text("Página anterior del PDF"))
                    Text(L10n.format("Página %@ de %@",session.proofPage+1,session.proofPageCount)).monospacedDigit()
                    Button { session.proofPage = min(session.proofPageCount-1,session.proofPage+1) } label: { Image(systemName:"chevron.right") }.disabled(session.proofPage+1 >= session.proofPageCount).help(L10n.text("Página siguiente del PDF"))
                    Menu(L10n.text("Zoom del PDF")) {
                        Button(L10n.text("Ajustar a la ventana")) {session.proofZoom=nil}
                        ForEach([0.5,0.75,1,1.25,1.5,2.0],id:\.self) {scale in Button("\(Int(scale*100)) %") {session.proofZoom=scale}}
                    }.fixedSize()
                    Spacer()
                    Button(L10n.text("Detalles de composición")) { details.toggle() }
                    Button(L10n.text("Guardar PDF…")) { session.sheet = .export }.buttonStyle(.borderedProminent)
                }.font(.caption).padding(12)
            } else {
                ContentUnavailableView(session.compiling ? L10n.text("Componiendo con LaTeX…") : L10n.text("Compón tu primera prueba"), systemImage:"doc.richtext", description:Text(session.compiling ? L10n.text("Puedes volver a escribir mientras el motor trabaja.") : L10n.text("Pulsa Actualizar PDF. El motor local genera el resultado tipográfico a partir del documento.")))
            }
            if details, let result = session.compilation {
                Divider()
                ScrollView {
                    VStack(alignment:.leading,spacing:8) {
                        Text(L10n.text("Motor: ")+result.engine.path).font(.caption)
                        Text(result.log).font(.system(size:10,design:.monospaced))
                    }.textSelection(.enabled).frame(maxWidth:.infinity,alignment:.leading).padding(12)
                }.frame(maxHeight:180)
            }
        }.background(Color(nsColor:.windowBackgroundColor))
    }
}

struct ProofPDFView: NSViewRepresentable {
    let url: URL
    let session: Session
    func makeCoordinator() -> Coordinator { Coordinator(session:session) }
    func makeNSView(context:Context) -> FittingPDFView {
        let view=FittingPDFView()
        view.autoScales=false;view.displayMode = .singlePageContinuous;view.displaysPageBreaks=true
        view.setAccessibilityLabel(L10n.text("PDF compuesto por el motor LaTeX"))
        NotificationCenter.default.addObserver(context.coordinator,selector:#selector(Coordinator.pageChanged(_:)),name:.PDFViewPageChanged,object:view)
        return view
    }
    func updateNSView(_ view:FittingPDFView,context:Context) {
        context.coordinator.updating=true
        defer {context.coordinator.updating=false}
        if view.document?.documentURL != url {view.document=PDFDocument(url:url);view.revealPageAfterLayout=true}
        if let document=view.document,let page=document.page(at:session.proofPage),view.currentPage != page {view.go(to:page)}
        view.fitsPage=session.proofZoom==nil
        if let zoom=session.proofZoom,abs(view.scaleFactor-zoom)>0.001 {view.scaleFactor=zoom}
        view.needsLayout=true
    }
    final class Coordinator:NSObject {
        let session:Session
        var updating=false
        init(session:Session) {self.session=session}
        @objc func pageChanged(_ notification:Notification) {
            guard !updating,let view=notification.object as? PDFView,let document=view.document,let page=view.currentPage else{return}
            session.proofPage=document.index(for:page)
        }
        deinit {NotificationCenter.default.removeObserver(self)}
    }
}

/// PDFKit's continuous auto-scale fills the width. Fit the whole page explicitly.
final class FittingPDFView:PDFView {
    var fitsPage=true
    var revealPageAfterLayout=false
    override func layout() {
        super.layout()
        guard let page=currentPage ?? document?.page(at:0),bounds.width>24,bounds.height>24 else{return}
        if fitsPage {
            let pageSize=page.bounds(for:displayBox).size
            let scale=min((bounds.width-20)/max(1,pageSize.width),(bounds.height-20)/max(1,pageSize.height))
            if abs(scaleFactor-scale)>0.001 {scaleFactor=scale}
        }
        if revealPageAfterLayout {
            revealPageAfterLayout=false
            let rectangle=page.bounds(for:displayBox)
            go(to:PDFDestination(page:page,at:NSPoint(x:rectangle.minX,y:rectangle.maxY)))
        }
    }
}
