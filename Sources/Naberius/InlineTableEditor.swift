import AppKit
import NaberiusCore

final class TableCellField:NSTextField {
    var rowID:UUID?
    var columnID:UUID?
    var registeredEdit=false
}

/// A cell-specific field editor intercepts only rectangular spreadsheet text.
final class TableFieldEditor:NSTextView {
    weak var grid:InlineTableEditor?
    weak var field:TableCellField?
    override var undoManager:UndoManager? {grid?.session?.undo ?? super.undoManager}
    override func paste(_ sender:Any?) {
        if let field,grid?.pasteCells(from:.general,at:field)==true {return}
        super.paste(sender)
    }
    override func pasteAsPlainText(_ sender:Any?) {paste(sender)}
}
final class TableFieldCell:NSTextFieldCell {
    weak var grid:InlineTableEditor?
    override func fieldEditor(for controlView:NSView)->NSTextView? {
        guard let grid,let field=controlView as? TableCellField else{return nil}
        grid.fieldEditor.field=field
        return grid.fieldEditor
    }
}

/// One native grid is mounted over the active table attachment, in the document itself.
final class InlineTableEditor:NSView,NSTableViewDataSource,NSTableViewDelegate,NSTextFieldDelegate {
    weak var owner:NativeTextView?
    weak var session:Session?
    let nodeID:UUID
    private var node:AcademicNode
    let fieldEditor=TableFieldEditor()
    private let table=NSTableView()
    private let scroll=NSScrollView()
    private let heading=NSTextField(labelWithString:"")
    private let hint=NSTextField(labelWithString:L10n.text("Tab: siguiente celda · ⌘V: pegar rango · Esc: terminar"))
    private var updating=false
    private var lastWidth=0.0
    private var font:NSFont
    init(owner:NativeTextView,session:Session,node:AcademicNode) {
        self.owner=owner;self.session=session;nodeID=node.id;self.node=node
        font=DocumentFonts.font(family:session.document?.template.font ?? DocumentTypography.defaultFont,size:13)
        super.init(frame:.zero)
        fieldEditor.isFieldEditor=true;fieldEditor.grid=self
        wantsLayer=true;layer?.cornerRadius=5;layer?.borderWidth=1
        heading.font = .systemFont(ofSize:11,weight:.semibold)
        heading.lineBreakMode = .byTruncatingTail
        heading.setContentCompressionResistancePriority(.defaultLow,for:.horizontal)
        heading.setContentHuggingPriority(.defaultLow,for:.horizontal)
        hint.font = .systemFont(ofSize:10);hint.textColor = .secondaryLabelColor
        let toolbar=NSStackView(views:[heading,button(L10n.text("+ Fila"),#selector(addRow)),button(L10n.text("− Fila"),#selector(removeRow)),button(L10n.text("+ Col."),#selector(addColumn)),button(L10n.text("− Col."),#selector(removeColumn)),button(L10n.text("Listo"),#selector(closeEditor))])
        toolbar.spacing=5;toolbar.edgeInsets=NSEdgeInsets(top:5,left:7,bottom:5,right:7)
        toolbar.setHuggingPriority(.required,for:.vertical)
        table.delegate=self;table.dataSource=self;table.headerView=NSTableHeaderView();table.rowHeight=32
        table.gridStyleMask=[.solidHorizontalGridLineMask,.solidVerticalGridLineMask]
        table.intercellSpacing=NSSize(width:1,height:1);table.selectionHighlightStyle = .none
        table.columnAutoresizingStyle = .noColumnAutoresizing;table.allowsColumnReordering=false
        scroll.documentView=table;scroll.hasVerticalScroller=true;scroll.hasHorizontalScroller=true;scroll.autohidesScrollers=true
        let stack=NSStackView(views:[toolbar,scroll,hint]);stack.orientation = .vertical;stack.alignment = .leading;stack.spacing=0
        addSubview(stack);stack.translatesAutoresizingMaskIntoConstraints=false;scroll.translatesAutoresizingMaskIntoConstraints=false
        NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo:leadingAnchor),stack.trailingAnchor.constraint(equalTo:trailingAnchor),stack.topAnchor.constraint(equalTo:topAnchor),stack.bottomAnchor.constraint(equalTo:bottomAnchor),scroll.widthAnchor.constraint(equalTo:stack.widthAnchor),toolbar.widthAnchor.constraint(equalTo:stack.widthAnchor),scroll.heightAnchor.constraint(greaterThanOrEqualToConstant:100)])
        rebuildColumns();updateHeading();updateColors()
    }
    required init?(coder:NSCoder) {fatalError(L10n.text("init(coder:) has not been implemented"))}
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateColors()
    }
    override func viewDidMoveToWindow() {super.viewDidMoveToWindow();updateColors()}
    private func updateColors() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor=NSColor.controlBackgroundColor.cgColor
            layer?.borderColor=NSColor.separatorColor.cgColor
        }
    }
    override var acceptsFirstResponder:Bool {true}
    override func layout() {
        super.layout()
        if abs(bounds.width-lastWidth)>1 {lastWidth=bounds.width;for column in table.tableColumns {column.width=max(100,min(240,(bounds.width-20)/Double(max(1,node.columnIDs.count))))}}
    }
    private func button(_ title:String,_ action:Selector)->NSButton {
        let button=NSButton(title:title,target:self,action:action);button.bezelStyle = .rounded;button.controlSize = .small;button.font = .systemFont(ofSize:11);return button
    }
    private func updateHeading() {heading.stringValue=L10n.format("Tabla %@ · %@ × %@",session?.document?.number(of:nodeID) ?? 0,node.rows.count,node.columnIDs.count)}
    private func rebuildColumns() {
        for column in table.tableColumns {table.removeTableColumn(column)}
        for (index,id) in node.columnIDs.enumerated() {
            let column=NSTableColumn(identifier:NSUserInterfaceItemIdentifier(id.uuidString))
            column.title=L10n.format("Columna %@",index+1);column.width=max(100,min(180,(bounds.width-20)/Double(max(1,node.columnIDs.count))))
            column.minWidth=80;column.maxWidth=400;table.addTableColumn(column)
        }
        table.reloadData()
    }
    func sync(_ updated:AcademicNode) {
        updating=true;defer{updating=false}
        let structureChanged=updated.rowIDs != node.rowIDs || updated.columnIDs != node.columnIDs
        node=updated;updateHeading()
        if structureChanged {rebuildColumns();return}
        let visible=table.rows(in:table.visibleRect)
        guard visible.location != NSNotFound else{return}
        for r in visible.location..<min(node.rows.count,NSMaxRange(visible)) {
            for c in node.columnIDs.indices {
                if let field=table.view(atColumn:c,row:r,makeIfNecessary:false) as? TableCellField,field.stringValue != node.rows[r][c] {
                    field.stringValue=node.rows[r][c]
                    if let editor=field.currentEditor() {editor.string=node.rows[r][c]}
                }
            }
        }
    }
    func numberOfRows(in tableView:NSTableView)->Int {node.rows.count}
    func tableView(_ tableView:NSTableView,heightOfRow row:Int)->CGFloat {
        guard row<node.rows.count else{return 32}
        return min(130,max(32,node.rows[row].enumerated().map {index,value in
            let width=max(30,(table.tableColumns.indices.contains(index) ? table.tableColumns[index].width : 120)-12)
            return ceil((value as NSString).boundingRect(with:NSSize(width:width,height:2000),options:[.usesLineFragmentOrigin,.usesFontLeading],attributes:[.font:font]).height)+12
        }.max() ?? 32))
    }
    func tableView(_ tableView:NSTableView,viewFor tableColumn:NSTableColumn?,row:Int)->NSView? {
        guard let tableColumn,let c=node.columnIDs.firstIndex(where:{$0.uuidString==tableColumn.identifier.rawValue}),row<node.rows.count else{return nil}
        let identifier=NSUserInterfaceItemIdentifier("NaberiusTableCell")
        let field=(tableView.makeView(withIdentifier:identifier,owner:self) as? TableCellField) ?? TableCellField()
        if !(field.cell is TableFieldCell) {let cell=TableFieldCell(textCell:"");cell.grid=self;field.cell=cell}
        field.identifier=identifier;field.rowID=node.rowIDs[row];field.columnID=node.columnIDs[c]
        field.delegate=self;field.isEditable=true;field.isSelectable=true;field.isBordered=false;field.drawsBackground=false
        field.cell?.wraps=true;field.cell?.isScrollable=false;field.maximumNumberOfLines=0;field.lineBreakMode = .byWordWrapping
        field.font=node.header && row==0 ? NSFontManager.shared.convert(font,toHaveTrait:.boldFontMask) : font
        field.stringValue=node.rows[row][c];field.setAccessibilityLabel(L10n.format("Fila %@, columna %@",row+1,c+1))
        return field
    }
    func controlTextDidBeginEditing(_ notification:Notification) {(notification.object as? TableCellField)?.registeredEdit=false}
    func controlTextDidChange(_ notification:Notification) {
        guard !updating,let field=notification.object as? TableCellField,let session,let r=node.rowIDs.firstIndex(where:{$0==field.rowID}),let c=node.columnIDs.firstIndex(where:{$0==field.columnID}) else{return}
        let text=field.stringValue
        session.mutate(L10n.text("Editar celda"),registerUndo:!field.registeredEdit) {document in
            guard let i=document.nodes.firstIndex(where:{$0.id==nodeID}),r<document.nodes[i].rows.count,c<document.nodes[i].rows[r].count else{return}
            document.nodes[i].rows[r][c]=text
        }
        field.registeredEdit=true
        table.noteHeightOfRows(withIndexesChanged:IndexSet(integer:r))
    }
    func control(_ control:NSControl,textView:NSTextView,doCommandBy commandSelector:Selector)->Bool {
        guard let field=control as? TableCellField,let r=node.rowIDs.firstIndex(where:{$0==field.rowID}),let c=node.columnIDs.firstIndex(where:{$0==field.columnID}) else{return false}
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {closeEditor();return true}
        let forward=commandSelector == #selector(NSResponder.insertTab(_:))
        let backward=commandSelector == #selector(NSResponder.insertBacktab(_:))
        let nextRow=commandSelector == #selector(NSResponder.insertNewline(_:))
        guard forward || backward || nextRow else{return false}
        var row=r,column=c
        if nextRow {row += 1} else if forward {column += 1;if column==node.columnIDs.count {column=0;row += 1}}
        else {column -= 1;if column<0 {column=node.columnIDs.count-1;row -= 1}}
        if row<0 {closeEditor();return true}
        if row>=node.rows.count {
            guard node.rows.count<200 else{closeEditor();return true}
            addRow()
        }
        focus(row:min(row,node.rows.count-1),column:column)
        return true
    }
    func focus(row:Int=0,column:Int=0) {
        guard node.rows.indices.contains(row),node.columnIDs.indices.contains(column) else{return}
        table.scrollRowToVisible(row);table.scrollColumnToVisible(column)
        if let field=table.view(atColumn:column,row:row,makeIfNecessary:true) as? TableCellField {window?.makeFirstResponder(field);field.selectText(nil)}
    }
    /// Validate against the live document before committing dimensions, content and IDs.
    @discardableResult func pasteCells(from pasteboard:NSPasteboard,at field:TableCellField)->Bool {
        let tsv=NSPasteboard.PasteboardType("public.utf8-tab-separated-values-text")
        guard let text=pasteboard.string(forType:tsv) ?? pasteboard.string(forType:.string),
              text.contains("\t") || text.contains("\n") || text.contains("\r"),
              let session,let current=session.document?.nodes.first(where:{$0.id==nodeID}),
              let row=current.rowIDs.firstIndex(where:{$0==field.rowID}),
              let column=current.columnIDs.firstIndex(where:{$0==field.columnID}) else{return false}
        do {
            let cells=try TablePaste.parse(text)
            guard cells.count>1 || (cells.first?.count ?? 0)>1 else{return false}
            let updated=try TablePaste.applying(cells,to:current,row:row,column:column)
            window?.makeFirstResponder(self)
            session.mutate(L10n.text("Pegar celdas")) {document in
                if let index=document.nodes.firstIndex(where:{$0.id==nodeID}) {document.nodes[index]=updated}
            }
            sync(updated);table.noteHeightOfRows(withIndexesChanged:IndexSet(integersIn:row..<row+cells.count))
            focus(row:row,column:column)
        } catch {session.error=error.localizedDescription}
        return true
    }
    private func change(_ title:String,_ body:(inout AcademicNode)->Void) {
        guard let session else{return}
        window?.makeFirstResponder(self)
        session.mutate(title) {document in if let i=document.nodes.firstIndex(where:{$0.id==nodeID}) {body(&document.nodes[i]);document.nodes[i].normalizeTableIdentity()}}
        if let updated=session.document?.nodes.first(where:{$0.id==nodeID}) {sync(updated)}
    }
    @objc private func addRow() {change(L10n.text("Añadir fila")) {if $0.rows.count<200 {$0.rows.append(Array(repeating:"",count:$0.columnIDs.count))}}}
    @objc private func removeRow() {change(L10n.text("Quitar fila")) {if $0.rows.count>1 {$0.rows.removeLast()}}}
    @objc private func addColumn() {change(L10n.text("Añadir columna")) {if $0.columnIDs.count<TablePaste.maximumColumns {$0.rows=$0.rows.map{$0+[""]}}}}
    @objc private func removeColumn() {change(L10n.text("Quitar columna")) {if $0.columnIDs.count>1 {$0.rows=$0.rows.map{Array($0.dropLast())}}}}
    @objc private func closeEditor() {owner?.finishTableEditing()}
}
