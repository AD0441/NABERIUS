import AppKit
import CoreText
import PDFKit
import NaberiusCore
import os

/// Fonts are registered for this process only, never installed into the user's system.
enum DocumentFonts {
    private static let registration: Void = {
        let logger = Logger(subsystem: "cl.sebastianpasten.Naberius", category: "Typography")
        for file in DocumentTypography.fontFiles {
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(DocumentTypography.fontURL(file) as CFURL, .process, &error), let error {
                logger.error("Font registration: \(error.takeRetainedValue().localizedDescription, privacy: .public)")
            }
        }
    }()
    static func font(family: String = DocumentTypography.defaultFont, size: Double, bold: Bool = false, italic: Bool = false) -> NSFont {
        _ = registration
        if family == DocumentTypography.defaultFont {
            let style = bold ? (italic ? "BoldItalic" : "Bold") : (italic ? "Italic" : "Regular")
            if let font = NSFont(name: "LMRoman10-"+style, size: size) { return font }
        }
        let base = NSFont(name: family, size: size) ?? NSFont(name: "LMRoman10-Regular", size: size) ?? NSFont.userFont(ofSize: size)!
        var traits: NSFontTraitMask = []
        if bold { traits.insert(.boldFontMask) }; if italic { traits.insert(.italicFontMask) }
        return NSFontManager.shared.convert(base, toHaveTrait: traits)
    }
}

extension NSAttributedString.Key {
    static let nabLogoCapital = NSAttributedString.Key("nab.logoCapital")
    static let nabLogoFont = NSAttributedString.Key("nab.logoFont")
    static let nabLogoBaseline = NSAttributedString.Key("nab.logoBaseline")
}
extension RichText {
    static func decorateLogos(_ text: NSMutableAttributedString, range input: NSRange? = nil) {
        let range = input ?? NSRange(location: 0, length: text.length)
        guard range.length > 0 else { return }
        var originals: [(NSRange, NSFont, Double)] = []
        text.enumerateAttribute(.nabLogoFont, in: range) { font, r, _ in
            if let font = font as? NSFont { originals.append((r, font, (text.attribute(.nabLogoBaseline, at: r.location, effectiveRange: nil) as? Double) ?? 0)) }
        }
        for (r, font, offset) in originals {
            text.addAttributes([.font: font, .baselineOffset: offset], range: r)
            for key in [NSAttributedString.Key.nabLogoFont, .nabLogoBaseline, .nabLogoCapital, .kern] { text.removeAttribute(key, range: r) }
        }
        let fragment = (text.string as NSString).substring(with: range)
        for logo in DocumentTypography.logos(in: fragment) {
            let location = range.location+logo.range.location
            for index in 0..<logo.range.length {
                let r = NSRange(location: location+index, length: 1)
                guard let font = text.attribute(.font, at: r.location, effectiveRange: nil) as? NSFont else { continue }
                let size = font.pointSize
                let originalBaseline = (text.attribute(.baselineOffset, at: r.location, effectiveRange: nil) as? Double) ?? 0
                var attrs: [NSAttributedString.Key: Any] = [.nabLogoCapital: true, .nabLogoFont: font, .nabLogoBaseline: originalBaseline, .ligature: 0]
                if logo.isLaTeX && index == 1 {
                    attrs[.font] = NSFont(descriptor: font.fontDescriptor, size: size*0.72)
                    attrs[.baselineOffset] = originalBaseline+size*0.30
                }
                let texIndex = logo.isLaTeX ? index-2 : index
                if texIndex == 1 { attrs[.baselineOffset] = originalBaseline-size*0.215 }
                if logo.isLaTeX && index == 0 { attrs[.kern] = -size*0.30 }
                else if logo.isLaTeX && index == 1 { attrs[.kern] = -size*0.12 }
                else if texIndex == 0 { attrs[.kern] = -size*0.12 }
                else if texIndex == 1 { attrs[.kern] = -size*0.10 }
                text.addAttributes(attrs, range: r)
            }
        }
    }
}

/// Crops the actual TeX output, retaining vector rendering until drawn by AppKit.
enum EquationTypesetter {
    static func image(from url: URL, pointSize: Double = 21) throws -> NSImage {
        guard let document = PDFDocument(url: url), let page = document.page(at: 0),
              let selection = page.selection(for: page.bounds(for: .mediaBox)) else {
            throw NabError.invalid(L10n.text("El motor no produjo una ecuación visible."))
        }
        let crop = selection.bounds(for: page).insetBy(dx: -5, dy: -6)
        guard crop.width.isFinite, crop.height.isFinite, crop.width > 0, crop.height > 0 else { throw NabError.invalid(L10n.text("La ecuación no tiene dimensiones válidas.")) }
        let scale = pointSize/10
        let size = NSSize(width: crop.width*scale, height: crop.height*scale)
        let image = NSImage(size: size, flipped: false) { _ in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.saveGState()
            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: -crop.minX, y: -crop.minY)
            page.draw(with: .mediaBox, to: context)
            context.restoreGState()
            context.saveGState()
            context.setBlendMode(.sourceIn)
            context.setFillColor(NSColor.labelColor.cgColor)
            context.fill(NSRect(origin: .zero, size: size))
            context.restoreGState()
            return true
        }
        image.cacheMode = .never
        return image
    }
}
