import SwiftUI
import NaberiusCore

struct InspectorView:View {
    @Bindable var session:Session
    private func meta<T>(_ key:WritableKeyPath<Metadata,T>)->Binding<T> { Binding(get:{session.document?.metadata[keyPath:key] ?? Metadata()[keyPath:key]},set:{ value in session.mutate(L10n.text("Propiedades")){$0.metadata[keyPath:key]=value};if key == \Metadata.citationStyle || key == \Metadata.language {session.refreshCitations()} }) }
    private func design<T>(_ key:WritableKeyPath<DocumentTemplate,T>)->Binding<T> { Binding(get:{session.document?.template[keyPath:key] ?? DocumentTemplate.builtins[0][keyPath:key]},set:{ value in session.mutate(L10n.text("Diseño")){$0.template[keyPath:key]=value} }) }
    private func supports(_ alias:TemplateFieldAlias)->Bool {session.document?.template.package.map{$0.plan.fields.contains{$0.alias==alias}} ?? true}
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:20) {
                HStack { Text(session.selectedNode == nil ? L10n.text("Documento") : "Elemento").font(.headline);Spacer();Button {session.inspector=false} label:{Image(systemName:"xmark")}.buttonStyle(.plain).help(L10n.text("Cerrar inspector")) }
                if let id=session.selectedNode,let node=session.document?.nodes.first(where:{$0.id==id}) { NodeInspector(session:session,id:id,node:node) }
                else if session.document != nil {
                    GroupBox(L10n.text("General")) { VStack(alignment:.leading,spacing:10) {
                        TextField(L10n.text("Título"),text:meta(\.title))
                        if supports(.subtitle) {TextField(L10n.text("Subtítulo"),text:meta(\.subtitle))}
                        if supports(.authors) && session.document?.template.package?.hasSeparateAuthors != true {TextField(L10n.text("Autor(es)"),text:meta(\.authors))}
                        if supports(.institution) && session.document?.template.package?.hasSeparateInstitutions != true {TextField(L10n.text("Institución"),text:meta(\.institution))}
                        if supports(.date) {TextField(L10n.text("Fecha"),text:meta(\.date))}
                        if supports(.keywords) {TextField(L10n.text("Palabras clave"),text:meta(\.keywords))}
                        if supports(.abstract) {TextField(L10n.text("Resumen"),text:meta(\.abstract),axis:.vertical).lineLimit(3...6)}
                        Picker(L10n.text("Idioma"),selection:meta(\.language)) { Text(L10n.text("Español")).tag("es-ES");Text(L10n.text("English")).tag("en-US") }
                    }.padding(6) }
                    if let package=session.document?.template.package {EditorialFieldsView(session:session,package:package)}
                    GroupBox(L10n.text("Diseño")) { VStack(alignment:.leading,spacing:10) {
                        Text(session.document?.template.name ?? "").font(.callout.weight(.medium));Button(L10n.text("Cambiar plantilla…")) {session.sheet = .templates}
                        if let package=session.document?.template.package {
                            Text(L10n.format("Clase: %@",package.plan.documentClass)).font(.caption)
                            Text(L10n.text("La clase del ZIP determina la tipografía, el papel, los márgenes y los encabezados del PDF.")).font(.caption).foregroundStyle(.secondary)
                            if package.hasExternalClass {Label(L10n.format("Falta %@.cls en el ZIP.",package.plan.documentClass),systemImage:"exclamationmark.triangle").font(.caption)}
                            Button(L10n.text("Completar recursos…")){session.completeDocumentResources()}
                            DisclosureGroup(L10n.text("Apariencia de escritura")) {
                                Picker(L10n.text("Tipografía"),selection:design(\.font)){ForEach(DocumentTypography.supportedFonts,id:\.self){Text($0)}}
                                Stepper(L10n.format("Cuerpo: %@ pt",Int(session.document?.template.fontSize ?? 10)),value:design(\.fontSize),in:8...24)
                                Text(L10n.text("Estos ajustes cambian el editor. La clase editorial conserva el diseño del PDF.")).font(.caption).foregroundStyle(.secondary)
                            }
                            Button(L10n.text("Usar diseño libre")){session.mutate(L10n.text("Diseño libre")){$0.template=$0.template.freeVariant()}}
                        } else {
                        Picker(L10n.text("Papel"),selection:design(\.paper)){Text(L10n.text("A4")).tag("a4paper");Text(L10n.text("Carta")).tag("letterpaper");Text(L10n.text("Legal")).tag("legalpaper")}.disabled(session.document?.template.allows(.paper) == false)
                        Picker(L10n.text("Tipografía"),selection:design(\.font)){ForEach(DocumentTypography.supportedFonts,id:\.self){Text($0)}}.disabled(session.document?.template.allows(.font) == false)
                        if session.document?.template.font != DocumentTypography.defaultFont {Button(L10n.text("Usar tipografía LaTeX")){session.mutate(L10n.text("Tipografía LaTeX")){$0.template.font=DocumentTypography.defaultFont}}.disabled(session.document?.template.allows(.font) == false)}
                        Stepper(value:design(\.fontSize),in:8...24,step:1){Text(L10n.format("Cuerpo: %@ pt",Int(session.document?.template.fontSize ?? 12)))}.disabled(session.document?.template.allows(.fontSize) == false)
                        Stepper(value:design(\.marginMM),in:10...50,step:1){Text(L10n.format("Márgenes: %@ mm",Int(session.document?.template.marginMM ?? 25)))}.disabled(session.document?.template.allows(.marginMM) == false)
                        Stepper(value:design(\.lineSpacing),in:1...3,step:0.1){Text(L10n.format("Interlineado: %@",String(format:"%.1f",session.document?.template.lineSpacing ?? 1.4)))}.disabled(session.document?.template.allows(.lineSpacing) == false)
                        Toggle(L10n.text("Portada"),isOn:design(\.cover)).disabled(session.document?.template.allows(.cover) == false);Toggle(L10n.text("Numerar títulos"),isOn:design(\.numberedHeadings)).disabled(session.document?.template.allows(.numberedHeadings) == false)
                        DocumentLayoutControls(template:Binding(get:{session.document?.template ?? DocumentTemplate.builtins[0]},set:{value in session.mutate(L10n.text("Composición")){$0.template=value}})).disabled(session.document?.template.allows(.layout) == false)
                        }
                        Button(L10n.text("Restaurar formato de plantilla")) {if let t=session.templates.first(where:{$0.id==session.document?.template.id}){session.mutate(L10n.text("Restaurar plantilla")){$0.template=t}}}
                    }.padding(6) }.disabled(session.document?.template.locked == true)
                    GroupBox(L10n.text("Referencias")) {VStack(alignment:.leading,spacing:10){Picker(L10n.text("Estilo"),selection:meta(\.citationStyle)){ForEach(CitationStyle.allCases,id:\.rawValue){Text($0.label).tag($0)}}.disabled(session.document?.template.package != nil);if let package=session.document?.template.package {Text(L10n.format("El PDF usa el estilo bibliográfico de %@.",package.plan.documentClass)).font(.caption).foregroundStyle(.secondary)};Toggle(L10n.text("Bibliografía al final"),isOn:meta(\.bibliography));Button(L10n.text("Biblioteca del documento…")){session.sheet = .library}}.padding(6)}
                    GroupBox(L10n.text("Corrección local")) {VStack(alignment:.leading,spacing:10){Toggle(L10n.text("Revisión ortográfica"),isOn:meta(\.spelling));Toggle(L10n.text("Autocorrección"),isOn:meta(\.autocorrect));Text(L10n.text("Las sugerencias, Ignorar y Aprender están en el menú contextual del texto.")).font(.caption).foregroundStyle(.secondary)}.padding(6)}
                }
            }.textFieldStyle(.roundedBorder).controlSize(.small).padding(16)
        }.background(Color(nsColor:.controlBackgroundColor))
    }
}
struct NodeInspector:View {
    let session:Session;let id:UUID;let node:AcademicNode
    private func value<T>(_ key:WritableKeyPath<AcademicNode,T>)->Binding<T> {Binding(get:{session.document?.nodes.first(where:{$0.id==id})?[keyPath:key] ?? node[keyPath:key]},set:{value in session.mutate(L10n.text("Editar elemento")){d in if let i=d.nodes.firstIndex(where:{$0.id==id}){d.nodes[i][keyPath:key]=value;d.nodes[i].normalizeTableIdentity()}};if node.kind == .citation{session.refreshCitations()} })}
    private func math<T>(_ key:WritableKeyPath<MathExpression,T>)->Binding<T> {Binding(get:{session.document?.nodes.first(where:{$0.id==id})?.math[keyPath:key] ?? node.math[keyPath:key]},set:{value in session.mutate(L10n.text("Editar ecuación")){d in if let i=d.nodes.firstIndex(where:{$0.id==id}){d.nodes[i].math[keyPath:key]=value}}})}
    var body:some View {
        VStack(alignment:.leading,spacing:14) {
            if node.kind == .figure || node.kind == .table {
                Text(node.kind == .figure ? L10n.format("Figura %@",session.document?.number(of:id) ?? 0) : L10n.format("Tabla %@",session.document?.number(of:id) ?? 0)).font(.subheadline.weight(.semibold))
                TextField(L10n.text("Título / pie"),text:value(\.caption),axis:.vertical).lineLimit(2...4);TextField(L10n.text("Nota"),text:value(\.note),axis:.vertical);TextField(L10n.text("Fuente"),text:value(\.source))
                if node.kind == .figure {
                    TextField(L10n.text("Texto alternativo"),text:value(\.alt),axis:.vertical)
                    Picker(L10n.text("Alineación"),selection:value(\.alignment)){Text(L10n.text("Izquierda")).tag("left");Text(L10n.text("Centro")).tag("center");Text(L10n.text("Derecha")).tag("right")}
                    Slider(value:value(\.width),in:100...570){Text(L10n.text("Ancho"))};Text(L10n.format("Ancho: %@ pt · proporción conservada",Int(node.width))).font(.caption).foregroundStyle(.secondary)
                    Button(L10n.text("Reemplazar imagen…")){replaceFigure()}
                } else { tableControls }
            }
            if node.kind == .equation {
                Text(L10n.text("Ecuación visual")).font(.headline)
                Group {
                    if let image=session.equationImages[node.math] {Image(nsImage:image).renderingMode(.template).resizable().scaledToFit().foregroundStyle(.primary).frame(maxHeight:120).accessibilityLabel(node.math.readable)}
                    else {MathPreview(math:node.math)}
                }.frame(maxWidth:.infinity,minHeight:65).padding(10).background(Color(nsColor:.textBackgroundColor),in:.rect(cornerRadius:8))
                HStack {Button(L10n.text("Componer con LaTeX")) {session.renderEquation(id)}.disabled(session.renderingEquation);if session.renderingEquation {ProgressView().controlSize(.small)}}
                Text(session.equationImages[node.math] == nil ? L10n.text("Vista de estructura. Compón para ver la tipografía matemática del motor.") : L10n.text("Ecuación compuesta por Tectonic.")).font(.caption).foregroundStyle(.secondary)
                Picker(L10n.text("Estructura"),selection:math(\.operation)){ForEach(MathOperation.allCases,id:\.rawValue){Text($0.label).tag($0)}}
                TextField(node.math.operation == .fraction ? "Numerador" : L10n.text("Expresión / base"),text:math(\.first))
                if [.fraction,.power,.subscripted,.integral].contains(node.math.operation){TextField(node.math.operation == .fraction ? "Denominador" : L10n.text("Segundo valor"),text:math(\.second))}
                if [.sum,.integral].contains(node.math.operation){TextField(L10n.text("Límite inferior"),text:math(\.lower));TextField(L10n.text("Límite superior"),text:math(\.upper))}
                LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:6),spacing:7){ForEach(["α","β","γ","δ","θ","λ","μ","π","σ","φ","ω","∞","×","÷","≤","≥","≠","ε"],id:\.self){symbol in Button(symbol){var m=node.math;m.first += symbol;value(\.math).wrappedValue=m}.help(L10n.format("Insertar %@",symbol))}}
                Toggle(L10n.text("En línea"),isOn:value(\.inline));Toggle(L10n.text("Numerar ecuación"),isOn:value(\.numbered)).disabled(node.inline)
            }
            if node.kind == .footnote {Text(L10n.text("Nota al pie")).font(.headline);TextField(L10n.text("Texto de la nota"),text:value(\.note),axis:.vertical).lineLimit(4...12)}
            if node.kind == .citation {Text(L10n.text("Cita bibliográfica")).font(.headline);Toggle(L10n.text("Narrativa"),isOn:value(\.narrative));TextField(L10n.text("Página(s)"),text:value(\.locator));TextField(L10n.text("Prefijo"),text:value(\.prefix));TextField(L10n.text("Sufijo"),text:value(\.suffix));Text(session.citations.citations[id] ?? "").font(.callout);Button(L10n.text("Cambiar referencias…")){session.sheet = .citation}}
            if node.kind == .crossReference {Text(L10n.text("Referencia cruzada")).font(.headline);Text(session.document?.crossReference(node.targetID) ?? "");Button(L10n.text("Cambiar destino…")){session.sheet = .reference}}
            if node.kind == .separator {Text(L10n.text("Separador estructural")).font(.headline);Text(L10n.text("Separa partes del documento con una línea tipográfica.")).font(.callout).foregroundStyle(.secondary)}
            if node.kind == .contents {Text(L10n.text("Índice automático")).font(.headline);Text(L10n.text("Se actualiza a partir de los títulos. El PDF incluye las páginas definitivas.")).font(.callout).foregroundStyle(.secondary)}
            if node.kind == .figureList || node.kind == .tableList {
                Text(node.kind == .figureList ? L10n.text("Lista de figuras") : L10n.text("Lista de tablas")).font(.headline)
                Text(L10n.text("Se actualiza con los títulos y el orden de los elementos. El PDF incluye las páginas definitivas.")).font(.callout).foregroundStyle(.secondary)
            }
            Divider();Text(L10n.text("Identificador estable")).font(.caption).foregroundStyle(.secondary);Text(id.uuidString).font(.system(size:9,design:.monospaced)).textSelection(.enabled)
            Button(L10n.text("Seleccionar objeto en el texto")){guard let editor=session.editor else{return};editor.attributedString().enumerateAttribute(NSAttributedString.Key("nab.node"),in:NSRange(location:0,length:editor.string.utf16.count)){v,r,stop in if v as? String == id.uuidString{editor.setSelectedRange(r);editor.scrollRangeToVisible(r);stop.pointee=true}}}
        }
    }
    private var tableControls:some View {
        VStack(alignment:.leading,spacing:10){
            Button(L10n.text("Editar celdas en el documento")){session.editor?.editTable(id)}
            Toggle(L10n.text("Fila de encabezado"),isOn:value(\.header));Picker(L10n.text("Estilo"),selection:value(\.tableStyle)){ForEach(["Académico","Simple","Cuadrícula"],id:\.self){Text($0)}}
            ScrollView(.horizontal){Grid(horizontalSpacing:3,verticalSpacing:3){ForEach(node.rowIDs,id:\.self){rid in GridRow{ForEach(node.columnIDs,id:\.self){cid in TextField(L10n.text("Celda"),text:cell(rid,cid)).frame(width:90).accessibilityLabel(L10n.text("Celda de tabla"))}}}}}
            HStack{Button(L10n.text("+ Fila")){var rows=node.rows;if rows.count<200{rows.append(Array(repeating:"",count:rows.first?.count ?? 2));value(\.rows).wrappedValue=rows}};Button(L10n.text("− Fila")){var rows=node.rows;if rows.count>1{rows.removeLast();value(\.rows).wrappedValue=rows}}}
            HStack{Button(L10n.text("+ Columna")){if (node.rows.first?.count ?? 0)<12{value(\.rows).wrappedValue=node.rows.map{$0+[""]}}};Button(L10n.text("− Columna")){if (node.rows.first?.count ?? 0)>1{value(\.rows).wrappedValue=node.rows.map{Array($0.dropLast())}}}}
        }
    }
    private func cell(_ rowID:UUID,_ columnID:UUID)->Binding<String> {
        Binding(get:{guard let n=session.document?.nodes.first(where:{$0.id==id}),let r=n.rowIDs.firstIndex(of:rowID),let c=n.columnIDs.firstIndex(of:columnID),r<n.rows.count,c<n.rows[r].count else{return ""};return n.rows[r][c]},set:{text in session.mutate(L10n.text("Editar tabla")){d in guard let i=d.nodes.firstIndex(where:{$0.id==id}),let r=d.nodes[i].rowIDs.firstIndex(of:rowID),let c=d.nodes[i].columnIDs.firstIndex(of:columnID),r<d.nodes[i].rows.count,c<d.nodes[i].rows[r].count else{return};d.nodes[i].rows[r][c]=text}})
    }
    private func replaceFigure(){let p=NSOpenPanel();p.allowedContentTypes=[.png,.jpeg,.pdf];guard p.runModal() == .OK,let u=p.url else{return};do{let data=try Data(contentsOf:u);guard data.count<=32*1024*1024,NSImage(data:data) != nil else{throw NabError.invalid(L10n.text("Imagen no válida o demasiado grande."))};let a=Asset(name:u.lastPathComponent,mediaType:u.pathExtension=="pdf" ? "application/pdf" : (u.pathExtension=="png" ? "image/png" : "image/jpeg"),data:data);session.mutate(L10n.text("Reemplazar imagen")){d in d.assets.append(a);if let i=d.nodes.firstIndex(where:{$0.id==id}){d.nodes[i].assetID=a.id}}}catch{session.error=error.localizedDescription}}
}
struct MathPreview:View {
    let math:MathExpression
    var body:some View {
        Group {
            switch math.operation {
            case .fraction:VStack(spacing:4){Text(math.first);Rectangle().frame(height:1);Text(math.second)}.fixedSize()
            case .root:HStack(spacing:2){Text(L10n.text("√")).font(.system(size:34));Text(math.first).overline()}
            case .power:HStack(alignment:.top,spacing:2){Text(math.first);Text(math.second).font(.caption).offset(y:-4)}
            case .subscripted:HStack(alignment:.bottom,spacing:2){Text(math.first);Text(math.second).font(.caption).offset(y:4)}
            case .sum,.integral:HStack{VStack(spacing:1){Text(math.upper).font(.caption);Text(math.operation == .sum ? "∑" : "∫").font(.system(size:32));Text(math.lower).font(.caption)};Text(math.first)}
            case .text:Text(math.first)
            }
        }.font(.system(size:21,design:.serif)).accessibilityLabel(math.readable)
    }
}
private extension View {func overline()->some View {self.overlay(alignment:.top){Rectangle().frame(height:1).offset(y:-2)}}}
