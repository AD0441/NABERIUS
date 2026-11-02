import AppKit
import Testing
import NaberiusCore
@testable import Naberius

@MainActor struct TableRangeTests {
    @Test func `range paste is one undo transaction and redo preserves expanded identities`()throws {
        _=NSApplication.shared
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:folder)}
        let session=Session(supportDirectory:folder);session.new()
        defer{session.autosaveForTestingCleanup()}
        var original=AcademicNode(.table);original.normalizeTableIdentity();session.mutate("Tabla"){$0.insert(original)}
        session.undo.removeAllActions()
        let owner=NativeTextView();owner.session=session
        let grid=InlineTableEditor(owner:owner,session:session,node:original)
        let field=TableCellField();field.rowID=original.rowIDs[1];field.columnID=original.columnIDs[1]
        let pasteboard=NSPasteboard.withUniqueName();defer{pasteboard.releaseGlobally()}
        pasteboard.setString("1\t2\n3\t4\n",forType:.string)
        #expect(grid.pasteCells(from:pasteboard,at:field))
        let expanded=try #require(session.document?.nodes.first)
        #expect(expanded.rows==[["Variable","Valor",""],["","1","2"],["","3","4"]])
        session.undo.undo();#expect(session.document?.nodes.first==original)
        session.undo.redo();#expect(session.document?.nodes.first==expanded)
        let cell=TableFieldCell(textCell:"");cell.grid=grid
        #expect(cell.fieldEditor(for:field) === grid.fieldEditor)
        #expect(grid.fieldEditor.field === field);#expect(grid.fieldEditor.isFieldEditor)
    }
    @Test func `plain single cell uses normal text paste and malformed ranges preserve document`()throws {
        _=NSApplication.shared
        let folder=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:folder)}
        let session=Session(supportDirectory:folder);session.new();defer{session.autosaveForTestingCleanup()}
        var original=AcademicNode(.table);original.normalizeTableIdentity();session.mutate("Tabla"){$0.insert(original)}
        let grid=InlineTableEditor(owner:NativeTextView(),session:session,node:original)
        let field=TableCellField();field.rowID=original.rowIDs[0];field.columnID=original.columnIDs[0]
        let pasteboard=NSPasteboard.withUniqueName();defer{pasteboard.releaseGlobally()}
        pasteboard.setString("Texto normal",forType:.string)
        #expect(!grid.pasteCells(from:pasteboard,at:field))
        pasteboard.clearContents();pasteboard.setString("\"sin cerrar\tvalor",forType:.string)
        #expect(grid.pasteCells(from:pasteboard,at:field));#expect(session.error != nil)
        #expect(session.document?.nodes.first==original)
    }
}
