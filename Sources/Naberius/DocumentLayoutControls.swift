import SwiftUI
import NaberiusCore

struct DocumentLayoutControls: View {
    @Binding var template: DocumentTemplate
    private func layout<T>(_ key: WritableKeyPath<DocumentLayout,T>) -> Binding<T> {
        Binding(get:{template.effectiveLayout[keyPath:key]},set:{value in
            var updated=template.effectiveLayout
            updated[keyPath:key]=value
            template.effectiveLayout=updated
        })
    }
    var body: some View {
        Picker(L10n.text("Clase LaTeX"),selection:layout(\.documentClass)) {
            ForEach(DocumentClass.allCases,id:\.rawValue) {kind in Text(kind.label).tag(kind)}
        }
        if template.effectiveLayout.documentClass != .letter {
            Picker(L10n.text("Columnas"),selection:layout(\.columnCount)){Text(L10n.text("Una")).tag(1);Text(L10n.text("Dos")).tag(2)}
            if template.effectiveLayout.columnCount==2 {Stepper(value:layout(\.columnSeparationMM),in:3...20,step:1){Text(L10n.format("Separación: %@ mm",Int(template.effectiveLayout.columnSeparationMM)))}}
        }
        DisclosureGroup(L10n.text("Márgenes por lado")) {
            margin(L10n.text("Superior"),\.marginTopMM);margin(L10n.text("Inferior"),\.marginBottomMM);margin(L10n.text("Izquierdo"),\.marginLeftMM);margin(L10n.text("Derecho"),\.marginRightMM)
        }
        if template.effectiveLayout.documentClass.hasChapters {
            Text(L10n.text("Título 1 crea un capítulo; Título 2–4, sus apartados.")).font(.caption).foregroundStyle(.secondary)
        }
        Stepper(value:layout(\.paragraphIndentMM),in:0...20,step:1) { Text(L10n.format("Sangría: %@ mm",Int(template.effectiveLayout.paragraphIndentMM))) }
        Stepper(value:layout(\.paragraphSpacingPT),in:0...30,step:1) {Text(L10n.format("Espacio entre párrafos: %@ pt",Int(template.effectiveLayout.paragraphSpacingPT)))}
        TextField(L10n.text("Encabezado"),text:layout(\.header))
        TextField(L10n.text("Pie de página"),text:layout(\.footer))
        Toggle(L10n.text("Números de página"),isOn:layout(\.pageNumbers))
        if template.effectiveLayout.documentClass == .letter {
            TextField(L10n.text("Destinatario"),text:layout(\.recipient),axis:.vertical)
            TextField(L10n.text("Saludo"),text:layout(\.opening))
            TextField(L10n.text("Despedida"),text:layout(\.closing))
        }
    }

    private func margin(_ label:String,_ key:WritableKeyPath<DocumentLayout,Double?>)->some View {
        Stepper(value:Binding(get:{template.effectiveLayout[keyPath:key] ?? template.marginMM},set:{layout(key).wrappedValue=$0}),in:10...60,step:1){Text(L10n.format("%@: %@ mm",label,Int(template.effectiveLayout[keyPath:key] ?? template.marginMM)))}
    }

}
