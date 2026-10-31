import SwiftUI
import PDFKit
import NaberiusCore

struct SettingsView:View {
    let session:Session
    @AppStorage("appearance") private var appearance=Appearance.system.rawValue
    @AppStorage("enginePath") private var enginePath=""
    @AppStorage("reopenLast") private var reopenLast=false
    var body:some View{
        TabView{
            Form{Picker(L10n.text("Apariencia"),selection:$appearance){ForEach(Appearance.allCases,id:\.rawValue){Text($0.label).tag($0.rawValue)}};Toggle(L10n.text("Reabrir el último documento al iniciar"),isOn:$reopenLast);Text(L10n.text("Tus documentos y referencias permanecen en este Mac. No hay telemetría ni cuenta de usuario.")).font(.callout).foregroundStyle(.secondary);AboutView()}.formStyle(.grouped).tabItem{Label(L10n.text("General"),systemImage:"gearshape")}
            TemplateSettings(session:session).tabItem{Label(L10n.text("Plantillas"),systemImage:"doc.on.doc")}
            Form{Text(L10n.text("Motor LaTeX")).font(.headline);Text(L10n.text("Tectonic compone el PDF bajo demanda. Por defecto usa solo paquetes ya disponibles en la caché local.")).foregroundStyle(.secondary);TextField(L10n.text("Ruta a Tectonic"),text:$enginePath);Button(L10n.text("Seleccionar motor…")){let p=NSOpenPanel();p.canChooseDirectories=false;if p.runModal() == .OK,let u=p.url{enginePath=u.path}};if let engine=Composer.detectedEngine(custom:enginePath){Label(L10n.text("Disponible: ")+engine.path,systemImage:"checkmark.circle").font(.caption).textSelection(.enabled)}else{Label(L10n.text("Motor no encontrado"),systemImage:"exclamationmark.triangle")};Divider();Text(L10n.text("La primera composición puede necesitar descargar paquetes de TeX. Esta acción requiere conexión y solo se ejecuta al pulsar el botón.")).font(.callout).foregroundStyle(.secondary);Button(L10n.text("Componer y permitir descarga de paquetes")){session.compile(allowNetwork:true)}.disabled(session.document==nil || session.compiling);Text(L10n.text("Los registros técnicos se muestran si ocurre un error. El documento maestro nunca se modifica durante la composición.")).font(.caption).foregroundStyle(.secondary)}.formStyle(.grouped).tabItem{Label(L10n.text("Composición"),systemImage:"doc.richtext")}
        }.padding(14).frame(width:760,height:660)
    }
}
struct TemplateSettings:View {
    let session:Session
    @Environment(\.openWindow) private var openWindow
    @AppStorage("defaultTemplateID") private var defaultTemplateID="blank"
    @State private var selected:String?
    @State private var analysis:TemplateAnalysis?
    @State private var edit:DocumentTemplate?
    @State private var notice=""
    @State private var importing=false
    var body:some View {
        VStack(alignment:.leading,spacing:14) {
            HStack {
                Text(L10n.text("Catálogo de plantillas")).font(.title3.weight(.semibold));Spacer()
                if importing {ProgressView().controlSize(.small)}
                Button(L10n.text("Importar plantilla…")){importTemplate()}.disabled(importing)
            }
            HSplitView {
                List(session.templates,selection:$selected) {template in
                    VStack(alignment:.leading,spacing:4) {
                        Text(template.name)
                        Text(L10n.text(template.category)+L10n.format(" · v%@",template.version)).font(.caption).foregroundStyle(.secondary)
                    }.tag(template.id)
                }.frame(minWidth:200)
                ScrollView {
                    if let template=session.templates.first(where:{$0.id==selected}) {
                        details(template)
                    } else {
                        Text(L10n.text("Selecciona una plantilla para previsualizarla y administrarla.")).foregroundStyle(.secondary).padding(20)
                    }
                }.frame(minWidth:350)
            }
            Text(L10n.text("Cada documento guarda una copia de su plantilla. Actualizar o desinstalar una plantilla no cambia los documentos existentes.")).font(.caption).foregroundStyle(.secondary)
            if !notice.isEmpty {Text(notice).font(.caption).textSelection(.enabled)}
            if let result=analysis,result.template.package==nil {
                Divider()
                Text(result.compatible ? (result.partial ? L10n.text("Compatibilidad parcial") : L10n.text("Compatible")) : L10n.text("No compatible")).font(.headline)
                ForEach(result.messages,id:\.self){Text($0).font(.caption)}
                if result.compatible {Button(L10n.text("Instalar variante semántica")){selected=session.installTemplate(result.template);analysis=nil}}
            }
        }.padding(18).sheet(item:$edit) {template in
            TemplateEditor(template:template) {updated in
                var value=updated
                if template.category=="Integradas" {value.id=UUID().uuidString;value.category="Personales";value.name += L10n.text(" · personal");session.templates.append(value)}
                else if let index=session.templates.firstIndex(where:{$0.id==value.id}) {value.version += 1;session.templates[index]=value}
                session.persistLocal();edit=nil
            }
        }
    }
    private func details(_ template:DocumentTemplate)->some View {
        VStack(alignment:.leading,spacing:14) {
            TemplateMiniature(template:template).frame(width:100,height:140)
            Text(template.detail).foregroundStyle(.secondary)
            if let package=template.package {
                Text(L10n.format("Clase: %@",package.plan.documentClass)).font(.headline)
                Text(L10n.format("Opciones: %@",package.plan.options.joined(separator:", "))).font(.caption)
                if package.plan.candidates.count>1 {
                    Picker(L10n.text("Documento principal"),selection:Binding(get:{package.plan.mainFile},set:{selectMain($0,template:template)})) {
                        ForEach(package.plan.candidates,id:\.self){Text($0).tag($0)}
                    }.disabled(importing)
                } else {Text(L10n.format("Archivo principal: %@",package.plan.mainFile)).font(.caption)}
                Text(L10n.format("%@ archivos conservados · %@ estilos bibliográficos",package.files.count,package.plan.bibliographyStyles.count)).font(.caption)
                Text(L10n.format("Motor detectado: %@ · Bibliografía: %@",package.plan.requiredEngine,package.plan.bibliographyBackend)).font(.caption)
                if package.plan.requiredEngine != "tectonic" || package.plan.bibliographyBackend=="biber" {
                    Label(L10n.text("Este paquete requiere LuaLaTeX o Biber. Puedes conservarlo y exportarlo; la composición integrada todavía no admite esas dependencias."),systemImage:"exclamationmark.triangle").font(.caption)
                }
                Text(L10n.text("El PDF usa las fuentes, márgenes y estilos de la clase editorial. La miniatura es la referencia incluida en el ZIP; comprueba el resultado con PDF LaTeX.")).font(.caption).foregroundStyle(.secondary)
            } else {Text(L10n.format("%@, %@ pt · %@ mm",template.font,Int(template.fontSize),Int(template.marginMM))).font(.caption)}
            HStack {
                Button(L10n.text("Duplicar")){var copy=template;copy.id=UUID().uuidString;copy.name += L10n.text(" · copia");copy.category="Personales";session.templates.append(copy);session.persistLocal();selected=copy.id}
                Button(L10n.text("Personalizar…")){edit=template}
            }
            Button(defaultTemplateID==template.id ? L10n.text("Plantilla predeterminada") : L10n.text("Usar al crear documentos")){defaultTemplateID=template.id}.disabled(defaultTemplateID==template.id)
            Button(L10n.text("Documento de prueba")){session.new(template:template,example:true);openWindow(id:"main")}
            if template.category != "Integradas" {
                Button(L10n.text("Desinstalar"),role:.destructive){session.templates.removeAll{$0.id==template.id};if defaultTemplateID==template.id{defaultTemplateID="blank"};session.persistLocal()}
            } else {
                Button(L10n.text("Restaurar")){if let builtin=DocumentTemplate.builtins.first(where:{$0.id==template.id}),let index=session.templates.firstIndex(where:{$0.id==template.id}){session.templates[index]=builtin;session.persistLocal()}}
            }
        }.padding(15).frame(maxWidth:.infinity,alignment:.leading)
    }
    private func selectMain(_ main:String,template:DocumentTemplate) {
        guard let package=template.package else{return}
        importing=true
        Task {
            defer{importing=false}
            do {
                let updated=try await Self.reanalyze(package,main:main)
                guard let index=session.templates.firstIndex(where:{$0.id==template.id}) else{return}
                session.templates[index].package=updated;session.templates[index].version += 1;session.persistLocal()
                notice=L10n.text("Configuración actualizada para los documentos nuevos.")
            } catch {notice=error.localizedDescription}
        }
    }
    private func importTemplate() {
        let panel=NSOpenPanel();panel.allowedContentTypes=[.plainText,.zip];panel.allowsOtherFileTypes=true
        let completion:(NSApplication.ModalResponse)->Void={response in
            guard response == .OK,let url=panel.url else{return}
            importing=true;notice=""
            Task {
                defer{importing=false}
                do {
                    let result=try await Self.analyze(url);analysis=result
                    if result.compatible,result.template.package != nil {
                        let id=session.installTemplate(result.template);selected=id;defaultTemplateID=id
                        notice=L10n.text("ZIP configurado como plantilla predeterminada. Crea un documento y usa PDF LaTeX para comprobar la composición.")
                    }
                } catch {notice=error.localizedDescription}
            }
        }
        if let window=NSApp.keyWindow {panel.beginSheetModal(for:window,completionHandler:completion)} else {panel.begin(completionHandler:completion)}
    }
    @concurrent private static func analyze(_ url:URL)async throws->TemplateAnalysis {try TemplateImporter.analyze(url)}
    @concurrent private static func reanalyze(_ package:LaTeXTemplatePackage,main:String)async throws->LaTeXTemplatePackage {try LaTeXTemplatePackage.analyze(files:package.files,sourceName:package.sourceName,selectedMain:main)}
}
struct TemplateEditor:View {
    @State var template:DocumentTemplate
    let save:(DocumentTemplate)->Void
    @Environment(\.dismiss)private var dismiss
    var body:some View{VStack{HStack{Text(L10n.text("Personalizar plantilla")).font(.title2);Spacer();Button(L10n.text("Cancelar")){dismiss()};Button(L10n.text("Guardar variante")){save(template)}}.padding();Form{TextField(L10n.text("Nombre"),text:$template.name);if let package=template.package {Text(L10n.format("Clase: %@ · Archivo principal: %@",package.plan.documentClass,package.plan.mainFile)).font(.caption);Text(L10n.text("El diseño procede de la clase editorial del ZIP.")).foregroundStyle(.secondary)} else {Picker(L10n.text("Tipografía"),selection:$template.font){ForEach(DocumentTypography.supportedFonts,id:\.self){Text($0)}};Stepper(L10n.format("Cuerpo: %@ pt",Int(template.fontSize)),value:$template.fontSize,in:8...24);Stepper(L10n.format("Márgenes: %@ mm",Int(template.marginMM)),value:$template.marginMM,in:10...50);Stepper(L10n.format("Interlineado: %@",String(format:"%.1f",template.lineSpacing)),value:$template.lineSpacing,in:1...3,step:0.1);Toggle(L10n.text("Portada"),isOn:$template.cover);Toggle(L10n.text("Numerar títulos"),isOn:$template.numberedHeadings);DocumentLayoutControls(template:$template);Toggle(L10n.text("Bloquear todo el diseño"),isOn:$template.locked);Section(L10n.text("Propiedades protegidas en los documentos")){ForEach(TemplateProperty.allCases,id:\.rawValue){property in Toggle(property.label,isOn:Binding(get:{(template.lockedProperties ?? []).contains(property)},set:{locked in var properties=template.lockedProperties ?? [];properties.removeAll{$0==property};if locked{properties.append(property)};template.lockedProperties=properties}))}}}}.formStyle(.grouped)}.frame(width:600,height:680)}
}
