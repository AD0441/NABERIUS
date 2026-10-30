import SwiftUI
import AppKit
import CoreText
import NaberiusCore

private extension NSAttributedString.Key {
    static let nabStyle = NSAttributedString.Key("nab.style")
    static let nabBlock = NSAttributedString.Key("nab.block")
    static let nabNode = NSAttributedString.Key("nab.node")
}
enum RichText {
    static func attributes(style: BlockStyle, template: DocumentTemplate, dark: Bool = false) -> [NSAttributedString.Key:Any] {
        let base = template.fontSize * 1.25
        let size: Double = switch style { case .title: base*2.05; case .subtitle: base*1.1; case .heading1: base*1.5; case .heading2: base*1.25; case .heading3,.heading4: base*1.1; case .caption: base*0.85; default: base }
        let font = DocumentFonts.font(family:template.font,size:size,bold:style.headingLevel != nil || style == .title)
        let p = NSMutableParagraphStyle(); p.alignment = .justified; p.firstLineHeadIndent = template.effectiveLayout.paragraphIndentMM*72/25.4*1.25; p.paragraphSpacing = template.effectiveLayout.paragraphSpacingPT*1.25; p.lineSpacing = max(0,(template.lineSpacing-1)*base*0.65)
        if style.headingLevel != nil { p.paragraphSpacingBefore = 20; p.paragraphSpacing = 10 }
        if style == .title { p.paragraphSpacing = 16 }; if style == .subtitle { p.paragraphSpacing = 24 }
        if [.quote,.bullet,.numbered].contains(style) { p.headIndent = 25; p.firstLineHeadIndent = style == .quote ? 25 : 5 }
        if style == .bullet || style == .numbered {
            p.tabStops=[NSTextTab(textAlignment:.left,location:25)]
        }
        return [.font:font,.foregroundColor:NSColor.labelColor,.paragraphStyle:p,.nabStyle:style.rawValue]
    }
    static func attributed(_ d: NabDocument, citations: CitationOutput, equations:[MathExpression:NSImage] = [:],editingTable:UUID? = nil) -> NSAttributedString {
        let result = NSMutableAttributedString();var listNumber=0
        for (index,b) in d.blocks.enumerated() {
            var attrs = attributes(style:b.style,template:d.template); attrs[.nabBlock] = b.id.uuidString
            if b.style == .bullet {result.append(NSAttributedString(string:"•\t",attributes:attrs));listNumber=0}
            else if b.style == .numbered {listNumber += 1;result.append(NSAttributedString(string:"\(listNumber).\t",attributes:attrs))}
            else {listNumber=0}
            for run in b.runs {
                if let id = run.nodeID, let node = d.nodes.first(where:{$0.id==id}) {
                    result.append(attachment(node,document:d,citations:citations,attrs:attrs,equations:equations,editingTable:editingTable)); continue
                }
                var a = attrs; var font = a[.font] as! NSFont
                var traits: NSFontTraitMask = []; if run.bold { traits.insert(.boldFontMask) }; if run.italic { traits.insert(.italicFontMask) }
                font = NSFontManager.shared.convert(font,toHaveTrait:traits); a[.font] = font
                if run.script != 0 { a[.baselineOffset] = run.script*5; a[.superscript] = run.script }
                if let link = run.link, let u = URL(string:link), ["http","https","mailto"].contains(u.scheme ?? "") { a[.link] = u }
                result.append(NSAttributedString(string:run.text,attributes:a))
            }
            if b.runs.isEmpty { /* Empty paragraph still receives identity on its newline. */ }
            if index < d.blocks.count-1 { result.append(NSAttributedString(string:"\n",attributes:attrs)) }
        }
        decorateLogos(result)
        return result
    }
    static func attachment(_ n: AcademicNode, document d: NabDocument, citations: CitationOutput, attrs: [NSAttributedString.Key:Any], equations:[MathExpression:NSImage] = [:],editingTable:UUID? = nil) -> NSAttributedString {
        let image: NSImage
        let inline = [.citation,.crossReference,.footnote].contains(n.kind) || (n.kind == .equation && n.inline)
        let width = inline ? 460.0 : min(n.width,570)
        switch n.kind {
        case .figure:
            if let a = d.assets.first(where:{$0.id == n.assetID}), let source = NSImage(data:a.data) {
                let scale=min(width/max(source.size.width,1),450/max(source.size.height,1))
                let w=source.size.width*scale,h=source.size.height*scale
                image = NSImage(size:NSSize(width:w,height:h+54),flipped:false) { rect in
                    source.draw(in:CGRect(x:0,y:54,width:w,height:h),from:.zero,operation:.sourceOver,fraction:1,respectFlipped:false,hints:nil)
                    drawLabel(L10n.format("Figura %@. %@",d.number(of:n.id) ?? 0,n.caption),in:CGRect(x:0,y:22,width:w,height:25),size:12)
                    if !n.source.isEmpty { drawLabel(L10n.text("Fuente: ")+n.source,in:CGRect(x:0,y:2,width:w,height:20),size:10) }; return true
                }
            } else { image = textImage(L10n.text("Imagen no encontrada"),width:width) }
        case .table:
            let cols=max(1,n.rows.first?.count ?? 1),layout=TablePreviewLayout(node:n,width:width,editing:editingTable==n.id)
            let h=layout.height
            image=NSImage(size:NSSize(width:width,height:h),flipped:false){_ in
                NSColor.textBackgroundColor.setFill();NSBezierPath(rect:NSRect(x:0,y:0,width:width,height:h)).fill()
                drawLabel(L10n.format("Tabla %@. %@",d.number(of:n.id) ?? 0,n.caption),in:NSRect(x:0,y:h-25,width:width,height:24),size:12)
                var y=h-30
                for (r,row) in n.rows.prefix(8).enumerated() {
                    let rowHeight=layout.heights[r];y -= rowHeight
                    for (c,value) in row.enumerated() {
                        let cell=NSRect(x:Double(c)*width/Double(cols),y:y,width:width/Double(cols),height:rowHeight)
                        if r==0 && n.header && n.tableStyle != "Simple" {NSColor.quaternaryLabelColor.setFill();NSBezierPath(rect:cell).fill()}
                        if n.tableStyle=="Cuadrícula" {NSColor.separatorColor.setStroke();NSBezierPath(rect:cell).stroke()}
                        if n.tableStyle != "Simple" {NSColor.separatorColor.setStroke();let line=NSBezierPath();line.move(to:NSPoint(x:cell.minX,y:cell.minY));line.line(to:NSPoint(x:cell.maxX,y:cell.minY));line.lineWidth=0.5;line.stroke()}
                        drawLabel(value,in:cell.insetBy(dx:7,dy:5),size:12)
                    }
                }
                let footer=layout.abbreviated ? L10n.format("Vista de 8 de %@ filas · doble clic para editar",n.rows.count) : L10n.text("Doble clic para editar las celdas")
                drawLabel(footer,in:NSRect(x:0,y:3,width:width,height:20),size:10)
                return true
            }
        case .equation:
            let formula = n.math.readable + (n.numbered && !n.inline ? "     (\(d.number(of:n.id) ?? 0))" : "")
            if let rendered = equations[n.math] {
                let ratio = min(1, width/max(1,rendered.size.width))
                let contentSize = NSSize(width:rendered.size.width*ratio,height:rendered.size.height*ratio)
                let label = n.numbered && !n.inline ? "(\(d.number(of:n.id) ?? 0))" : ""
                let canvas = NSSize(width:inline ? contentSize.width : width,height:contentSize.height+4)
                image = NSImage(size:canvas,flipped:false) { _ in
                    rendered.draw(in:NSRect(x:inline ? 0 : (width-contentSize.width)/2,y:2,width:contentSize.width,height:contentSize.height))
                    if !label.isEmpty {drawLabel(label,in:NSRect(x:width-38,y:(canvas.height-18)/2,width:38,height:18),size:13)}
                    return true
                }
            } else { image = textImage(formula,width:width,size:20,inline:inline) }
        case .citation: image = textImage(citations.citations[n.id] ?? L10n.text("[Cita bibliográfica]"),width:width,size:15,inline:true)
        case .crossReference: image = textImage(d.crossReference(n.targetID),width:width,size:15,inline:true)
        case .footnote: image = textImage("[\(d.number(of:n.id) ?? 1)]",width:60,size:12,inline:true)
        case .separator:
            image=NSImage(size:NSSize(width:width,height:20),flipped:false){_ in
                NSColor.separatorColor.setStroke();let line=NSBezierPath();line.move(to:NSPoint(x:0,y:10));line.line(to:NSPoint(x:width,y:10));line.lineWidth=0.5;line.stroke();return true
            }
        case .contents:
            let headings = d.blocks.filter{$0.style.headingLevel != nil}.map { String(repeating:"   ",count:($0.style.headingLevel ?? 1)-1)+$0.text }.joined(separator:"\n")
            image = textImage("Índice\n"+headings,width:width,size:14)
        }
        let attachment = NSTextAttachment(); attachment.attachmentCell = NSTextAttachmentCell(imageCell:image)
        let result = NSMutableAttributedString(attributedString:NSAttributedString(attachment:attachment))
        var a = attrs; a[.nabNode] = n.id.uuidString
        if !inline,let paragraph=(attrs[.paragraphStyle] as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle {paragraph.alignment=n.alignment == "left" ? .left : (n.alignment == "right" ? .right : .center);a[.paragraphStyle]=paragraph}
        if inline { a[.baselineOffset] = -3 }
        result.addAttributes(a,range:NSRange(location:0,length:result.length)); return result
    }
    private static func drawLabel(_ text: String,in rect: CGRect,size:Double) { (text as NSString).draw(in:rect,withAttributes:[.font:DocumentFonts.font(size:size),.foregroundColor:NSColor.labelColor]) }
    private static func textImage(_ text:String,width:Double,size:Double = 14,inline:Bool = false)->NSImage {
        let font = DocumentFonts.font(size:size)
        let measured = (text as NSString).boundingRect(with:NSSize(width:width,height:2000),options:[.usesLineFragmentOrigin],attributes:[.font:font])
        let w = inline ? min(width,ceil(measured.width)+6) : width, h = max(size+6,ceil(measured.height)+8)
        return NSImage(size:NSSize(width:w,height:h),flipped:false) { _ in drawLabel(text,in:CGRect(x:2,y:3,width:w-4,height:h-3),size:size); return true }
    }
    static func blocks(_ text: NSAttributedString) -> [Block] {
        let ns = text.string as NSString; var result: [Block] = []; var location = 0; var used: Set<UUID> = []
        while location < ns.length {
            let range = ns.paragraphRange(for:NSRange(location:location,length:0))
            let attrs = text.attributes(at:range.location,effectiveRange:nil)
            var b = Block(); b.id = (attrs[.nabBlock] as? String).flatMap(UUID.init(uuidString:)) ?? UUID()
            if used.contains(b.id) { b.id = UUID() }; used.insert(b.id)
            b.style = (attrs[.nabStyle] as? String).flatMap(BlockStyle.init(rawValue:)) ?? .paragraph; b.runs=[]
            let end = range.location+range.length; let contentEnd = end > 0 && ns.substring(with:NSRange(location:end-1,length:1)) == "\n" ? end-1 : end
            if contentEnd > range.location { text.enumerateAttributes(in:NSRange(location:range.location,length:contentEnd-range.location)) { a,r,_ in
                var run = TextRun(ns.substring(with:r)); if let font = a[.font] as? NSFont { let traits = NSFontManager.shared.traits(of:font); run.bold = traits.contains(.boldFontMask) && b.style.headingLevel == nil && b.style != .title; run.italic = traits.contains(.italicFontMask) }
                run.script = (a[.superscript] as? Int) ?? 0; run.link = (a[.link] as? URL)?.absoluteString ?? a[.link] as? String; run.nodeID = (a[.nabNode] as? String).flatMap(UUID.init(uuidString:)); b.runs.append(run)
            }}
            if [.bullet,.numbered].contains(b.style),!b.runs.isEmpty {
                if let tab=b.runs[0].text.firstIndex(of:"\t") {b.runs[0].text=String(b.runs[0].text[b.runs[0].text.index(after:tab)...]);if b.runs[0].text.isEmpty{b.runs.removeFirst()}}
            }
            b.runs=b.semanticRuns
            result.append(b); location = end
        }
        if ns.length == 0 || text.string.hasSuffix("\n") { result.append(Block()) }
        return result
    }
}
final class NativeTextView: NSTextView, NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager:NSLayoutManager,shouldGenerateGlyphs glyphs:UnsafePointer<CGGlyph>,properties:UnsafePointer<NSLayoutManager.GlyphProperty>,characterIndexes:UnsafePointer<Int>,font:NSFont,forGlyphRange glyphRange:NSRange)->Int {
        guard let storage=layoutManager.textStorage else{return 0}
        var replacements=Array(UnsafeBufferPointer(start:glyphs,count:glyphRange.length))
        var changed=false
        let source=storage.string as NSString
        let ctFont=CTFontCreateWithName(font.fontName as CFString,font.pointSize,nil)
        for i in 0..<glyphRange.length {
            let index=characterIndexes[i]
            guard index<storage.length,storage.attribute(.nabLogoCapital,at:index,effectiveRange:nil) as? Bool == true else{continue}
            var character=(source.substring(with:NSRange(location:index,length:1)).uppercased() as NSString).character(at:0)
            var glyph:CGGlyph=0
            if CTFontGetGlyphsForCharacters(ctFont,&character,&glyph,1){replacements[i]=glyph;changed=true}
        }
        guard changed else{return 0}
        layoutManager.setGlyphs(replacements,properties:properties,characterIndexes:characterIndexes,font:font,forGlyphRange:glyphRange)
        return glyphRange.length
    }
    weak var session: Session?
    private var tableNeedsReveal=false
    private var inlineTable:InlineTableEditor?
    var pageMode = true
    override func mouseDown(with event:NSEvent) {
        if event.clickCount==2,let layoutManager,let container=textContainer,let storage=textStorage {
            let point=convert(event.locationInWindow,from:nil)
            let origin=textContainerOrigin
            let glyph=layoutManager.glyphIndex(for:NSPoint(x:point.x-origin.x,y:point.y-origin.y),in:container)
            if glyph<layoutManager.numberOfGlyphs {
                let index=layoutManager.characterIndexForGlyph(at:glyph)
                if index<storage.length,let raw=storage.attribute(.nabNode,at:index,effectiveRange:nil) as? String,let id=UUID(uuidString:raw),session?.document?.nodes.first(where:{$0.id==id})?.kind == .table {
                    setSelectedRange(NSRange(location:index,length:1));editTable(id);return
                }
            }
        }
        super.mouseDown(with:event)
    }
    func editTable(_ id:UUID) {
        guard let session,!session.showProof,let node=session.document?.nodes.first(where:{$0.id==id && $0.kind == .table}) else{return}
        finishTableEditing()
        if node.rowIDs.count != node.rows.count || node.columnIDs.count != node.rows.first?.count {
            session.mutate(L10n.text("Preparar tabla"),registerUndo:false) {document in if let i=document.nodes.firstIndex(where:{$0.id==id}) {document.nodes[i].normalizeTableIdentity()}}
        }
        guard let node=session.document?.nodes.first(where:{$0.id==id}) else{return}
        session.inlineTableID=id;session.selectedNode=id;session.inspector=false;session.revision += 1;tableNeedsReveal=true
        let overlay=InlineTableEditor(owner:self,session:session,node:node);inlineTable=overlay;addSubview(overlay)
        positionTableEditor();overlay.focus()
    }
    func finishTableEditing() {
        guard inlineTable != nil else{return}
        window?.makeFirstResponder(self);inlineTable?.removeFromSuperview();inlineTable=nil
        session?.inlineTableID=nil;session?.revision += 1
    }
    func positionTableEditor() {
        guard let overlay=inlineTable,let layoutManager,let container=textContainer,let storage=textStorage else{return}
        var location:NSRange?
        storage.enumerateAttribute(.nabNode,in:NSRange(location:0,length:storage.length)){value,range,stop in
            if value as? String == overlay.nodeID.uuidString {location=range;stop.pointee=true}
        }
        guard let location else{finishTableEditing();return}
        let glyph=layoutManager.glyphRange(forCharacterRange:location,actualCharacterRange:nil)
        let rect=layoutManager.boundingRect(forGlyphRange:glyph,in:container).offsetBy(dx:textContainerOrigin.x,dy:textContainerOrigin.y)
        let width=max(340,min(rect.width,bounds.width-textContainerInset.width*2))
        overlay.frame=NSRect(x:max(textContainerInset.width,min(rect.minX,bounds.width-textContainerInset.width-width)),y:rect.minY,width:width,height:max(220,min(360,rect.height)))
        if let node=session?.document?.nodes.first(where:{$0.id==overlay.nodeID}) {overlay.sync(node)}
        if tableNeedsReveal && rect.height>=299 {tableNeedsReveal=false;scrollToVisible(overlay.frame.insetBy(dx:0,dy:-12))}
    }
    override func layout() {super.layout();positionTableEditor()}
    var pageHeight = 1052.0
    func movePage(_ direction:Int) {
        guard let scroll=enclosingScrollView else{return}
        let current=scroll.contentView.bounds.minY
        let next=min(max(0,current+Double(direction)*pageHeight),max(0,bounds.height-scroll.contentSize.height))
        scroll.contentView.scroll(to:NSPoint(x:0,y:next));scroll.reflectScrolledClipView(scroll.contentView)
    }
    override func drawBackground(in rect: NSRect) {
        super.drawBackground(in:rect)
        guard pageMode else { return }
        NSColor.separatorColor.setStroke()
        let start = max(1,Int(rect.minY/pageHeight))
        let end = min(500,Int(rect.maxY/pageHeight)+1)
        if start <= end { for page in start...end {
            let y = Double(page)*pageHeight+textContainerInset.height
            let path = NSBezierPath(); path.move(to:CGPoint(x:0,y:y)); path.line(to:CGPoint(x:bounds.width,y:y)); path.lineWidth=0.5; path.stroke()
        }}
    }
    func toggleBold() {guard session?.showProof != true else{return};toggleTrait(.boldFontMask)}
    func toggleItalic() {guard session?.showProof != true else{return};toggleTrait(.italicFontMask)}
    private func toggleTrait(_ trait:NSFontTraitMask) {
        let range=selectedRange()
        func toggled(_ font:NSFont)->NSFont { let manager=NSFontManager.shared;return manager.traits(of:font).contains(trait) ? manager.convert(font,toNotHaveTrait:trait) : manager.convert(font,toHaveTrait:trait) }
        if range.length==0 { var a=typingAttributes;a[.font]=toggled(a[.font] as? NSFont ?? NSFont.systemFont(ofSize:16));typingAttributes=a;return }
        let copy=attributedString();copy.enumerateAttribute(.font,in:range){font,r,_ in if let font=font as? NSFont{textStorage?.addAttribute(.font,value:toggled(font),range:r)}};didChangeText()
    }
    func insertPageBreak() {
        guard let d=session?.document else{return}
        let normal=RichText.attributes(style:.paragraph,template:d.template),special=RichText.attributes(style:.pageBreak,template:d.template)
        let fragment=NSMutableAttributedString(string:"\n",attributes:normal);fragment.append(NSAttributedString(string:L10n.text("[Salto de página]\n"),attributes:special));insertText(fragment,replacementRange:selectedRange());typingAttributes=normal
    }
    func applyStyle(_ style: BlockStyle) {
        guard let session,!session.showProof,let d=session.document else{return}
        let selected=selectedRange(),ns=string as NSString
        let start=ns.substring(to:min(selected.location,ns.length)).components(separatedBy:"\n").count-1
        let end=ns.substring(to:min(selected.location+selected.length,ns.length)).components(separatedBy:"\n").count-1
        var blocks=RichText.blocks(attributedString())
        let oldStyle=blocks[min(start,blocks.count-1)].style
        for i in start...min(end,blocks.count-1){blocks[i].style=style}
        session.mutate(L10n.text("Cambiar estilo")){$0.blocks=blocks}
        let value=RichText.attributed(session.document!,citations:session.citations)
        let delta=value.length-attributedString().length
        textStorage?.setAttributedString(value)
        let position=min(value.length,max(0,selected.location+(oldStyle == style ? 0 : delta)))
        setSelectedRange(NSRange(location:position,length:min(selected.length,value.length-position)))
        var attrs=RichText.attributes(style:style,template:d.template);attrs[.nabBlock]=blocks[min(start,blocks.count-1)].id.uuidString;typingAttributes=attrs;session.selectedStyle=style
    }
    func insertNode(_ n: AcademicNode) {
        guard let session, let d = session.document else { return }
        let attrs = RichText.attributes(style:.paragraph,template:d.template)
        let a = RichText.attachment(n,document:d,citations:session.citations,attrs:attrs)
        let block = ![.citation,.crossReference,.footnote].contains(n.kind) && !(n.kind == .equation && n.inline)
        let result = NSMutableAttributedString()
        if block && selectedRange().location > 0 { result.append(NSAttributedString(string:"\n",attributes:attrs)) }
        result.append(a); if block { result.append(NSAttributedString(string:"\n",attributes:attrs)) }
        insertText(result,replacementRange:selectedRange()); typingAttributes=attrs
    }
    override func insertNewline(_ sender: Any?) {
        guard let session, let template = session.document?.template else { super.insertNewline(sender); return }
        let r = (string as NSString).paragraphRange(for:selectedRange())
        let current = session.selectedStyle
        var content=(string as NSString).substring(with:r).trimmingCharacters(in:.whitespacesAndNewlines)
        if [.bullet,.numbered].contains(current),let tab=content.firstIndex(of:"\t"){content=String(content[content.index(after:tab)...]).trimmingCharacters(in:.whitespacesAndNewlines)}
        if current == .bullet && content == "•" {content=""}
        if current == .numbered && content.hasSuffix(".") && content.dropLast().allSatisfy(\.isNumber){content=""}
        if [.bullet,.numbered].contains(current) && content.isEmpty {applyStyle(.paragraph);return}
        super.insertNewline(sender)
        if current == .bullet {insertText(L10n.text("•\t"),replacementRange:selectedRange())}
        if current == .numbered {insertText(L10n.text("1.\t"),replacementRange:selectedRange())}
        let next: BlockStyle = current.headingLevel != nil || [.title,.subtitle].contains(current) ? .paragraph : current
        var attrs = RichText.attributes(style:next,template:template); attrs[.nabBlock] = UUID().uuidString
        typingAttributes=attrs; session.selectedStyle=next
        if [.bullet,.numbered].contains(next),let d=session.document {
            let value=RichText.attributed(d,citations:session.citations,equations:session.equationImages),oldLength=attributedString().length,range=selectedRange()
            textStorage?.setAttributedString(value);setSelectedRange(NSRange(location:min(value.length,max(0,range.location+value.length-oldLength)),length:0));typingAttributes=attrs
        }
    }
    override func paste(_ sender: Any?) {
        if let data=NSPasteboard.general.data(forType:NSPasteboard.PasteboardType("cl.naberius.portable-fragment")),let session,var destination=session.document {
            do {
                let fragment=try NabArchive.decode(data)
                let blocks=try DocumentFragment.importBlocks(fragment,into:&destination)
                var display=destination;display.blocks=blocks
                session.undo.beginUndoGrouping()
                defer {session.undo.endUndoGrouping()}
                session.mutate(L10n.text("Pegar contenido")) {$0=destination}
                insertText(RichText.attributed(display,citations:session.citations,equations:session.equationImages),replacementRange:selectedRange())
                session.refreshCitations()
            } catch {session.error=error.localizedDescription}
            return
        }
        if let data = NSPasteboard.general.data(forType:.rtf), let attr = try? NSAttributedString(data:data,options:[.documentType:NSAttributedString.DocumentType.rtf],documentAttributes:nil) {
            let clean = NSMutableAttributedString(attributedString:attr)
            clean.removeAttribute(.attachment,range:NSRange(location:0,length:clean.length))
            clean.mutableString.replaceOccurrences(of:"\u{fffc}",with:L10n.text("[Imagen no incluida]"),range:NSRange(location:0,length:clean.length))
            if var display=session?.document {
                display.blocks=RichText.blocks(clean)
                insertText(RichText.attributed(display,citations:CitationOutput()),replacementRange:selectedRange())
            } else {insertText(clean.string,replacementRange:selectedRange())}
            return
        }
        if let data=NSPasteboard.general.data(forType:.png) ?? NSPasteboard.general.data(forType:.tiff),let image=NSImage(data:data){ session?.pasteImage(image);return }
        if let text = NSPasteboard.general.string(forType:.string) { insertText(text,replacementRange:selectedRange()) }
    }
    override func copy(_ sender: Any?) {
        super.copy(sender); guard selectedRange().length > 0, let storage=textStorage else { return }
        let fragment = RichText.blocks(storage.attributedSubstring(from:selectedRange()))
        if let source=session?.document,let data=try? NabArchive.encode(DocumentFragment.selection(fragment,from:source)){NSPasteboard.general.setData(data,forType:NSPasteboard.PasteboardType("cl.naberius.portable-fragment"))}
    }
    override func cut(_ sender: Any?) { copy(sender); insertText("",replacementRange:selectedRange()) }
    override func pasteAsPlainText(_ sender: Any?) {
        if let s=NSPasteboard.general.string(forType:.string),let template=session?.document?.template {
            let attrs=RichText.attributes(style:session?.selectedStyle ?? .paragraph,template:template)
            insertText(NSAttributedString(string:s,attributes:attrs),replacementRange:selectedRange());typingAttributes=attrs
        }
    }
    override func menu(for event:NSEvent)->NSMenu? {
        guard let menu=super.menu(for:event) else{return nil}
        if selectedRange().length>0 {
            menu.addItem(.separator())
            for (title,selector) in [(L10n.text("Negrita"),#selector(contextBold(_:))),(L10n.text("Cursiva"),#selector(contextItalic(_:))),(L10n.text("Enlace…"),#selector(contextLink(_:))),(L10n.text("Cita bibliográfica…"),#selector(contextCitation(_:)))] {
                let item=NSMenuItem(title:title,action:selector,keyEquivalent:"");item.target=self;menu.addItem(item)
            }
            let styles=NSMenu(title:L10n.text("Estilo semántico"))
            for style in BlockStyle.allCases {let item=NSMenuItem(title:style.label,action:#selector(contextStyle(_:)),keyEquivalent:"");item.target=self;item.representedObject=style.rawValue;styles.addItem(item)}
            let parent=NSMenuItem(title:L10n.text("Estilo semántico"),action:nil,keyEquivalent:"");parent.submenu=styles;menu.addItem(parent)
        }
        return menu
    }
    @objc private func contextBold(_ sender:Any?) {toggleBold()}
    @objc private func contextItalic(_ sender:Any?) {toggleItalic()}
    @objc private func contextLink(_ sender:Any?) {session?.sheet = .link}
    @objc private func contextCitation(_ sender:Any?) {session?.sheet = .citation}
    @objc private func contextStyle(_ sender:NSMenuItem) {if let raw=sender.representedObject as? String,let style=BlockStyle(rawValue:raw){applyStyle(style)}}
    override func performDragOperation(_ sender:any NSDraggingInfo)->Bool {
        if let urls=sender.draggingPasteboard.readObjects(forClasses:[NSURL.self]) as? [URL],let url=urls.first {
            do {try session?.addFigure(url);return true}catch{session?.error=error.localizedDescription;return false}
        }
        return super.performDragOperation(sender)
    }
    override func readSelection(from pboard: NSPasteboard,type: NSPasteboard.PasteboardType) -> Bool { if let text=pboard.string(forType:.string) { insertText(text,replacementRange:selectedRange()); return true }; return false }
}
final class EditorScrollView:NSScrollView {
    override func tile() {
        super.tile()
        guard let text=documentView as? NativeTextView,let container=text.textContainer else{return}
        let width=max(250,contentSize.width)
        if abs(text.frame.width-width)>0.5 {text.setFrameSize(NSSize(width:width,height:max(text.frame.height,contentSize.height)))}
        let contentWidth=max(160,width-2*text.textContainerInset.width)
        if abs(container.containerSize.width-contentWidth)>0.5 {container.containerSize=NSSize(width:contentWidth,height:CGFloat.greatestFiniteMagnitude)}
    }
}
struct NativeEditor: NSViewRepresentable {
    let session: Session
    @Environment(\.colorScheme) private var colorScheme
    func makeCoordinator()->Coordinator { Coordinator(session) }
    func makeNSView(context: Context)->NSScrollView {
        let scroll = EditorScrollView(); scroll.hasVerticalScroller=true; scroll.hasHorizontalScroller=false; scroll.autohidesScrollers=true;scroll.allowsMagnification=true;scroll.minMagnification=0.6;scroll.maxMagnification=1.8
        let text = NativeTextView(frame:CGRect(x:0,y:0,width:740,height:1000)); text.session=session; text.delegate=context.coordinator; text.layoutManager?.delegate=text
        text.isRichText=true; text.importsGraphics=false;text.usesFontPanel=false; text.allowsUndo=false; text.isVerticallyResizable=true; text.isHorizontallyResizable=false
        text.minSize=NSSize(width:0,height:1000); text.maxSize=NSSize(width:100000,height:CGFloat.greatestFiniteMagnitude)
        text.autoresizingMask=[.width]; text.textContainer?.widthTracksTextView=false; text.textContainerInset=NSSize(width:56,height:50);text.textContainer?.containerSize=NSSize(width:628,height:CGFloat.greatestFiniteMagnitude)
        text.isAutomaticQuoteSubstitutionEnabled=true; text.isAutomaticDashSubstitutionEnabled=true; text.isAutomaticLinkDetectionEnabled=false
        text.setAccessibilityLabel(L10n.text("Contenido del documento"))
        scroll.documentView=text; session.editor=text; configure(text,context:context)
        return scroll
    }
    func updateNSView(_ scroll:NSScrollView,context:Context) {
        guard let text=scroll.documentView as? NativeTextView else { return }; configure(text,context:context)
    }
    private func configure(_ text:NativeTextView,context:Context) {
        guard let d=session.document else { return }
        if let scroll=text.enclosingScrollView,abs(scroll.magnification-session.zoom)>0.01{scroll.magnification=session.zoom}
        text.pageMode=session.pageMode;text.pageHeight=(d.template.paper == "letterpaper" ? 792 : (d.template.paper == "legalpaper" ? 1008 : 841.89))*1.25; text.isContinuousSpellCheckingEnabled=d.metadata.spelling; text.isAutomaticSpellingCorrectionEnabled=d.metadata.autocorrect
        NSSpellChecker.shared.setLanguage(d.metadata.language)
        let inset: CGFloat = session.pageMode ? CGFloat(d.template.marginMM*72/25.4*1.25) : 40
        if text.textContainerInset.width != inset { text.textContainerInset=NSSize(width:inset,height:50) }
        let c=context.coordinator
        if c.lastRevision != session.revision || c.lastScheme != colorScheme {
            c.updating=true
            let range = c.documentID == d.id && !session.restoreSelection ? text.selectedRange() : NSRange(location:d.cursor.location,length:d.cursor.length);session.restoreSelection=false
            let visible = text.enclosingScrollView?.contentView.bounds.origin
            let value=RichText.attributed(d,citations:session.citations,equations:session.equationImages,editingTable:session.inlineTableID)
            if text.attributedString() != value { text.textStorage?.setAttributedString(value) }
            let location=min(range.location,text.string.utf16.count), length=min(range.length,text.string.utf16.count-location)
            text.setSelectedRange(NSRange(location:location,length:length))
            if let visible,c.documentID == d.id { text.enclosingScrollView?.contentView.scroll(to:visible) }
            text.typingAttributes=RichText.attributes(style:session.selectedStyle,template:d.template)
            c.lastRevision=session.revision; c.lastScheme=colorScheme; c.documentID=d.id; c.updating=false
        }
        text.backgroundColor = .textBackgroundColor; text.insertionPointColor = .labelColor
        let width=max(160,(text.enclosingScrollView?.contentSize.width ?? 740)-2*inset)
        text.textContainer?.containerSize=NSSize(width:width,height:CGFloat.greatestFiniteMagnitude)
        if session.pageMode {
            let pages=min(300,max(3,text.string.count/1800+3))
            text.textContainer?.exclusionPaths=(1...pages).map {page in NSBezierPath(rect:CGRect(x:0,y:CGFloat(page)*text.pageHeight-40,width:width,height:40))}
        } else {text.textContainer?.exclusionPaths=[]}
        text.needsDisplay=true;text.positionTableEditor()
    }
    final class Coordinator: NSObject,NSTextViewDelegate {
        let session:Session; var updating=false; var lastRevision = -1; var lastScheme:ColorScheme?; var documentID:UUID?
        private var simpleEditBlock: UUID?
        private var simpleEditStart = 0
        init(_ session:Session) { self.session=session }
        func textView(_ textView:NSTextView,shouldChangeTextIn affectedCharRange:NSRange,replacementString:String?)->Bool {
            simpleEditBlock=nil
            guard let replacementString,!replacementString.contains(where:{$0.isNewline}),affectedCharRange.location != NSNotFound else{return true}
            let source=textView.string as NSString
            guard NSMaxRange(affectedCharRange)<=source.length,source.length>0,!source.substring(with:affectedCharRange).contains(where:{$0.isNewline}) else{return true}
            guard !(affectedCharRange.location==source.length && (source as String).last?.isNewline == true) else{return true}
            let paragraph=source.paragraphRange(for:NSRange(location:min(affectedCharRange.location,source.length-1),length:0))
            guard NSMaxRange(affectedCharRange)<=NSMaxRange(paragraph) else{return true}
            let position=min(paragraph.location,source.length-1)
            simpleEditBlock=(textView.attributedString().attribute(.nabBlock,at:position,effectiveRange:nil) as? String).flatMap(UUID.init(uuidString:))
            simpleEditStart=paragraph.location
            return true
        }
        func textDidChange(_ notification:Notification) {
            guard !updating,let t=notification.object as? NativeTextView else { return }
            let range=t.selectedRange()
            var blocks: [Block]
            if let id=simpleEditBlock,var existing=session.document?.blocks,let index=existing.firstIndex(where:{$0.id==id}),!t.string.isEmpty {
                let ns=t.string as NSString
                let paragraph=ns.paragraphRange(for:NSRange(location:min(simpleEditStart,ns.length-1),length:0))
                var block=RichText.blocks(t.attributedString().attributedSubstring(from:paragraph)).first ?? Block()
                block.id=id;existing[index]=block;blocks=existing
                t.textStorage?.addAttribute(.nabBlock,value:id.uuidString,range:paragraph)
            } else {
                blocks=RichText.blocks(t.attributedString())
                var offset=0
                for block in blocks {
                    if offset<t.string.utf16.count {
                        let r=(t.string as NSString).paragraphRange(for:NSRange(location:offset,length:0));t.textStorage?.addAttribute(.nabBlock,value:block.id.uuidString,range:r);offset=r.location+r.length
                    } else {var attrs=t.typingAttributes;attrs[.nabBlock]=block.id.uuidString;t.typingAttributes=attrs}
                }
            }
            simpleEditBlock=nil
            session.textChanged(blocks,cursor:Cursor(location:range.location,length:range.length)); lastRevision=session.revision
            if let storage=t.textStorage,storage.length>0 {
                let paragraph=(t.string as NSString).paragraphRange(for:NSRange(location:min(range.location,storage.length-1),length:0))
                RichText.decorateLogos(storage,range:paragraph)
            }
            var typing=t.typingAttributes
            if let font=typing[.nabLogoFont] as? NSFont {
                typing[.font]=font;typing[.baselineOffset]=typing[.nabLogoBaseline] ?? 0
                for key in [NSAttributedString.Key.nabLogoFont,.nabLogoBaseline,.nabLogoCapital,.kern]{typing.removeValue(forKey:key)}
                t.typingAttributes=typing
            }
        }
        func textViewDidChangeSelection(_ notification:Notification) {
            guard !updating,let t=notification.object as? NativeTextView else { return }
            let range=t.selectedRange(),length=t.string.utf16.count
            if length > 0 {
                let a=t.attributedString().attributes(at:min(range.location,length-1),effectiveRange:nil)
                session.selectedStyle=(a[.nabStyle] as? String).flatMap(BlockStyle.init(rawValue:)) ?? .paragraph
                session.selectedBlock=(a[.nabBlock] as? String).flatMap(UUID.init(uuidString:)); session.selectedNode=(a[.nabNode] as? String).flatMap(UUID.init(uuidString:))
            }
            if var d=session.document { d.cursor=Cursor(location:range.location,length:range.length); session.document=d }
        }
        func textView(_ textView:NSTextView,doCommandBy commandSelector:Selector)->Bool {
            if commandSelector == #selector(NSTextView.insertTab(_:)) { return false }; return false
        }
    }
}
