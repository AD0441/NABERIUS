import SwiftUI
import NaberiusCore

struct EditorialFieldsView:View {
    let session:Session
    let package:LaTeXTemplatePackage
    var body:some View {
        if !package.customFields.isEmpty {
            GroupBox(L10n.text("Campos de la revista")) {
                VStack(alignment:.leading,spacing:10) {
                    Text(L10n.text("Detectados en el paquete. Conservan la estructura editorial al editar sus valores.")).font(.caption).foregroundStyle(.secondary)
                    ForEach(package.customFields) {field in
                        TextField(field.label,text:Binding(get:{session.document?.metadata.templateFields?[field.id] ?? field.plainValue},set:{value in
                            session.mutate(L10n.text("Editar dato editorial")) {document in
                                if document.metadata.templateFields==nil {document.metadata.templateFields=[:]}
                                document.metadata.templateFields?[field.id]=value
                                document.metadata.authors=package.authors(metadata:document.metadata)
                            }
                        }),axis:.vertical).lineLimit(1...3)
                    }
                }.padding(6)
            }
        }
    }
}
