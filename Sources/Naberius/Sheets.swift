import SwiftUI
import PDFKit
import NaberiusCore

struct SheetRouter:View {
    let session:Session;let sheet:Session.Sheet
    @Environment(\.dismiss) private var dismiss
    var body:some View {
        VStack(spacing:0){
            HStack{Text(title).font(.title2.weight(.semibold));Spacer();Button(L10n.text("Listo")){dismiss()}.keyboardShortcut(.escape,modifiers:[])}.padding(22)
            Divider()
            Group{switch sheet {
            case .templates:TemplateCatalog(session:session)
            case .library:if session.bibliographyImport != nil {BibliographyImportView(session:session)} else {LibraryView(session:session)}
            case .citation:CitationSheet(session:session)
            case .insert:TableSheet(session:session)
            case .link:LinkSheet(session:session)
            case .reference:CrossReferenceSheet(session:session)
            case .about:AboutView()
            case .export:ExportView(session:session)
            case .recovery:RecoveryView(session:session)
            case .diagnostic:ScrollView{if let failure=session.failedComposition {VStack(alignment:.leading,spacing:14){Text(failure.summary).font(.callout);Text(L10n.text("Motor: ")+failure.engine.path).font(.caption);Text(failure.log.isEmpty ? L10n.text("El proceso terminó sin generar un registro.") : failure.log).font(.system(size:11,design:.monospaced))}.frame(maxWidth:.infinity,alignment:.leading).padding(22).textSelection(.enabled)}}
            }}.frame(maxWidth:.infinity,maxHeight:.infinity)
        }.frame(width:sheet == .export ? 900 : 700,height:sheet == .export ? 720 : 570).tint(Brand.accent)
    }
    private var title:String {switch sheet{case .templates:L10n.text("Plantillas");case .library:session.bibliographyImport != nil ? L10n.text("Revisar importación") : L10n.text("Biblioteca");case .citation:L10n.text("Insertar cita");case .insert:L10n.text("Insertar tabla");case .link:L10n.text("Insertar enlace");case .reference:L10n.text("Referencia cruzada");case .about:L10n.text("Acerca de Naberius");case .export:L10n.text("Vista previa PDF");case .recovery:L10n.text("Recuperar documentos");case .diagnostic:L10n.text("Detalles de LaTeX")}}
}
struct TemplateCatalog:View {
    let session:Session
    @Environment(\.dismiss) private var dismiss
    var body:some View {
        ScrollView {VStack(alignment:.leading,spacing:0){ForEach(session.templates){t in HStack(spacing:20){TemplateMiniature(template:t).frame(width:72,height:92);VStack(alignment:.leading,spacing:6){Text(t.name).font(.headline);Text(t.detail).font(.callout).foregroundStyle(.secondary);Text(L10n.format("%@ · versión %@",t.category,t.version)).font(.caption).foregroundStyle(.secondary)};Spacer();Button(session.document == nil ? L10n.text("Crear") : L10n.text("Aplicar")){if session.document == nil{session.new(template:t)}else{session.mutate(L10n.text("Cambiar plantilla")){$0.template=t}};dismiss()}}.padding(.vertical,15);Divider()}}.padding(.horizontal,28)}
    }
}
struct TemplateMiniature:View {
    let template:DocumentTemplate
    var body:some View {
        if let data=template.package?.previewPDF,let page=PDFDocument(data:data)?.page(at:0) {
            Image(nsImage:page.thumbnail(of:NSSize(width:220,height:310),for:.mediaBox)).resizable().scaledToFit().help(L10n.text("PDF de referencia incluido en el paquete"))
        } else {
            VStack(alignment:.leading,spacing:5){Rectangle().fill(Brand.accent).frame(width:28,height:4).padding(.top,12);ForEach(0..<6,id:\.self){i in Rectangle().fill(Color.gray.opacity(0.3)).frame(width:i==5 ? 22 : 43,height:2)};Spacer()}.padding(.horizontal,12).frame(maxWidth:.infinity,maxHeight:.infinity).background(Color(nsColor:.textBackgroundColor)).overlay{Rectangle().stroke(Color(nsColor:.separatorColor),lineWidth:0.5)}
        }
    }
}

struct TableSheet:View {
    let session:Session
    @Environment(\.dismiss) private var dismiss
    @State private var rows=3
    @State private var columns=3
    var body:some View{VStack(alignment:.leading,spacing:24){Text(L10n.text("Elige el tamaño inicial. Podrás editar y ampliar la tabla directamente en el documento.")).foregroundStyle(.secondary);HStack(spacing:30){Stepper(L10n.format("Filas: %@",rows),value:$rows,in:1...12);Stepper(L10n.format("Columnas: %@",columns),value:$columns,in:1...8)};Grid(horizontalSpacing:5,verticalSpacing:5){ForEach(1...8,id:\.self){r in GridRow{ForEach(1...8,id:\.self){c in Button{rows=r;columns=c}label:{Rectangle().fill(r<=rows && c<=columns ? Brand.accent.opacity(0.6) : Color.secondary.opacity(0.1)).frame(width:32,height:24)}.buttonStyle(.plain).accessibilityLabel(L10n.format("%@ filas y %@ columnas",r,c))}}}};Spacer();HStack{Spacer();Button(L10n.text("Insertar tabla")){var n=AcademicNode(.table);n.rows=Array(repeating:Array(repeating:"",count:columns),count:rows);n.caption=L10n.text("Título de la tabla");session.insert(n);dismiss()}.buttonStyle(.borderedProminent)}}.padding(28)}
}
struct LinkSheet:View {
    let session:Session
    @Environment(\.dismiss) private var dismiss
    @State private var title=""
    @State private var url="https://"
    var valid:Bool {URL(string:url).map{["http","https","mailto"].contains($0.scheme?.lowercased() ?? "")} ?? false}
    var body:some View{Form{TextField(L10n.text("Texto"),text:$title);TextField(L10n.text("Dirección"),text:$url);Button(L10n.text("Insertar enlace")){guard let editor=session.editor,let link=URL(string:url)else{return};let range=editor.selectedRange();let text=title.isEmpty ? (range.length>0 ? (editor.string as NSString).substring(with:range) : url) : title;let a=NSMutableAttributedString(string:text,attributes:editor.typingAttributes);a.addAttribute(.link,value:link,range:NSRange(location:0,length:a.length));editor.insertText(a,replacementRange:range);dismiss()}.disabled(!valid)}.formStyle(.grouped)}
}
struct CitationSheet:View {
    let session:Session
    @Environment(\.dismiss) private var dismiss
    @State private var selected:Set<UUID>=[]
    @State private var search=""
    @State private var narrative=false
    @State private var pages=""
    var body:some View{VStack(spacing:14){HStack{TextField(L10n.text("Buscar autor, título o año"),text:$search).textFieldStyle(.roundedBorder);Button(L10n.text("Importar…")){session.importReferences()};Button(L10n.text("Biblioteca…")){session.sheet = .library}};List(session.document?.references.filter{search.isEmpty || ($0.title+$0.authors+$0.year).localizedCaseInsensitiveContains(search)} ?? []){r in Toggle(isOn:Binding(get:{selected.contains(r.id)},set:{if $0{selected.insert(r.id)}else{selected.remove(r.id)}})){VStack(alignment:.leading,spacing:4){Text(r.title.isEmpty ? L10n.text("Sin título") : r.title).font(.headline);Text(r.authors+" · "+r.year).font(.caption).foregroundStyle(.secondary)}}};HStack{Toggle(L10n.text("Narrativa"),isOn:$narrative);TextField(L10n.text("Página(s), opcional"),text:$pages).frame(width:180);Spacer();Button(editingID == nil ? L10n.text("Insertar cita") : L10n.text("Actualizar cita")){var n=AcademicNode(.citation);n.referenceIDs=(session.document?.references ?? []).filter{selected.contains($0.id)}.map(\.id);n.narrative=narrative;n.locator=pages;if let id=editingID{session.mutate(L10n.text("Actualizar cita")){d in if let i=d.nodes.firstIndex(where:{$0.id==id}){d.nodes[i].referenceIDs=n.referenceIDs;d.nodes[i].narrative=narrative;d.nodes[i].locator=pages}};session.refreshCitations()}else{session.insert(n)};dismiss()}.buttonStyle(.borderedProminent).disabled(selected.isEmpty)}}.padding(22).onAppear{if let id=editingID,let n=session.document?.nodes.first(where:{$0.id==id}){selected=Set(n.referenceIDs);narrative=n.narrative;pages=n.locator}}}
    private var editingID:UUID?{guard let id=session.selectedNode,session.document?.nodes.first(where:{$0.id==id})?.kind == .citation else{return nil};return id}
}
struct CrossReferenceSheet:View {
    let session:Session
    @Environment(\.dismiss) private var dismiss
    var body:some View{List{ForEach(session.document?.blocks.filter{$0.style.headingLevel != nil} ?? []){b in Button(b.text){insert(b.id)}};ForEach(session.document?.orderedNodes.filter{[.figure,.table].contains($0.kind) || ($0.kind == .equation && $0.numbered)} ?? []){n in Button((session.document?.crossReference(n.id) ?? "")+" · "+n.caption){insert(n.id)}}}.padding(12)}
    private func insert(_ id:UUID){if let nodeID=session.selectedNode,session.document?.nodes.first(where:{$0.id==nodeID})?.kind == .crossReference{session.mutate(L10n.text("Cambiar destino")){d in if let i=d.nodes.firstIndex(where:{$0.id==nodeID}){d.nodes[i].targetID=id}}}else{var n=AcademicNode(.crossReference);n.targetID=id;session.insert(n)};dismiss()}
}
struct AboutView:View {
    var body:some View{VStack(spacing:18){NaberiusMark().stroke(Brand.accent,style:StrokeStyle(lineWidth:2,lineCap:.round,lineJoin:.round)).frame(width:100,height:100);Text("NABERIUS").font(.system(size:26,weight:.semibold)).tracking(2);Text(L10n.text("Escritura visual. Composición precisa.")).font(.title3).foregroundStyle(.secondary);Text(L10n.format("Versión %@ · AGPL-3.0-or-later",Bundle.main.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String ?? "0.4.1")).font(.caption);Text(Brand.author);Link(destination:Brand.donation){Label(L10n.text("Apoyar en Ko-fi"),systemImage:"cup.and.saucer")}.buttonStyle(.bordered);Text(L10n.text("Sin cuenta, anuncios ni envío de tus documentos.\nCitas: citeproc-js y estilos Citation Style Language.")).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)}.padding(35)}
}
struct ExportView:View {
    let session:Session
    var body:some View{VStack(spacing:0){if let url=session.previewURL{PDFPreview(url:url);Divider();HStack{Text(L10n.text("PDF compuesto con LaTeX")).font(.caption).foregroundStyle(.secondary);Spacer();Button(L10n.text("Guardar PDF…")){let p=NSSavePanel();p.allowedContentTypes=[.pdf];p.nameFieldStringValue=(session.document?.metadata.title ?? L10n.text("Documento"))+".pdf";if p.runModal() == .OK,let dest=p.url{do{try Data(contentsOf:url).write(to:dest,options:.atomic)}catch{session.error=error.localizedDescription}}}.buttonStyle(.borderedProminent)}.padding(16)}else{ContentUnavailableView(L10n.text("Todavía no hay un PDF"),systemImage:"doc",description:Text(L10n.text("Compón una vista previa desde la barra del editor.")))}}}
}
struct PDFPreview:NSViewRepresentable {
    let url:URL
    func makeNSView(context:Context)->PDFView{let v=PDFView();v.autoScales=true;v.displayMode = .singlePageContinuous;v.document=PDFDocument(url:url);return v}
    func updateNSView(_ v:PDFView,context:Context){if v.document?.documentURL != url{v.document=PDFDocument(url:url)}}
}
struct RecoveryView:View {
    let session:Session
    @Environment(\.dismiss) private var dismiss
    var body:some View{List(session.recoveryFiles,id:\.path){url in HStack{VStack(alignment:.leading){Text((try? NabArchive.decode(Data(contentsOf:url)).metadata.title) ?? L10n.text("Recuperación dañada"));Text(url.lastPathComponent).font(.caption).foregroundStyle(.secondary)};Spacer();Button(L10n.text("Abrir copia")){session.open(url,recovered:true);dismiss()};Button(L10n.text("Descartar")){do{try FileManager.default.removeItem(at:url);session.recoveryFiles.removeAll{$0==url}}catch{session.error=error.localizedDescription}}}}.padding(16)}
}
