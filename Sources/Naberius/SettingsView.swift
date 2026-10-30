import SwiftUI
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
    @AppStorage("defaultTemplateID") private var defaultTemplateID="blank"
    @State private var selected:String?
    @State private var analysis:TemplateAnalysis?
    @State private var edit:DocumentTemplate?
    @State private var notice=""
    var body:some View{
        VStack(alignment:.leading,spacing:14){
            HStack{Text(L10n.text("Catálogo de plantillas")).font(.title3.weight(.semibold));Spacer();Button(L10n.text("Importar plantilla…")){importTemplate()}}
            HSplitView{
                List(session.templates,selection:$selected){t in VStack(alignment:.leading,spacing:4){Text(t.name);Text(t.category+L10n.format(" · v%@",t.version)).font(.caption).foregroundStyle(.secondary)}.tag(t.id)}.frame(minWidth:220)
                if let t=session.templates.first(where:{$0.id==selected}){VStack(alignment:.leading,spacing:14){TemplateMiniature(template:t).frame(width:100,height:140);Text(t.detail).foregroundStyle(.secondary);Text(L10n.format("%@, %@ pt · %@ mm",t.font,Int(t.fontSize),Int(t.marginMM))).font(.caption);HStack{Button(L10n.text("Duplicar")){var copy=t;copy.id=UUID().uuidString;copy.name += L10n.text(" · copia");copy.category="Personales";session.templates.append(copy);session.persistLocal();selected=copy.id};Button(L10n.text("Personalizar…")){edit=t}};Button(defaultTemplateID == t.id ? L10n.text("Plantilla predeterminada") : L10n.text("Usar al crear documentos")){defaultTemplateID=t.id}.disabled(defaultTemplateID == t.id);Button(L10n.text("Documento de prueba")){session.new(template:t,example:true);session.mutate(L10n.text("Plantilla de prueba")){$0.template=t}}
                    if t.category != "Integradas"{Button(L10n.text("Desinstalar"),role:.destructive){session.templates.removeAll{$0.id==t.id};if defaultTemplateID==t.id{defaultTemplateID="blank"};session.persistLocal()}}else{Button(L10n.text("Restaurar")){if let builtin=DocumentTemplate.builtins.first(where:{$0.id==t.id}),let i=session.templates.firstIndex(where:{$0.id==t.id}){session.templates[i]=builtin;session.persistLocal()}}};Spacer()}.padding(15).frame(minWidth:340)}else{Text(L10n.text("Selecciona una plantilla para previsualizarla y administrarla.")).foregroundStyle(.secondary).padding(20).frame(minWidth:340)}
            }
            Text(L10n.text("Cada documento guarda una copia de su plantilla. Actualizar o desinstalar una plantilla no cambia los documentos existentes.")).font(.caption).foregroundStyle(.secondary)
            if !notice.isEmpty{Text(notice).font(.caption).foregroundStyle(.secondary)}
            if let result=analysis{Divider();Text(result.compatible ? (result.partial ? L10n.text("Compatibilidad parcial") : L10n.text("Compatible")) : L10n.text("No compatible")).font(.headline);ForEach(result.messages,id:\.self){Text($0).font(.caption)};if result.compatible{Button(L10n.text("Instalar variante semántica")){session.templates.append(result.template);session.persistLocal();analysis=nil}}}
        }.padding(18).sheet(item:$edit){template in TemplateEditor(template:template){updated in var t=updated;if template.category=="Integradas"{t.id=UUID().uuidString;t.category="Personales";t.name += L10n.text(" · personal");session.templates.append(t)}else if let i=session.templates.firstIndex(where:{$0.id==t.id}){t.version += 1;session.templates[i]=t};session.persistLocal();edit=nil}}
    }
    private func importTemplate(){let p=NSOpenPanel();p.allowedContentTypes=[.plainText,.zip];p.allowsOtherFileTypes=true;guard p.runModal() == .OK,let u=p.url else{return};Task{do{let result=try await Self.analyze(u);analysis=result}catch{notice=error.localizedDescription}}}
    @concurrent private static func analyze(_ url:URL)async throws->TemplateAnalysis{try TemplateImporter.analyze(url)}
}
struct TemplateEditor:View {
    @State var template:DocumentTemplate
    let save:(DocumentTemplate)->Void
    @Environment(\.dismiss)private var dismiss
    var body:some View{VStack{HStack{Text(L10n.text("Personalizar plantilla")).font(.title2);Spacer();Button(L10n.text("Cancelar")){dismiss()};Button(L10n.text("Guardar variante")){save(template)}}.padding();Form{TextField(L10n.text("Nombre"),text:$template.name);Picker(L10n.text("Tipografía"),selection:$template.font){ForEach(DocumentTypography.supportedFonts,id:\.self){Text($0)}};Stepper(L10n.format("Cuerpo: %@ pt",Int(template.fontSize)),value:$template.fontSize,in:8...24);Stepper(L10n.format("Márgenes: %@ mm",Int(template.marginMM)),value:$template.marginMM,in:10...50);Stepper(L10n.format("Interlineado: %@",String(format:"%.1f",template.lineSpacing)),value:$template.lineSpacing,in:1...3,step:0.1);Toggle(L10n.text("Portada"),isOn:$template.cover);Toggle(L10n.text("Numerar títulos"),isOn:$template.numberedHeadings);DocumentLayoutControls(template:$template);Toggle(L10n.text("Bloquear todo el diseño"),isOn:$template.locked);Section(L10n.text("Propiedades protegidas en los documentos")){ForEach(TemplateProperty.allCases,id:\.rawValue){property in Toggle(property.label,isOn:Binding(get:{(template.lockedProperties ?? []).contains(property)},set:{locked in var properties=template.lockedProperties ?? [];properties.removeAll{$0==property};if locked{properties.append(property)};template.lockedProperties=properties}))}}}.formStyle(.grouped)}.frame(width:600,height:680)}
}
