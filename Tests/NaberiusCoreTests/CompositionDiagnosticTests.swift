import Testing
@testable import NaberiusCore

struct CompositionDiagnosticTests {
    @Test func `a missing editorial class names the resource and recovery actions`() {
        let summary=Composer.failureSummary(log:"! LaTeX Error: File `independent-journal.cls' not found.",allowNetwork:true)
        #expect(summary.contains("independent-journal.cls"));#expect(summary.contains("recursos"));#expect(summary.contains("libre"))
    }
    @Test func `offline missing fonts explain preparation without mislabeling syntax failures`() {
        let font="Font OT1/cmr/bx/n/9.8=cmbx9 at 9.8pt not loadable: Metric (TFM) file or installed font not found"
        let missing=Composer.failureSummary(log:font,allowNetwork:false)
        #expect(missing.contains("fuentes"));#expect(missing.contains("Configuración"))
        #expect(Composer.failureSummary(log:"Undefined control sequence",allowNetwork:false).contains("caché") == false)
        #expect(Composer.failureSummary(log:font,allowNetwork:true).contains("caché") == false)
    }
}
