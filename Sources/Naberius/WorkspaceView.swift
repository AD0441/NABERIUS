import SwiftUI
import NaberiusCore

struct RootView:View {
    @Bindable var session:Session
    @State private var sidebar:NavigationSplitViewVisibility = .all
    var body:some View {
        NavigationSplitView(columnVisibility:$sidebar) { sidebarView.navigationSplitViewColumnWidth(min:195,ideal:225,max:290) } detail: {
            Group { if session.document == nil { HomeView(session:session) } else { EditorWorkspace(session:session) } }
                .background(Color(nsColor:.windowBackgroundColor))
        }.navigationTitle(session.document?.metadata.title ?? "Naberius")
        .toolbar { if session.document != nil && !session.showProof { ToolbarItemGroup(placement:.primaryAction) { EditorToolbar(session:session) } } }
        .sheet(item:$session.sheet,onDismiss:{session.bibliographyImport=nil}) { sheet in SheetRouter(session:session,sheet:sheet) }
        .alert(L10n.text("No se pudo completar la operación"),isPresented:Binding(get:{session.error != nil},set:{if !$0 { session.error=nil }})) { Button(L10n.text("Aceptar"),role:.cancel) { session.error=nil };if let failure=session.failedComposition,session.error == failure.localizedDescription {Button(L10n.text("Detalles de LaTeX")){session.error=nil;session.sheet = .diagnostic}}; if session.document != nil { Button(L10n.text("Guardar copia…")) { session.error=nil;session.save(copy:true) } } } message: { ScrollView { Text(session.error ?? "").textSelection(.enabled) } }
        .onChange(of:session.focusMode) { _,focus in sidebar=focus ? .detailOnly : .all }
    }
    private func navigationLabel(_ title:String,symbol:String)->some View {
        Label {Text(LocalizedStringKey(title))} icon:{Image(systemName:symbol).foregroundStyle(Brand.accent)}
            .frame(maxWidth:.infinity,alignment:.leading).padding(.vertical,3).contentShape(Rectangle())
    }
    private var sidebarView:some View {
        VStack(spacing:0) {
            List {
                Section {
                    Button { session.goHome() } label: { navigationLabel(L10n.text("Inicio"),symbol:"house") }
                    Button { session.sheet = .templates } label: { navigationLabel(L10n.text("Plantillas"),symbol:"doc.on.doc") }
                    Button { session.sheet = .library } label: { navigationLabel(L10n.text("Biblioteca"),symbol:"books.vertical") }
                }.buttonStyle(.plain)
                if let d=session.document {
                    Section(L10n.text("Esquema")) {
                        let headings=d.blocks.filter{$0.style.headingLevel != nil}
                        if headings.isEmpty { Text(L10n.text("Aplica un estilo de título para organizar tu documento.")).font(.caption).foregroundStyle(.secondary).padding(.vertical,8) }
                        ForEach(headings) { b in Button {
                            session.reveal(blockID:b.id)
                        } label: { Text(b.text.isEmpty ? L10n.text("Título sin texto") : b.text).font(.system(size:12,weight:b.style == .heading1 ? .medium : .regular)).lineLimit(2).padding(.leading,CGFloat(max(0,(b.style.headingLevel ?? 1)-1))*12).frame(maxWidth:.infinity,alignment:.leading) }.buttonStyle(.plain).padding(.vertical,3) }
                    }
                }
            }.listStyle(.sidebar)
            Divider(); BrandFooter()
        }
    }
}
struct HomeView:View {
    @Bindable var session:Session
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:30) {
                HStack(alignment:.center,spacing:22) {
                    NaberiusMark().stroke(Brand.accent,style:StrokeStyle(lineWidth:2,lineCap:.round,lineJoin:.round)).frame(width:82,height:82).accessibilityHidden(true)
                    VStack(alignment:.leading,spacing:7) { Text(L10n.text("Dale forma a tus ideas.")).font(.system(size:32,weight:.semibold)); Text(L10n.text("Escribe con libertad. Publica con precisión.")).font(.title3).foregroundStyle(.secondary) }
                }.padding(.top,32)
                HStack(spacing:14) {
                    Button { session.new() } label: { Label(L10n.text("Nuevo documento"),systemImage:"square.and.pencil").padding(.horizontal,8).padding(.vertical,5) }.buttonStyle(.borderedProminent).keyboardShortcut("n")
                    Button { session.openPanel() } label: { Label(L10n.text("Abrir documento"),systemImage:"folder").padding(.horizontal,8).padding(.vertical,5) }.buttonStyle(.bordered)
                    Button(L10n.text("Explorar un ejemplo")) { session.new(example:true) }.buttonStyle(.link)
                }
                if !session.recoveryFiles.isEmpty {
                    HStack { Label(L10n.text("Hay documentos de recuperación disponibles."),systemImage:"arrow.clockwise.circle");Spacer();Button(L10n.text("Revisar")) { session.sheet = .recovery } }.font(.callout).padding(14).background(Color(nsColor:.controlBackgroundColor),in:.rect(cornerRadius:10))
                }
                VStack(alignment:.leading,spacing:14) {
                    HStack { Text(L10n.text("Documentos recientes")).font(.title3.weight(.semibold));Spacer();Text(L10n.text(".nab · local y portable")).font(.caption).foregroundStyle(.secondary) }
                    Divider()
                    if session.recent.isEmpty {
                        VStack(alignment:.leading,spacing:9) { Text(L10n.text("Tu próximo documento empieza aquí.")).font(.headline);Text(L10n.text("Crea uno en blanco o elige una plantilla. Tus imágenes, citas y estilos se guardarán en un único archivo.")).foregroundStyle(.secondary).fixedSize(horizontal:false,vertical:true) }.padding(.vertical,30)
                    } else { ForEach(session.recent) { r in RecentRow(session:session,recent:r) } }
                }.padding(.top,12)
                Spacer(minLength:45)
                HStack(spacing:7) { Image(systemName:"lock.shield");Text(L10n.text("Sin cuenta. Sin nube obligatoria. Tu escritura se queda en tu Mac.")) }.font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth:820,alignment:.leading).padding(46).frame(maxWidth:.infinity)
        }
    }
}
struct RecentRow:View {
    let session:Session;let recent:Recent
    var exists:Bool { FileManager.default.fileExists(atPath:recent.path) }
    var body:some View {
        HStack(spacing:15) {
            Image(systemName:exists ? "doc.text" : "doc.badge.ellipsis").font(.system(size:24)).foregroundStyle(exists ? Brand.accent : .secondary)
            VStack(alignment:.leading,spacing:4) { Text(recent.title).font(.headline);Text(exists ? recent.path : L10n.text("Archivo no encontrado")).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle) }
            Spacer();Text(recent.opened,style:.date).font(.caption).foregroundStyle(.secondary)
            if exists { Button(L10n.text("Abrir")) { session.open(URL(fileURLWithPath:recent.path)) } }
            else { Button(L10n.text("Localizar…")) { session.openPanel() };Button(L10n.text("Quitar")) { session.recent.removeAll{$0.id==recent.id};session.persistLocal() } }
        }.padding(.vertical,9)
    }
}
struct EditorToolbar:View {
    @Bindable var session:Session
    var body:some View {
        Picker(L10n.text("Estilo"),selection:Binding(get:{session.selectedStyle},set:{session.editor?.applyStyle($0)})) { ForEach(BlockStyle.allCases,id:\.rawValue) { Text($0.label).tag($0) } }.frame(width:145).help(L10n.text("Estilo semántico del párrafo"))
        Button { session.editor?.toggleBold() } label:{ Image(systemName:"bold") }.help(L10n.text("Negrita · ⌘B"))
        Button { session.editor?.toggleItalic() } label:{ Image(systemName:"italic") }.help(L10n.text("Cursiva · ⌘I"))
        Menu { Button(L10n.text("Viñetas")) { session.editor?.applyStyle(.bullet) };Button(L10n.text("Numerada")) { session.editor?.applyStyle(.numbered) } } label:{ Image(systemName:"list.bullet") }.help(L10n.text("Listas"))
        Menu { InsertMenu(session:session) } label:{ Label(L10n.text("Insertar"),systemImage:"plus") }
        Button { session.sheet = .citation } label:{ Label(L10n.text("Citar"),systemImage:"quote.opening") }.help(L10n.text("Insertar cita bibliográfica"))
        Button { session.openProof() } label:{ Label(L10n.text("PDF LaTeX"),systemImage:"doc.richtext") }.help(L10n.text("Ver el PDF compuesto con el motor LaTeX"))
        Button { session.inspector.toggle() } label:{ Image(systemName:"sidebar.right") }.help(L10n.text("Propiedades del documento y del elemento"))
    }
}
struct EditorWorkspace:View {
    @Bindable var session:Session
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("editorColumnWidth") private var editorColumnWidth=false
    var body:some View {
        VStack(spacing:0) {
            if session.showFind { FindBar(session:session) }
            if !session.focusMode {
                HStack {
                    Picker(L10n.text("Modo"),selection:Binding(get:{session.editorMode},set:{session.setEditorMode($0)})){ForEach(EditorMode.allCases){Text($0.label).tag($0)}}.pickerStyle(.segmented).frame(width:290)
                    if !session.showProof {Menu {
                        Button(session.pageMode ? L10n.text("Usar lienzo continuo") : L10n.text("Usar página orientativa")){session.pageMode.toggle()}
                        Toggle(L10n.text("Editar al ancho de una columna"),isOn:$editorColumnWidth)
                    } label:{Image(systemName:"textformat.size")}.fixedSize().help(L10n.text("Apariencia de escritura"))}
                    Text(session.document?.template.name ?? "").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    Spacer()
                    if session.compiling { ProgressView().controlSize(.small);Text(L10n.text("Componiendo PDF…")).font(.caption);Button(L10n.text("Cancelar")) { session.cancelCompile() } }
                    Button { session.focusMode.toggle() } label:{ Label(L10n.text("Concentración"),systemImage:"arrow.up.left.and.arrow.down.right") }.buttonStyle(.plain).font(.caption).help(L10n.text("⇧⌘F"))
                }.padding(.horizontal,20).padding(.vertical,11)
                Divider()
            } else { HStack { Spacer();Button(L10n.text("Salir de concentración")) { session.focusMode=false }.keyboardShortcut(.escape,modifiers:[]) }.padding(8) }
            HStack(spacing:0) {
                ZStack { Color(nsColor:.underPageBackgroundColor)
                    ComparisonWorkspace(session:session,mode:session.editorMode,columnWidth:editorColumnWidth)
                        .opacity(session.showProof ? 0 : 1).allowsHitTesting(!session.showProof).accessibilityHidden(session.showProof)
                    if session.showProof {TypesetProofView(session:session)}
                }
                if session.inspector && !session.focusMode { Divider(); InspectorView(session:session).frame(width:270) }
            }
            Divider()
            HStack {
                Image(systemName:session.status.contains("Guardado") ? "checkmark.circle" : "internaldrive").foregroundStyle(.secondary)
                Text(session.status);Spacer();Text(L10n.format("%@ palabras",session.document?.wordCount ?? 0)).monospacedDigit();if !session.showProof {Menu {ForEach([0.75,1,1.25,1.5],id:\.self){z in Button("\(Int(z*100))%"){session.zoom=z}}} label:{Text("\(Int(session.zoom*100))%").foregroundStyle(.primary)}.menuStyle(.borderlessButton).fixedSize().frame(width:58).help(L10n.text("Zoom del editor"))};Divider().frame(height:12)
                if session.pageMode && !session.showProof {
                    Button {session.editor?.movePage(-1)} label:{Image(systemName:"chevron.up")}.buttonStyle(.plain).help(L10n.text("Página anterior del editor"))
                    Button {session.editor?.movePage(1)} label:{Image(systemName:"chevron.down")}.buttonStyle(.plain).help(L10n.text("Página siguiente del editor"))
                }
                Text(session.showProof ? L10n.text("PDF LaTeX") : (session.pageMode ? L10n.text("Paginación orientativa") : L10n.text("Lienzo continuo")))
            }.font(.system(size:11)).foregroundStyle(.secondary).padding(.horizontal,20).padding(.vertical,8)
        }
        .onAppear {session.setPreviewActive(scenePhase == .active)}
        .onDisappear {session.setPreviewActive(false)}
        .onChange(of:scenePhase) {_,phase in session.setPreviewActive(phase == .active)}
        .onChange(of:session.editorMode) {_,mode in
            if mode == .pdf {session.editor?.window?.makeFirstResponder(nil)}
            else if let editor=session.editor {editor.window?.makeFirstResponder(editor)}
        }
    }
}
struct FindBar:View {
    @Bindable var session:Session
    var body:some View {
        VStack(spacing:8) {
            HStack { TextField(L10n.text("Buscar en el documento"),text:$session.findQuery).onSubmit{find(1)};TextField(L10n.text("Reemplazar por"),text:$session.replaceQuery);Button { find(-1) } label:{Image(systemName:"chevron.up")};Button {find(1)} label:{Image(systemName:"chevron.down")};Button(L10n.text("Reemplazar")) { replace(all:false) };Button(L10n.text("Todos")) { replace(all:true) };Button {session.showFind=false} label:{Image(systemName:"xmark")} }
            HStack { Toggle(L10n.text("Distinguir mayúsculas"),isOn:$session.caseSensitive);Toggle(L10n.text("Palabra completa"),isOn:$session.wholeWord);Spacer();Text(L10n.format("%@ coincidencias",session.matchCount)).foregroundStyle(.secondary) }.font(.caption)
        }.textFieldStyle(.roundedBorder).padding(12).onChange(of:session.findQuery){_,_ in find(0)}.onChange(of:session.caseSensitive){_,_ in find(0)}.onChange(of:session.wholeWord){_,_ in find(0)}
    }
    private func find(_ direction:Int) {
        guard let editor=session.editor,let d=session.document else{return}
        let ranges=DocumentSearch.ranges(session.findQuery,in:editor.string,caseSensitive:session.caseSensitive,wholeWord:session.wholeWord)
        let nodeMatches=d.orderedNodes.filter { n in [n.caption,n.note,n.source,n.alt]+n.rows.flatMap{$0} != [] && ([n.caption,n.note,n.source,n.alt]+n.rows.flatMap{$0}).contains{!DocumentSearch.ranges(session.findQuery,in:$0,caseSensitive:session.caseSensitive,wholeWord:session.wholeWord).isEmpty} }
        session.matchCount=ranges.count+nodeMatches.count
        guard session.matchCount > 0 else {return};session.matchPosition=(session.matchPosition+direction+session.matchCount)%session.matchCount
        if session.matchPosition < ranges.count { editor.setSelectedRange(ranges[session.matchPosition]);editor.scrollRangeToVisible(editor.selectedRange()) }
        else { session.selectedNode=nodeMatches[session.matchPosition-ranges.count].id;session.inspector=true }
    }
    private func replace(all:Bool) {
        guard let editor=session.editor,let d=session.document,!session.findQuery.isEmpty else{return}
        let text=NSMutableAttributedString(attributedString:editor.attributedString())
        let ranges=DocumentSearch.ranges(session.findQuery,in:text.string,caseSensitive:session.caseSensitive,wholeWord:session.wholeWord)
        let selected=ranges.contains(editor.selectedRange()) ? editor.selectedRange() : ranges.first
        if all { for r in ranges.reversed(){text.replaceCharacters(in:r,with:session.replaceQuery)} }
        else if let selected,session.matchPosition<ranges.count {text.replaceCharacters(in:selected,with:session.replaceQuery)}
        let query=session.findQuery, replacement=session.replaceQuery, sensitive=session.caseSensitive, word=session.wholeWord
        session.mutate(L10n.text("Reemplazar")) { document in
            document.blocks=RichText.blocks(text)
            for i in document.nodes.indices {
                if !all && document.nodes[i].id != session.selectedNode {continue}
                func replaceText(_ value:String)->String{DocumentSearch.replacing(value,query:query,replacement:replacement,caseSensitive:sensitive,wholeWord:word)}
                if all || selected == nil {document.nodes[i].caption=replaceText(document.nodes[i].caption);document.nodes[i].note=replaceText(document.nodes[i].note);document.nodes[i].source=replaceText(document.nodes[i].source);document.nodes[i].alt=replaceText(document.nodes[i].alt);document.nodes[i].rows=document.nodes[i].rows.map{$0.map(replaceText)}}
            }
        };_ = d;find(0)
    }
}
