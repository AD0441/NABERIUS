import Foundation

public enum DocumentClass: String, Codable, CaseIterable, Sendable {
    case article, report, book, letter
    public var label:String {switch self {case .article:L10n.text("Artículo");case .report:L10n.text("Informe / tesis");case .book:L10n.text("Libro");case .letter:L10n.text("Carta")}}
    public var hasChapters: Bool { self == .report || self == .book }
}

/// Optional in version-one templates so existing .nab files remain readable.
public struct DocumentLayout: Codable, Equatable, Sendable {
    public var documentClass: DocumentClass = .article
    public var columns:Int?
    public var columnGapMM:Double?
    public var marginTopMM:Double?
    public var marginBottomMM:Double?
    public var marginLeftMM:Double?
    public var marginRightMM:Double?
    public var columnCount:Int {get{columns ?? 1} set{columns=newValue==1 ? nil : newValue}}
    public var columnSeparationMM:Double {get{columnGapMM ?? 6} set{columnGapMM=newValue}}
    public var needsSchemaThree:Bool {columns != nil || columnGapMM != nil || [marginTopMM,marginBottomMM,marginLeftMM,marginRightMM].contains{$0 != nil}}
    public var paragraphIndentMM = 0.0
    public var paragraphSpacingPT = 7.0
    public var header = ""
    public var footer = ""
    public var pageNumbers = true
    public var recipient = ""
    public var opening = ""
    public var closing = "Atentamente,"
    public init(documentClass: DocumentClass = .article) { self.documentClass = documentClass }
}

public struct LogoMatch: Sendable {
    public let range: NSRange
    public let isLaTeX: Bool
}
public enum DocumentTypography {
    public static let defaultFont = "Latin Modern Roman"
    public static let supportedFonts = [defaultFont, "Times New Roman", "Georgia", "Helvetica", "Arial"]
    public static let fontFiles = ["lmroman10-regular.otf", "lmroman10-bold.otf", "lmroman10-italic.otf", "lmroman10-bolditalic.otf"]
    public static var fontDirectory: URL { Bundle.module.url(forResource: "Fonts", withExtension: nil, subdirectory: "Resources")! }
    public static func fontURL(_ file: String) -> URL { fontDirectory.appendingPathComponent(file) }
    public static func safeFont(_ name: String) -> String { supportedFonts.contains(name) ? name : defaultFont }
    private static let logoPattern = try! NSRegularExpression(pattern: #"(?<![\p{L}\p{N}_])(?:LaTeX|Latex|LATEX|TeX)(?![\p{L}\p{N}_])"#)
    public static func logos(in text: String) -> [LogoMatch] {
        logoPattern.matches(in: text, range: NSRange(text.startIndex..., in: text)).map {
            LogoMatch(range: $0.range, isLaTeX: $0.range.length == 5)
        }
    }
}

public enum TemplateProperty:String,Codable,CaseIterable,Sendable {
    case font,fontSize,lineSpacing,marginMM,paper,cover,numberedHeadings,layout
    public var label:String {switch self {
    case .font:L10n.text("Tipografía");case .fontSize:L10n.text("Tamaño de letra");case .lineSpacing:L10n.text("Interlineado");case .marginMM:L10n.text("Márgenes");case .paper:L10n.text("Papel");case .cover:L10n.text("Portada");case .numberedHeadings:L10n.text("Numeración de títulos");case .layout:L10n.text("Estructura, sangría y cabeceras")
    }}
}
