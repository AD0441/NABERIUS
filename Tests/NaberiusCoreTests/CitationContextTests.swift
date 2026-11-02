import Foundation
import Testing
@testable import NaberiusCore

struct CitationContextTests {
    private func document(authors:String,style:CitationStyle = .apa)->NabDocument {
        var document=NabDocument();document.metadata.language="es-ES";document.metadata.citationStyle=style
        var reference=Reference();reference.title="Manual de prueba";reference.authors=authors;reference.year="2024"
        document.references=[reference]
        var citation=AcademicNode(.citation);citation.referenceIDs=[reference.id];citation.narrative=true
        document.insert(citation)
        return document
    }
    private func citation(_ document:NabDocument)throws->String {
        let node=try #require(document.orderedNodes.first)
        return try #require(Bibliography.render(document).citations[node.id]).replacingOccurrences(of:"\u{00a0}",with:" ")
    }
    @Test(arguments:CitationStyle.allCases)
    func `narrative names come from CSL for multiple authors and institutions`(_ style:CitationStyle)throws {
        let multiple=try citation(document(authors:"Pérez, Ana; Gómez, Luis; Rojas, Eva",style:style))
        #expect(multiple.hasPrefix("Pérez et al. "))
        #expect(!multiple.contains("NO_PRINTED_FORM"))
        let organization=try citation(document(authors:"Instituto de Investigación del Sur",style:style))
        #expect(organization.hasPrefix("Instituto de Investigación del Sur "))
        let missing=try citation(document(authors:"",style:style))
        #expect(missing.contains("Manual de prueba"))
        #expect(!missing.contains("NO_PRINTED_FORM"))
    }
    @Test func `APA narrative uses a conjunction while parenthetical retains the ampersand`()throws {
        var d=document(authors:"Pérez, Ana; Gómez, Luis")
        #expect(try citation(d)=="Pérez y Gómez (2024)")
        d.nodes[0].narrative=false
        #expect(try citation(d)=="(Pérez & Gómez, 2024)")
    }
    @Test func `later citations update earlier year suffixes without losing affixes or locators`()throws {
        var d=document(authors:"Pérez, Ana")
        d.references[0].title="Primer estudio"
        d.nodes[0].prefix="Según";d.nodes[0].suffix="véase también";d.nodes[0].locator="12"
        var reference=d.references[0];reference.id=UUID();reference.title="Segundo estudio";d.references.append(reference)
        var next=AcademicNode(.citation);next.referenceIDs=[reference.id];d.insert(next)
        let result=try Bibliography.render(d)
        #expect(result.citations[d.nodes[0].id]=="Según Pérez (2024a, p. 12) véase también")
        #expect(result.citations[next.id]=="(Pérez, 2024b)")
        #expect(result.bibliography.count==2)
        let restored=try NabArchive.decode(NabArchive.encode(d))
        #expect(try Bibliography.render(restored).citations==result.citations)
    }
    @Test(arguments:[CitationStyle.ieee,.vancouver])
    func `numeric narrative preserves first appearance numbering and repeated references`(_ style:CitationStyle)throws {
        var d=document(authors:"Pérez, Ana",style:style)
        var other=d.references[0];other.id=UUID();other.authors="Gómez, Luis";d.references.append(other)
        var second=AcademicNode(.citation);second.referenceIDs=[other.id];d.insert(second)
        var repeated=d.nodes[0];repeated.id=UUID();d.insert(repeated)
        let result=try Bibliography.render(d)
        #expect(result.citations[d.nodes[0].id]==(style == .ieee ? "Pérez [1]" : "Pérez (1)"))
        #expect(result.citations[second.id]==(style == .ieee ? "[2]" : "(2)"))
        #expect(result.citations[repeated.id]==result.citations[d.nodes[0].id])
        #expect(result.bibliography.count==2)
    }
}
