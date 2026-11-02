import Foundation
import Testing
@testable import NaberiusCore

struct DocumentTests {
    @Test func `archive round trip preserves content identifiers assets and cursor`() throws {
        var d=NabDocument.example
        var reference=Reference();reference.title="Synthetic research";reference.authors="Pérez, Ana";reference.year="2024";d.references=[reference]
        let asset=Asset(name:"sample.png",mediaType:"image/png",data:Data([1,2,3,4]));d.assets=[asset]
        var figure=AcademicNode(.figure);figure.assetID=asset.id;d.insert(figure)
        d.cursor=Cursor(location:42,length:8)
        let decoded=try NabArchive.decode(NabArchive.encode(d))
        #expect(decoded.blocks==d.blocks);#expect(decoded.nodes==d.nodes);#expect(decoded.assets==d.assets);#expect(decoded.references==d.references);#expect(decoded.cursor==d.cursor);#expect(decoded.template==d.template)
    }
    @Test func `truncated corrupt and oversized declarations are rejected`() throws {
        let data=try NabArchive.encode(.example)
        #expect(throws:(any Error).self){try NabArchive.decode(data.prefix(30))}
        var corrupt=data;corrupt[corrupt.count-1] ^= 0xff
        #expect(throws:(any Error).self){try NabArchive.decode(corrupt)}
        var huge=data;for i in 11..<19{huge[i]=255}
        #expect(throws:(any Error).self){try NabArchive.decode(huge)}
    }
    @Test func `moving figures renumbers references without changing destination`() {
        var d=NabDocument();let first=AcademicNode(.figure),second=AcademicNode(.figure),third=AcademicNode(.figure)
        d.insert(first);d.insert(second);d.insert(third)
        #expect(d.crossReference(first.id)=="Figura 1")
        d.blocks.swapAt(1,3)
        #expect(d.crossReference(first.id)=="Figura 3");#expect(d.crossReference(third.id)=="Figura 1")
        d.blocks.removeAll{$0.runs.contains{$0.nodeID==second.id}}
        #expect(d.crossReference(second.id).contains("Destino no encontrado"))
    }
    @Test func `template changes preserve semantic document`() throws {
        var d=NabDocument.example;let blocks=d.blocks,id=d.id
        d.template=DocumentTemplate.builtins[3];d.template.marginMM=32
        #expect(d.blocks==blocks);#expect(d.id==id);#expect(DocumentTemplate.builtins[3].marginMM==25)
        _=try NabArchive.decode(NabArchive.encode(d))
    }
    @Test func `atomic save detects conflicts and recovery remains intact`() async throws {
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true);defer{try? FileManager.default.removeItem(at:directory)}
        let url=directory.appendingPathComponent("doc.nab"),disk=DocumentDisk();let d=NabDocument.example
        let hash=try await disk.save(d,to:url,expected:nil)
        try await disk.recovery(d,directory:directory.appendingPathComponent("Recovery"))
        var external=d;external.metadata.title="External change";try NabArchive.encode(external).write(to:url,options:.atomic)
        await #expect(throws:NabError.conflict){try await disk.save(d,to:url,expected:hash)}
        let (read,_)=try await disk.read(url);#expect(read.metadata.title=="External change")
        let recover=try NabArchive.decode(Data(contentsOf:directory.appendingPathComponent("Recovery").appendingPathComponent(d.id.uuidString+".nab")));#expect(recover.blocks==d.blocks)
    }
    @Test func `portable project uses internal resource paths and escapes input`() throws {
        var d=NabDocument.example;d.blocks.append(Block("% unsafe \\input{/etc/passwd} & {text}"))
        let source=LaTeX.source(d)
        #expect(source.contains("\\textbackslash{}input"));#expect(!source.contains("\\input{/etc/passwd}"));#expect(source.contains("\\% unsafe"))
        var math=MathExpression();math.first="x \\write18{bad}";math.operation = .fraction
        #expect(!LaTeX.equation(math).contains("\\write18"))
    }
    @Test(arguments:[("café cafétería CAFÉ",true,2),("cat scatter Cat",false,3)])
    func `search whole words and case options`(_ text:String,_ whole:Bool,_ expected:Int){#expect(DocumentSearch.ranges(whole ? "café" : "cat",in:text,caseSensitive:false,wholeWord:whole).count==expected)}
    @Test func `replace respects Unicode and literal replacement syntax`() {
        let value=DocumentSearch.replacing("α café CAFÉ",query:"café",replacement:"$1 \\ x",caseSensitive:false,wholeWord:true)
        #expect(value=="α $1 \\ x $1 \\ x")
    }
    @Test func `large document serializes within a measurable budget`() throws {
        var d=NabDocument();d.blocks=(0..<3000).map{Block("Párrafo \($0). "+String(repeating:"Contenido de prueba para documentos extensos. ",count:8))}
        let start=ContinuousClock.now;let data=try NabArchive.encode(d);let decoded=try NabArchive.decode(data);let elapsed=start.duration(to:.now)
        #expect(decoded.blocks==d.blocks);#expect(elapsed < .seconds(10));#expect(data.count<2_000_000)
        print("BENCHMARK 3000 paragraphs, \(d.wordCount) words, \(data.count) bytes, \(elapsed)")
    }
}
struct BibliographyTests {
    func sample()->NabDocument{var d=NabDocument();var r=Reference();r.title="Synthetic study of writing";r.authors="Pérez, Ana";r.year="2024";r.container="Journal of Synthetic Examples";r.volume="2";r.pages="10–20";d.references=[r];var n=AcademicNode(.citation);n.referenceIDs=[r.id];d.insert(n);return d}
    @Test(arguments:CitationStyle.allCases) func `CSL generates real citations and bibliography`(_ style:CitationStyle)throws{var d=sample();d.metadata.citationStyle=style;let result=try Bibliography.render(d);let node=try #require(d.orderedNodes.first);let cite=try #require(result.citations[node.id]);#expect(!cite.isEmpty);#expect(!cite.contains("undefined"));#expect(!result.bibliography.isEmpty);#expect(result.bibliography.joined().contains("Synthetic study"));if style == .ieee{#expect(cite.contains("1"))};if style == .apa{#expect(cite.contains("2024"));#expect(cite.contains("Pérez"))}}
    @Test func `narrative parenthetical multiple and locator are linked to references`() throws{var d=sample();var second=d.references[0];second.id=UUID();second.authors="Gómez, Luis";second.year="2021";d.references.append(second);d.nodes[0].referenceIDs.append(second.id);d.nodes[0].locator="12";d.nodes[0].narrative=true;let r=try Bibliography.render(d);let cite=try #require(r.citations[d.nodes[0].id]);#expect(cite.contains("Pérez"));#expect(cite.contains("Gómez"));#expect(cite.contains("2024"));#expect(cite.contains("2021"));#expect(cite.contains("12"));#expect(r.bibliography.count==2)}
    @Test func `CSL JSON roundtrip preserves represented fields`() throws{let d=sample();let imported=try Bibliography.importCSL(Bibliography.cslJSON(d.references));#expect(imported[0].title==d.references[0].title);#expect(imported[0].authors==d.references[0].authors);#expect(imported[0].year=="2024")}
    @Test func `BibTeX parser handles nested fields`()throws{let refs=try Bibliography.importBibTeX("@article{perez, title={A {nested} title}, author={Pérez, Ana and Gómez, Luis}, year={2024}, journal={Examples}}")
        #expect(refs[0].title=="A nested title");#expect(refs[0].imported?.fields["title"]=="A {nested} title");#expect(refs[0].authors=="Pérez, Ana; Gómez, Luis")}
    @Test func `RIS parser preserves missing metadata`()throws{let refs=try Bibliography.importRIS("TY  - JOUR\nTI  - Example\nAU  - Pérez, Ana\nER  - \n");#expect(refs[0].year.isEmpty);#expect(refs[0].title=="Example")}
}
struct TemplateTests {
    @Test(arguments:[("\\documentclass{article}",true),("\\immediate\\write18{touch bad}",false),("\\input{../secret}",false)])
    func `template scanner diagnoses compatibility without execution`(_ source:String,_ compatible:Bool)throws{let url=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".tex");try source.write(to:url,atomically:true,encoding:.utf8);defer{try? FileManager.default.removeItem(at:url)};let result=try TemplateImporter.analyze(url);#expect(result.compatible==compatible)}
}
struct JournalTests {
    @Test func `journal recovers edits between snapshots and ignores a torn final transaction`()async throws{
        let directory=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer{try? FileManager.default.removeItem(at:directory)}
        let disk=DocumentDisk();var d=NabDocument.example;try await disk.journal(d,directory:directory)
        d.blocks[3].runs[0].text="Última edición persistida";d.modified=Date().addingTimeInterval(1);try await disk.journal(d,directory:directory)
        let url=directory.appendingPathComponent(d.id.uuidString+".nab")
        let journal=url.appendingPathExtension("journal");let handle=try FileHandle(forWritingTo:journal);try handle.seekToEnd();try handle.write(contentsOf:Data("{interrupted".utf8));try handle.close()
        let recovered=try await disk.readRecovery(url)
        #expect(recovered.blocks==d.blocks)
        try await disk.recovery(d,directory:directory)
        #expect(!FileManager.default.fileExists(atPath:journal.path))
        let (snapshot,_)=try await disk.read(url);#expect(snapshot.blocks==d.blocks)
    }
}
