import Foundation
import Testing
@testable import NaberiusCore

struct BibliographyImportTests {
    static let complex = #"""
    % Synthetic import fixture: no external data or executable commands.
    @string{journal = prefix # " of Examples"}
    @string(prefix = "Journal")
    @preamble{"Not executed"}
    @xdata{shared, publisher={Example Press}, location={Santiago}}
    @proceedings{parent, title={Collected Examples}, date={2024-03-12}, editor={Doe, Jane}}
    @inproceedings(child,
       title = {La {TeX}nica de {Garc\'ia} y \LaTeX{}},
       author = {{Research and Development Group} and de la Cruz, Jr, Juan and Ana P\'erez},
       journaltitle = journal,
       crossref = {parent}, xdata = {shared},
       url = {https://example.org/~author},
       usera = {Custom {protected} value}, pages={12--19},
       editor={Garc\'ia, Mar\'ia},
       howpublished={\custom{Original}}
    )
    """#
    @Test func `macros concatenation inheritance names and TeX accents produce structured CSL`() throws {
        let report=try BibliographyImporter.bibTeX(Self.complex)
        let r=try #require(report.references.first(where:{$0.imported?.key=="child"}))
        #expect(report.references.count==2)
        #expect(r.title=="La TeXnica de García y LaTeX")
        #expect(r.container=="Journal of Examples");#expect(r.publisher=="Example Press")
        #expect(r.year=="2024");#expect(r.pages=="12–19")
        #expect(r.url=="https://example.org/~author")
        let people=try #require(r.csl["author"] as? [[String:String]])
        #expect(people[0]["literal"]=="Research and Development Group")
        #expect(people[1]["suffix"]=="Jr");#expect(people[2]["family"]=="Pérez")
        #expect((r.csl["issued"] as? [String:[[Int]]])?["date-parts"]==[[2024,3,12]])
        #expect(report.issues.contains{$0.field=="usera"})
        #expect(report.issues.contains{$0.field=="preamble"})
        #expect(report.issues.contains{$0.message.contains("custom")})
    }
    @Test func `archive CSL and BibTeX exports preserve extra data after editing represented fields`() throws {
        let original=try #require(BibliographyImporter.bibTeX(Self.complex).references.first(where:{$0.imported?.key=="child"}))
        var d=NabDocument();d.references=[original]
        let decoded=try NabArchive.decode(NabArchive.encode(d))
        #expect(decoded.references==d.references)
        var edited=original;edited.title="Edited & reviewed";edited.year="2030";edited.authors="New, Author";edited.publisher="";edited.container=""
        let data=try Bibliography.cslJSON([edited])
        let restored=try #require(BibliographyImporter.cslJSON(data).references.first)
        #expect(restored.title==edited.title);#expect(restored.imported==original.imported)
        #expect((restored.csl["editor"] as? [[String:String]])?.first?["family"]=="García")
        let bib=Bibliography.bibTeX([restored])
        let again=try #require(BibliographyImporter.bibTeX(bib).references.first)
        #expect(again.title==edited.title);#expect(again.year=="2030")
        #expect(again.authors=="New, Author");#expect(again.publisher.isEmpty);#expect(again.container.isEmpty)
        #expect(again.imported?.fields["usera"]=="Custom {protected} value")
        #expect(!bib.contains("crossref ="));#expect(!bib.contains("xdata ="))
    }
    @Test func `unknown CSL fields corporate names suffixes and full dates survive export`() throws {
        let json=Data(#"[{"id":"sample","type":"book","title":"Example","author":[{"literal":"Example Institute"},{"family":"Doe","given":"John","suffix":"III"}],"issued":{"date-parts":[[2024,2,29]]},"ISBN":"0000000000","custom-extra":{"nested":true}}]"#.utf8)
        let first=try #require(BibliographyImporter.cslJSON(json).references.first)
        let second=try #require(BibliographyImporter.cslJSON(Bibliography.cslJSON([first])).references.first)
        #expect((second.csl["custom-extra"] as? [String:Bool])?["nested"]==true)
        #expect((second.csl["author"] as? [[String:String]])?[1]["suffix"]=="III")
        #expect((second.csl["issued"] as? [String:[[Int]]])?["date-parts"]==[[2024,2,29]])
    }
    @Test func `circular and missing definitions are bounded and reported`() throws {
        let report=try BibliographyImporter.bibTeX(#"@string{a=b} @string{b=a} @book{one,title=a,crossref={two}} @book{two,title={Second},crossref={one},note=unknown}"#)
        #expect(report.references.count==2)
        #expect(report.issues.contains{$0.message.contains("circular")})
        #expect(report.issues.contains{$0.message.contains("no definida")})
    }
    @Test(arguments:["@article{one,title={unclosed}","@string{x=}","@book(one,title=\"never)"])
    func `malformed input fails without importing partial records`(_ source:String) {
        #expect(throws:(any Error).self){try BibliographyImporter.bibTeX(source)}
    }
    @Test func `Latin one is explicit and preambles are never executed`() throws {
        let data=try #require("@book{x,title={Café},year=2024}".data(using:.isoLatin1))
        let report=try BibliographyImporter.read(data,fileExtension:"bib")
        #expect(report.references.first?.title=="Café")
        #expect(report.issues.contains{$0.field=="codificación"})
    }
}
