import SwiftUI
import NaberiusCore

struct BibliographyImportView:View {
    @Bindable var session:Session
    @State private var selected:Set<UUID>=[]
    @State private var detail:UUID?
    var body:some View {
        if let report=session.bibliographyImport {
            VStack(alignment:.leading,spacing:12) {
                Text(report.sourceName).font(.headline)
                Text(L10n.format("%@ · %@ · %@",report.references.count==1 ? L10n.text("1 registro") : L10n.format("%@ registros",report.references.count),report.issues.count==1 ? L10n.text("1 advertencia") : L10n.format("%@ advertencias",report.issues.count),report.format)).font(.caption).foregroundStyle(.secondary)
                HSplitView {
                    List(report.references) {reference in
                        HStack {
                            Toggle(isOn:Binding(get:{selected.contains(reference.id)},set:{if $0 {selected.insert(reference.id)} else {selected.remove(reference.id)};detail=reference.id})) {Text(reference.title.isEmpty ? L10n.text("Sin título") : reference.title).lineLimit(2)}
                            Button {detail=reference.id} label:{Image(systemName:"info.circle")}.buttonStyle(.plain).help(L10n.text("Revisar datos y advertencias"))
                        }
                    }.frame(minWidth:260)
                    ScrollView {
                        VStack(alignment:.leading,spacing:10) {
                            let entry=report.references.first(where:{$0.id==detail}) ?? report.references.first
                            if let entry {
                                Text(entry.title.isEmpty ? L10n.text("Sin título") : entry.title).font(.headline)
                                Text(entry.authors+" · "+entry.year).font(.caption)
                                if let imported=entry.imported {
                                    ForEach(imported.warnings,id:\.self) {Text($0).font(.caption).foregroundStyle(.secondary)}
                                    DisclosureGroup(L10n.text("Datos originales conservados")) {
                                        ForEach(imported.fields.keys.sorted(),id:\.self) {key in VStack(alignment:.leading,spacing:3) {Text(key).font(.caption.weight(.semibold));Text(imported.fields[key] ?? "").font(.caption).textSelection(.enabled)}}
                                        if imported.fields.isEmpty {Text(imported.original).font(.system(size:10,design:.monospaced)).textSelection(.enabled)}
                                    }
                                }
                            }
                            ForEach(report.issues.filter{$0.key=="Archivo"}) {issue in Text(issue.message).font(.caption).foregroundStyle(.secondary)}
                        }.frame(maxWidth:.infinity,alignment:.leading).padding(10)
                    }.frame(minWidth:250)
                }
                Text(L10n.text("Solo se añadirán los registros seleccionados. Los campos originales se conservan; preámbulos y comandos externos no se ejecutan.")).font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button(L10n.text("Cancelar")) {session.bibliographyImport=nil;session.sheet = .library}
                    Spacer()
                    Button(selected.count==1 ? L10n.text("Importar 1 registro") : L10n.format("Importar %@ registros",selected.count)) {session.acceptBibliography(selected)}.buttonStyle(.borderedProminent).disabled(selected.isEmpty)
                }
            }.padding(20).onAppear {selected=Set(report.references.map(\.id));detail=report.references.first?.id}
        }
    }
}
