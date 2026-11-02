import Foundation
import Testing
@testable import NaberiusCore

struct TablePasteTests {
    @Test func `spreadsheet quotes preserve embedded separators Unicode and empty cells`()throws {
        let text="Nombre\tNota\t\r\n\"Pérez, Ana\"\t\"Línea 1\r\nLínea 2\"\t\"α\tβ \"\"cita\"\" 🧪\"\r\n"
        #expect(try TablePaste.parse(text)==[["Nombre","Nota",""],["Pérez, Ana","Línea 1\nLínea 2","α\tβ \"cita\" 🧪"]])
    }
    @Test(arguments:[("a\tb\n\n",[["a","b"],["",""]]),("a\tb\nc",[["a","b"],["c",""]]),("\t",[["",""]]),("",[[""]])])
    func `ragged ranges are padded and only the final row terminator is ignored`(_ text:String,_ expected:[[String]])throws {
        #expect(try TablePaste.parse(text)==expected)
    }
    @Test(arguments:["\"sin cerrar\tb","\"cerrada\"texto\tb",String(repeating:"x\t",count:30),String(repeating:"x\n",count:201)])
    func `malformed and oversized ranges are rejected without truncation`(_ text:String) {
        #expect(throws:(any Error).self){try TablePaste.parse(text)}
    }
    @Test func `expansion preserves existing cells semantic identifiers and source value`()throws {
        var original=AcademicNode(.table);original.rows=[["A","B"],["C","D"]];original.normalizeTableIdentity()
        let result=try TablePaste.applying([["1","2"],["3","4"]],to:original,row:1,column:1)
        #expect(result.rows==[["A","B",""],["C","1","2"],["","3","4"]])
        #expect(result.id==original.id);#expect(Array(result.rowIDs.prefix(2))==original.rowIDs)
        #expect(Array(result.columnIDs.prefix(2))==original.columnIDs)
        #expect(original.rows==[["A","B"],["C","D"]])
        var document=NabDocument();document.insert(result)
        #expect(try NabArchive.decode(NabArchive.encode(document)).nodes==document.nodes)
    }
    @Test func `overflow and invalid destinations reject the whole paste`()throws {
        var original=AcademicNode(.table);original.rows=Array(repeating:Array(repeating:"old",count:30),count:200);original.normalizeTableIdentity()
        #expect(throws:(any Error).self){try TablePaste.applying([["1","2"]],to:original,row:199,column:29)}
        #expect(throws:(any Error).self){try TablePaste.applying([["1"],["2"]],to:original,row:199,column:0)}
        #expect(throws:(any Error).self){try TablePaste.applying([["1"]],to:original,row:-1,column:0)}
        #expect(original.rows[199][29]=="old")
    }
}
