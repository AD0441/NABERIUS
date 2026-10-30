import Foundation
import PDFKit
import Testing
@testable import NaberiusCore

@Suite(.serialized)
struct LongTableTests {
    @Test(.enabled(if:ProcessInfo.processInfo.environment["NABERIUS_COMPOSE"]=="1"),arguments:["article","report","book","letter"])
    func `long tables wrap and retain every row across real PDF pages`(_ kind:String) async throws {
        var document=NabDocument();document.template=try #require(DocumentTemplate.builtins.first{$0.effectiveLayout.documentClass.rawValue==kind})
        var table=AcademicNode(.table);table.caption="Tabla extensa de prueba";table.tableStyle="Cuadrícula"
        table.rows=[["Identificador","Contenido"]]+(1...90).map{["Fila \($0)","Contenido de la fila \($0), con varias palabras para comprobar el ajuste de las columnas."]}
        table.rows[2][1]=String(repeating:"abcdefghij",count:12)
        table.rows[90][0]="ULTIMA-FILA-90";table.normalizeTableIdentity();document.insert(table)
        let engine=try #require(Composer.detectedEngine())
        let result=try await Composer.compile(document,engine:engine,allowNetwork:true)
        let pdf=try #require(PDFDocument(url:result.pdf));#expect(pdf.pageCount>1)
        let content=(0..<pdf.pageCount).compactMap{pdf.page(at:$0)?.string}.joined(separator:"\n")
        #expect(content.contains("ULTIMA-FILA-90"));#expect(content.components(separatedBy:"Identificador").count>2)
        let log=try String(contentsOf:result.pdf.deletingLastPathComponent().appendingPathComponent("main.log"),encoding:.utf8)
        #expect(!log.contains("Overfull \\hbox"))
        print("LONGTABLE_PDF \(kind) \(pdf.pageCount) pages \(result.pdf.path)")
    }
}
