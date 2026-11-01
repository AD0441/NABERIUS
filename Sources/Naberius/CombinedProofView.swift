import SwiftUI
import NaberiusCore

struct CombinedProofView:View {
    @Bindable var session:Session
    var body:some View {
        VStack(spacing:0) {
            HStack {
                Text(L10n.text("PDF LaTeX")).font(.headline)
                Spacer()
                Toggle(L10n.text("Automático"),isOn:Binding(get:{session.automaticPreview},set:{session.setAutomaticPreview($0)})).toggleStyle(.switch).controlSize(.mini).fixedSize()
                Button {session.compile(presentProof:false)} label:{Image(systemName:"arrow.clockwise")}.help(L10n.text("Actualizar PDF · ⇧⌘R")).disabled(session.compiling)
                Button {session.setEditorMode(.pdf)} label:{Image(systemName:"arrow.up.left.and.arrow.down.right")}.help(L10n.text("Ampliar PDF"))
            }.padding(12)
            HStack(spacing:6) {
                if session.compiling {ProgressView().controlSize(.mini);Text(L10n.text("Componiendo…"))}
                else if session.previewIssue != nil {Image(systemName:"exclamationmark.triangle");Text(L10n.text("No se pudo actualizar"))}
                else if session.proofNeedsUpdate {Text(session.automaticPreview ? L10n.text("Se actualizará tras una pausa.") : L10n.text("Hay cambios sin componer."))}
                else {Text(L10n.text("PDF actualizado"))}
                Spacer()
                if session.previewIssue != nil {Button(L10n.text("Detalles")){session.sheet = .diagnostic}}
            }.font(.caption).foregroundStyle(.secondary).padding(.horizontal,12).padding(.bottom,10)
            Divider()
            if let url=session.previewURL {ProofPDFView(url:url,session:session)}
            else {
                VStack(spacing:12) {
                    Image(systemName:"doc.richtext").font(.largeTitle).foregroundStyle(.secondary)
                    Text(L10n.text("Escribe y comprueba el resultado real.")).font(.headline).multilineTextAlignment(.center)
                    Text(session.previewIssue ?? (session.automaticPreview ? L10n.text("LaTeX actualizará esta vista después de una pausa. Las páginas y columnas finales se ven aquí.") : L10n.text("Pulsa Componer ahora para generar el PDF. Activa Automático para actualizarlo tras una pausa."))).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button(L10n.text("Componer ahora")){session.compile(presentProof:false)}.disabled(session.compiling)
                }.padding(24).frame(maxWidth:.infinity,maxHeight:.infinity)
            }
            if session.previewURL != nil {
                Divider()
                HStack {
                    Button {session.proofPage=max(0,session.proofPage-1)} label:{Image(systemName:"chevron.left")}.disabled(session.proofPage==0)
                    Text(L10n.format("%@ / %@",session.proofPage+1,session.proofPageCount)).font(.caption).monospacedDigit()
                    Button {session.proofPage=min(session.proofPageCount-1,session.proofPage+1)} label:{Image(systemName:"chevron.right")}.disabled(session.proofPage+1>=session.proofPageCount)
                    Spacer()
                    Button(L10n.text("Guardar PDF…")){session.sheet = .export}
                }.controlSize(.small).padding(10)
            }
        }.background(Color(nsColor:.windowBackgroundColor))
    }
}
