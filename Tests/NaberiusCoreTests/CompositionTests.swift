import Foundation
import Testing
@testable import NaberiusCore
struct CompositionTests {
    @Test(.enabled(if:ProcessInfo.processInfo.environment["NABERIUS_COMPOSE"] == "1"))
    func `real LaTeX compilation produces a PDF without mutating source`()async throws{
        let engine=try #require(Composer.detectedEngine());var d=NabDocument.example
        var r=Reference();r.title="Synthetic study";r.authors="Pérez, Ana";r.year="2024";d.references=[r]
        var citation=AcademicNode(.citation);citation.referenceIDs=[r.id];d.insert(citation)
        var table=AcademicNode(.table);table.caption="Resultados sintéticos";table.rows=[["Variable","Valor"],["Muestra","12"]];d.insert(table)
        var equation=AcademicNode(.equation);equation.math.operation = .fraction;equation.math.first="α + β";d.insert(equation)
        let fixture=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Resources/Brand/icon-64.png")
        let asset=Asset(name:"figure.png",mediaType:"image/png",data:try Data(contentsOf:fixture));d.assets=[asset]
        var figure=AcademicNode(.figure);figure.assetID=asset.id;figure.caption="Figura de prueba";d.insert(figure)
        var xref=AcademicNode(.crossReference);xref.targetID=figure.id;d.insert(xref)
        var footnote=AcademicNode(.footnote);footnote.note="Nota sintética";d.insert(footnote);d.insert(AcademicNode(.contents))
        let original=d
        let result=try await Composer.compile(d,engine:engine,allowNetwork:true)
        #expect(FileManager.default.fileExists(atPath:result.pdf.path));let data=try Data(contentsOf:result.pdf);#expect(data.starts(with:Data("%PDF".utf8)));#expect(d==original)
        print("PDF_TEST_OUTPUT \(result.pdf.path)")
    }
}

@Suite(.serialized)
struct TemplateCompositionTests {
    @Test(.enabled(if:ProcessInfo.processInfo.environment["NABERIUS_COMPOSE"] == "1"),arguments:DocumentTemplate.builtins)
    func `all six templates compose actual LaTeX including letter and chapters`(_ template:DocumentTemplate) async throws {
        var d=NabDocument.example;d.template=template
        d.metadata.abstract="Prueba tipográfica de LaTeX: español, áéíóú y referencias."
        d.blocks.append(Block("LaTeX y TeX conservan su composición tipográfica."))
        d.blocks.append(Block("Datos complementarios",style:.appendix))
        d.insert(AcademicNode(.separator))
        var layout=d.template.effectiveLayout;layout.header="Prueba de LaTeX";layout.footer="Naberius";d.template.layout=layout
        if template.effectiveLayout.documentClass == .letter {
            var layout=template.effectiveLayout;layout.recipient="Comité académico";layout.opening="Estimado comité:";d.template.layout=layout
        }
        var table=AcademicNode(.table);table.caption="Resultados de prueba";table.tableStyle="Cuadrícula";d.insert(table)
        var equation=AcademicNode(.equation);equation.math.operation = .root;equation.math.first="α + β";d.insert(equation)
        let engine=try #require(Composer.detectedEngine()),original=d
        let result=try await Composer.compile(d,engine:engine,allowNetwork:true)
        #expect(try Data(contentsOf:result.pdf).starts(with:Data("%PDF".utf8)))
        #expect(d==original)
        #expect(result.engine==engine)
        try NabArchive.encode(d).write(to:result.pdf.deletingLastPathComponent().appendingPathComponent("sample.nab"))
        print("TEMPLATE_PDF \(template.id) \(result.pdf.path)")
    }
}
