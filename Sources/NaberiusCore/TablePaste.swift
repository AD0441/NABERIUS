import Foundation

/// Spreadsheet text is data: quoted tabs/newlines are preserved and never evaluated.
public enum TablePaste {
    public static let maximumRows=200
    public static let maximumColumns=30
    public static let maximumBytes=4*1024*1024

    public static func parse(_ text:String)throws->[[String]] {
        guard text.utf8.count<=maximumBytes else {throw NabError.invalid(L10n.text("El rango copiado supera 4 MB. Copia un rango más pequeño."))}
        let bytes=Array(text.utf8)
        var rows:[[String]]=[],row:[String]=[],field:[UInt8]=[]
        var quoted=false,closedQuote=false,atStart=true,endedRow=false,index=0
        func finishField()throws {
            guard row.count<maximumColumns else {throw NabError.invalid(L10n.text("El rango copiado supera 30 columnas."))}
            row.append(String(decoding:field,as:UTF8.self));field=[];closedQuote=false;atStart=true
        }
        func finishRow()throws {
            try finishField()
            guard rows.count<maximumRows else {throw NabError.invalid(L10n.text("El rango copiado supera 200 filas."))}
            rows.append(row);row=[];endedRow=true
        }
        while index<bytes.count {
            let byte=bytes[index];endedRow=false
            if quoted {
                if byte==34 {
                    if index+1<bytes.count && bytes[index+1]==34 {field.append(34);index += 1}
                    else {quoted=false;closedQuote=true}
                } else if byte==13 {
                    field.append(10);if index+1<bytes.count && bytes[index+1]==10 {index += 1}
                } else {field.append(byte)}
            } else if byte==9 {try finishField()}
            else if byte==10 || byte==13 {
                try finishRow();if byte==13 && index+1<bytes.count && bytes[index+1]==10 {index += 1}
            } else if byte==34 && atStart {quoted=true;atStart=false}
            else {
                guard !closedQuote else {throw NabError.invalid(L10n.text("El rango copiado tiene texto fuera de una celda entre comillas. Vuelve a copiarlo desde la hoja de cálculo."))}
                field.append(byte);atStart=false
            }
            index += 1
        }
        guard !quoted else {throw NabError.invalid(L10n.text("El rango copiado contiene una celda con comillas sin cerrar."))}
        if !endedRow {try finishRow()}
        let columns=rows.map(\.count).max() ?? 1
        return rows.map {$0+Array(repeating:"",count:columns-$0.count)}
    }

    /// Returns a complete value only after validation; callers can register one undo step.
    public static func applying(_ cells:[[String]],to node:AcademicNode,row:Int,column:Int)throws->AcademicNode {
        guard node.kind == .table,!node.rows.isEmpty,let width=node.rows.first?.count,width>0,
              node.rows.allSatisfy({$0.count==width}),node.rows.indices.contains(row),(0..<width).contains(column),
              !cells.isEmpty,let pastedWidth=cells.first?.count,pastedWidth>0,cells.allSatisfy({$0.count==pastedWidth}) else {
            throw NabError.invalid(L10n.text("No se pudo identificar un rango rectangular de celdas."))
        }
        guard node.rows.count<=maximumRows,width<=maximumColumns,
              cells.count<=maximumRows-row,pastedWidth<=maximumColumns-column else {
            throw NabError.invalid(L10n.text("El pegado excedería el límite de 200 filas o 30 columnas. Elige otra celda o copia un rango más pequeño."))
        }
        var result=node
        let columns=max(width,column+pastedWidth),rows=max(node.rows.count,row+cells.count)
        result.rows=result.rows.map {$0+Array(repeating:"",count:columns-width)}
        result.rows += Array(repeating:Array(repeating:"",count:columns),count:rows-result.rows.count)
        for r in cells.indices {for c in cells[r].indices {result.rows[row+r][column+c]=cells[r][c]}}
        result.normalizeTableIdentity()
        return result
    }
}
