import Foundation

public enum BlockStyle: String, Codable, CaseIterable, Sendable {
    case paragraph, title, subtitle, heading1, heading2, heading3, heading4, quote, bullet, numbered, caption, pageBreak, appendix
    public var label:String {switch self {
    case .paragraph:L10n.text("Párrafo");case .title:L10n.text("Título del documento");case .subtitle:L10n.text("Subtítulo")
    case .heading1:L10n.text("Título 1");case .heading2:L10n.text("Título 2");case .heading3:L10n.text("Título 3");case .heading4:L10n.text("Título 4")
    case .quote:L10n.text("Cita extensa");case .bullet:L10n.text("Lista con viñetas");case .numbered:L10n.text("Lista numerada");case .caption:L10n.text("Pie / nota");case .pageBreak:L10n.text("Salto de página");case .appendix:L10n.text("Anexo")
    }}
    public var headingLevel: Int? { switch self { case .heading1,.appendix: 1; case .heading2: 2; case .heading3: 3; case .heading4: 4; default: nil } }
}
public struct TextRun: Codable, Equatable, Sendable {
    public var text: String
    public var bold = false
    public var italic = false
    public var script = 0
    public var link: String?
    public var nodeID: UUID?
    public init(_ text: String, bold: Bool = false, italic: Bool = false, nodeID: UUID? = nil) { self.text = text; self.bold = bold; self.italic = italic; self.nodeID = nodeID }
}
public struct Block: Codable, Equatable, Identifiable, Sendable {
    public var id = UUID()
    public var style: BlockStyle = .paragraph
    public var runs: [TextRun] = []
    public init(_ text: String = "", style: BlockStyle = .paragraph) { self.style = style; runs = [TextRun(text)] }
    public var text: String { runs.map(\.text).joined() }
    public var semanticRuns: [TextRun] {
        var merged: [TextRun] = []
        for run in runs {
            if let previous=merged.last,previous.nodeID == nil,run.nodeID == nil,previous.bold == run.bold,previous.italic == run.italic,previous.script == run.script,previous.link == run.link {
                merged[merged.count-1].text += run.text
            } else {merged.append(run)}
        }
        return merged
    }
}
public enum NodeKind: String, Codable, Sendable { case figure, table, equation, citation, crossReference, footnote, contents, separator }
public enum MathOperation: String, Codable, CaseIterable, Sendable {
    case text, fraction, root, power, subscripted, sum, integral
    public var label:String {switch self {case .text:L10n.text("Símbolos / texto");case .fraction:L10n.text("Fracción");case .root:L10n.text("Raíz");case .power:L10n.text("Exponente");case .subscripted:L10n.text("Subíndice");case .sum:L10n.text("Sumatoria");case .integral:L10n.text("Integral")}}
}
public struct MathExpression: Codable, Equatable, Hashable, Sendable {
    public var operation: MathOperation = .text
    public var first = "x"
    public var second = "2"
    public var lower = "i=1"
    public var upper = "n"
    public init() {}
    public var readable: String { switch operation {
    case .text: first; case .fraction: "(\(first)) / (\(second))"; case .root: "√(\(first))"
    case .power: "\(first)^(\(second))"; case .subscripted: "\(first)_(\(second))"
    case .sum: "∑ [\(lower)…\(upper)] \(first)"; case .integral: "∫ [\(lower)…\(upper)] \(first) d\(second)"
    }}
}
public struct AcademicNode: Codable, Equatable, Identifiable, Sendable {
    public var id = UUID()
    public var kind: NodeKind
    public var caption = ""
    public var note = ""
    public var source = ""
    public var alt = ""
    public var assetID: UUID?
    public var width = 420.0
    public var alignment = "center"
    public var rows: [[String]] = [["Variable", "Valor"], ["", ""]]
    public var rowIDs = [UUID(),UUID()]
    public var columnIDs = [UUID(),UUID()]
    public var header = true
    public var tableStyle = "Académico"
    public var math = MathExpression()
    public var numbered = true
    public var inline = false
    public var referenceIDs: [UUID] = []
    public var narrative = false
    public var locator = ""
    public var prefix = ""
    public var suffix = ""
    public var targetID: UUID?
    public init(_ kind: NodeKind) { self.kind = kind }
    public mutating func normalizeTableIdentity() {
        let columns=rows.first?.count ?? 0
        rowIDs=Array(rowIDs.prefix(rows.count));while rowIDs.count<rows.count{rowIDs.append(UUID())}
        columnIDs=Array(columnIDs.prefix(columns));while columnIDs.count<columns{columnIDs.append(UUID())}
    }
}
public struct Asset: Codable, Equatable, Identifiable, Sendable {
    public var id = UUID()
    public var name: String
    public var mediaType: String
    public var data: Data
    public var originalData: Data?
    public init(name: String, mediaType: String, data: Data) { self.name = name; self.mediaType = mediaType; self.data = data }
}
public enum CitationStyle: String, Codable, CaseIterable, Sendable {
    case apa, ieee, vancouver, chicago
    public var label:String {switch self {case .apa:"APA 7";case .ieee:"IEEE";case .vancouver:"Vancouver";case .chicago:L10n.text("Chicago autor-fecha")}}
    public var file: String { self == .chicago ? "chicago-author-date" : rawValue }
}
public struct Reference: Codable, Equatable, Identifiable, Sendable {
    public var imported:ImportedReference?
    public var id = UUID()
    public var type = "article-journal"
    public var title = ""
    public var authors = ""
    public var year = ""
    public var container = ""
    public var publisher = ""
    public var volume = ""
    public var issue = ""
    public var pages = ""
    public var doi = ""
    public var url = ""
    public init() {}
    public var csl: [String: Any] {
        var item=(imported.flatMap{try? JSONSerialization.jsonObject(with:$0.cslData)} as? [String:Any]) ?? [:]
        item["id"]=id.uuidString;item["type"]=type
        func update(_ csl:String,_ property:String,_ value:String) {
            if imported?.snapshot[property] != value || item[csl]==nil {item[csl]=value.isEmpty ? nil : value}
        }
        update("title","title",title)
        if imported?.snapshot["authors"] != authors || item["author"]==nil {
            item["author"]=authors.split(separator:";").map {name->[String:String] in
                let pieces=name.split(separator:",",maxSplits:1).map{$0.trimmingCharacters(in:.whitespaces)}
                return pieces.count==2 ? ["family":pieces[0],"given":pieces[1]] : ["literal":pieces[0]]
            }
        }
        if imported?.snapshot["year"] != year || item["issued"]==nil {
            item["issued"]=Int(year).map{["date-parts":[[$0]]]}
        }
        for (csl,property,value) in [("container-title","container",container),("publisher","publisher",publisher),("volume","volume",volume),("issue","issue",issue),("page","pages",pages),("DOI","doi",doi),("URL","url",url)] {update(csl,property,value)}
        return item
    }
}
public struct DocumentTemplate: Codable, Equatable, Identifiable, Sendable {
    public var id:String
    public var name:String
    public var detail:String
    public var version=1
    public var category="Integradas"
    public var font=DocumentTypography.defaultFont
    public var fontSize=12.0
    public var lineSpacing=1.4
    public var marginMM=25.0
    public var paper="a4paper"
    public var cover=false
    public var numberedHeadings=true
    public var locked=false
    public var lockedProperties:[TemplateProperty]?
    public func allows(_ property:TemplateProperty)->Bool {!locked && !(lockedProperties ?? []).contains(property)}
    public var layout:DocumentLayout?
    public var effectiveLayout:DocumentLayout {
        get {layout ?? DocumentLayout(documentClass:["report","thesis"].contains(id) ? .report : (id=="book" ? .book : (id=="letter" ? .letter : .article)))}
        set {layout=newValue}
    }
    public init(id:String,name:String,detail:String) {self.id=id;self.name=name;self.detail=detail}
    public static var builtins:[Self] {
        [DocumentTemplate(id:"blank",name:L10n.text("En blanco"),detail:L10n.text("Una página para comenzar.")),
         DocumentTemplate(id:"report",name:L10n.text("Informe académico"),detail:L10n.text("Estructura clara para comunicar resultados.")),
         DocumentTemplate(id:"article",name:L10n.text("Artículo científico"),detail:L10n.text("Resumen, secciones y bibliografía.")),
         DocumentTemplate(id:"thesis",name:L10n.text("Tesis"),detail:L10n.text("Capítulos, portada y referencias.")),
         DocumentTemplate(id:"book",name:L10n.text("Libro"),detail:L10n.text("Escritura extensa organizada en capítulos.")),
         DocumentTemplate(id:"letter",name:L10n.text("Carta"),detail:L10n.text("Correspondencia formal y sobria."))].map {template in
            var t=template;t.cover=["thesis","book"].contains(t.id)
            t.lineSpacing=t.id=="thesis" ? 1.5 : (t.id=="report" ? 1.4 : 1.15)
            var layout=t.effectiveLayout
            if t.id=="book" {layout.paragraphIndentMM=5;layout.paragraphSpacingPT=0}
            t.layout=layout;return t
        }
    }
}
public struct Metadata: Codable, Equatable, Sendable {
    public var title = L10n.text("Sin título")
    public var subtitle = ""
    public var authors = ""
    public var institution = ""
    public var date = ""
    public var language = "es-ES"
    public var abstract = ""
    public var keywords = ""
    public var citationStyle: CitationStyle = .apa
    public var bibliography = true
    public var spelling = true
    public var autocorrect = false
    public init() {}
}
public struct Cursor: Codable, Equatable, Sendable {
    public var location = 0
    public var length = 0
    public init(location: Int = 0, length: Int = 0) { self.location = location; self.length = length }
}
public struct NabDocument: Codable, Equatable, Identifiable, Sendable {
    public var id = UUID()
    public var schemaVersion = 1
    public var metadata = Metadata()
    public var template = DocumentTemplate.builtins[0]
    public var blocks = [Block()]
    public var nodes: [AcademicNode] = []
    public var assets: [Asset] = []
    public var references: [Reference] = []
    public var cursor = Cursor()
    public var modified = Date()
    public init(template: DocumentTemplate = DocumentTemplate.builtins[0]) { self.template = template }
    public var wordCount: Int { blocks.map(\.text).joined(separator:" ").split { $0.isWhitespace || $0 == "\u{fffc}" }.count }
    public var orderedNodes: [AcademicNode] { blocks.flatMap(\.runs).compactMap { r in r.nodeID.flatMap { id in nodes.first { $0.id == id } } } }
    public func number(of id: UUID) -> Int? {
        guard let node = nodes.first(where: { $0.id == id }) else { return nil }
        let list = orderedNodes.filter { $0.kind == node.kind && ($0.kind != .equation || $0.numbered) }
        return list.firstIndex(where: { $0.id == id }).map { $0 + 1 }
    }
    public func crossReference(_ id: UUID?) -> String {
        guard let id else { return L10n.text("⚠ Destino no encontrado") }
        if let b = blocks.first(where: { $0.id == id }), b.style.headingLevel != nil { return b.text }
        guard let n = nodes.first(where: { $0.id == id }), let number = number(of: id) else { return L10n.text("⚠ Destino no encontrado") }
        let name=switch n.kind {case .figure:L10n.text("Figura");case .table:L10n.text("Tabla");case .equation:L10n.text("Ecuación");default:L10n.text("Elemento")}
        return "\(name) \(number)"
    }
    public mutating func insert(_ node: AcademicNode, after blockID: UUID? = nil) {
        nodes.append(node)
        var block = Block(); block.runs = [TextRun("\u{fffc}",nodeID:node.id)]
        if let blockID, let i = blocks.firstIndex(where: { $0.id == blockID }) { blocks.insert(block,at:i+1) }
        else { blocks.append(block) }
    }
    public static var example: Self {
        var d = Self(template: DocumentTemplate.builtins[1]); d.metadata.title = L10n.text("El oficio de escribir"); d.metadata.authors = L10n.text("Documento de demostración")
        d.blocks = [Block(L10n.text("El oficio de escribir"), style:.title),Block(L10n.text("Del primer borrador a una idea que se entiende."),style:.subtitle),Block(L10n.text("Una idea necesita espacio"),style:.heading1),Block(L10n.text("Escribir es dar forma a lo que pensamos. Este documento de demostración muestra cómo organizar un texto, enlazar sus fuentes y cuidar su presentación sin interrumpir la escritura.")),Block(L10n.text("Estructura antes que apariencia"),style:.heading2),Block(L10n.text("Usa los estilos de la barra para expresar qué significa cada párrafo. El esquema se construye a partir de tus títulos; la plantilla se ocupa de la tipografía.")),Block(L10n.text("Inserta una tabla, una figura o una ecuación desde el menú Insertar.")),Block(L10n.text("Guarda tu trabajo como .nab: contenido, imágenes y referencias viajan juntos."),style:.bullet),Block(L10n.text("Un documento, dos maneras de verlo"),style:.heading1),Block(L10n.text("Alterna entre páginas y lienzo continuo. El texto y el historial son los mismos; la paginación definitiva corresponde al PDF compuesto con LaTeX."))]
        return d
    }
}
public enum NabError: LocalizedError, Equatable {
    case invalid(String), conflict, missingEngine, cancelled
    public var errorDescription: String? { switch self {
    case .invalid(let s): s
    case .conflict: L10n.text("El archivo cambió fuera de Naberius. Guarda una copia para conservar ambas versiones.")
    case .missingEngine: L10n.text("No se encontró Tectonic. Selecciona un motor en Configuración → Composición. Puedes seguir escribiendo y exportar el proyecto LaTeX.")
    case .cancelled: L10n.text("La operación se canceló.")
    }}
}
