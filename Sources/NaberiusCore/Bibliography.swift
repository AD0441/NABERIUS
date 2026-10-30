import Foundation
import JavaScriptCore

public struct CitationOutput: Sendable {
    public var citations: [UUID:String] = [:]
    public var bibliography: [String] = []
    public init() {}
}
public enum Bibliography {
    public static func render(_ document: NabDocument) throws -> CitationOutput {
        try Task.checkCancellation()
        if document.references.isEmpty { return CitationOutput() }
        guard let context = JSContext(), let jsURL = Bundle.module.url(forResource:"citeproc",withExtension:"js",subdirectory:"Resources"), let styleURL = Bundle.module.url(forResource:document.metadata.citationStyle.file,withExtension:"csl",subdirectory:"Resources/CSL") else { throw NabError.invalid(L10n.text("No se encontró el motor o estilo bibliográfico.")) }
        var jsError: String?
        context.exceptionHandler = { _, error in jsError = error?.toString() }
        context.evaluateScript(try String(contentsOf:jsURL,encoding:.utf8))
        let style = try String(contentsOf:styleURL,encoding:.utf8)
        var locales: [String:String] = [:]
        for lang in ["es-ES","en-US"] {
            if let u = Bundle.module.url(forResource:"locales-"+lang,withExtension:"xml",subdirectory:"Resources/CSL") { locales[lang] = try String(contentsOf:u,encoding:.utf8) }
        }
        context.setObject(style,forKeyedSubscript:"nabStyle" as NSString)
        context.setObject(locales,forKeyedSubscript:"nabLocales" as NSString)
        context.setObject(Dictionary(uniqueKeysWithValues:document.references.map { ($0.id.uuidString,$0.csl) }),forKeyedSubscript:"nabItems" as NSString)
        context.setObject(document.metadata.language,forKeyedSubscript:"nabLanguage" as NSString)
        context.evaluateScript("var nabSys={retrieveLocale:function(lang){return nabLocales[lang]||nabLocales['en-US'];}, retrieveItem:function(id){return nabItems[id];}}; var nabEngine=new CSL.Engine(nabSys,nabStyle,nabLanguage); nabEngine.setOutputFormat('text');")
        let nodes = document.orderedNodes.filter { $0.kind == .citation }
        var cited: [String] = []
        for n in nodes { for id in n.referenceIDs where !cited.contains(id.uuidString) && document.references.contains(where:{$0.id==id}) { cited.append(id.uuidString) } }
        context.setObject(cited,forKeyedSubscript:"nabIDs" as NSString)
        context.evaluateScript("nabEngine.updateItems(nabIDs);")
        var output = CitationOutput()
        for n in nodes {
            try Task.checkCancellation()
            let refs = n.referenceIDs.filter { id in document.references.contains { $0.id == id } }
            if refs.isEmpty { output.citations[n.id] = "[Referencia no encontrada]"; continue }
            let items: [[String:Any]] = refs.map { id in
                var item: [String:Any] = ["id":id.uuidString]
                if !n.locator.isEmpty { item["locator"] = n.locator; item["label"] = "page" }
                if n.narrative { item["suppress-author"] = true }
                return item
            }
            context.setObject(items,forKeyedSubscript:"nabCluster" as NSString)
            var label = context.evaluateScript("nabEngine.makeCitationCluster(nabCluster)")?.toString() ?? "[Cita]"
            if n.narrative {
                let author = refs.compactMap { id in document.references.first(where:{$0.id==id})?.authors.components(separatedBy:";").first?.components(separatedBy:",").first }.joined(separator:"; ")
                label = author + " " + label
            }
            output.citations[n.id] = n.prefix + (n.prefix.isEmpty ? "" : " ") + label + (n.suffix.isEmpty ? "" : " ") + n.suffix
        }
        if let entries = context.evaluateScript("(nabEngine.makeBibliography()||[{},[]])[1]")?.toArray() as? [String] { output.bibliography = entries.map { $0.trimmingCharacters(in:.whitespacesAndNewlines) } }
        if let jsError { throw NabError.invalid(L10n.format("El motor bibliográfico no pudo procesar los registros: %@",jsError)) }
        return output
    }
    public static func cslJSON(_ references:[Reference])throws->Data {
        let items=try references.map {reference->[String:Any] in
            var item=reference.csl
            if let imported=reference.imported {
                var custom=item["custom"] as? [String:Any] ?? [:]
                if let value=item["custom"],!(value is [String:Any]) {custom["source-custom"]=value}
                custom["naberius-import"]=try JSONSerialization.jsonObject(with:JSONEncoder().encode(imported))
                item["custom"]=custom
            }
            return item
        }
        return try JSONSerialization.data(withJSONObject:items,options:[.prettyPrinted,.sortedKeys])
    }
    public static func bibTeX(_ references:[Reference])->String {
        var used=Set<String>()
        return references.map {reference in
            let imported=reference.imported
            let original=imported?.format=="BibTeX/BibLaTeX"
            var fields=original ? imported!.fields : [:]
            // Inheritance is flattened, so export does not require unselected parent records.
            fields.removeValue(forKey:"crossref");fields.removeValue(forKey:"xdata")
            func update(_ field:String,_ property:String,_ value:String) {
                if original && imported?.snapshot[property]==value {return}
                if value.isEmpty {fields.removeValue(forKey:field)} else {fields[field]=LaTeX.escape(value)}
            }
            update("title","title",reference.title)
            update("author","authors",reference.authors.replacingOccurrences(of:";",with:" and "))
            // The snapshot uses semicolons; preserve original structured author syntax when unchanged.
            if original && imported?.snapshot["authors"]==reference.authors,let author=imported?.fields["author"] {fields["author"]=author}
            if original && imported?.snapshot["year"] != reference.year {fields.removeValue(forKey:"date");fields.removeValue(forKey:"month")}
            update("year","year",reference.year)
            if original && imported?.snapshot["publisher"] != reference.publisher {for key in ["institution","school"] {fields.removeValue(forKey:key)}}
            if original && imported?.snapshot["container"] != reference.container {for key in ["journal","journaltitle","booktitle"] {fields.removeValue(forKey:key)}}
            if original && imported?.snapshot["issue"] != reference.issue {fields.removeValue(forKey:"issue")}
            let container=fields["journaltitle"] != nil ? "journaltitle" : (fields["booktitle"] != nil ? "booktitle" : "journal")
            update(container,"container",reference.container)
            for (field,property,value) in [("publisher","publisher",reference.publisher),("volume","volume",reference.volume),("number","issue",reference.issue),("pages","pages",reference.pages),("doi","doi",reference.doi),("url","url",reference.url)] {update(field,property,value)}
            let types=["book":"book","chapter":"incollection","paper-conference":"inproceedings","thesis":"phdthesis","report":"techreport","webpage":"online","manuscript":"unpublished","article-journal":"article"]
            let kind=original && imported?.snapshot["type"]==reference.type ? imported!.entryType : (types[reference.type] ?? "misc")
            var key=imported?.key ?? ""
            if key.isEmpty || key.range(of:#"^[A-Za-z0-9_:.+/-]+$"#,options:.regularExpression)==nil {key="ref"+reference.id.uuidString.replacingOccurrences(of:"-",with:"")}
            if used.contains(key) {key += "_"+reference.id.uuidString.prefix(8)}
            used.insert(key)
            let body=fields.keys.sorted().map {"  \($0) = {\(fields[$0]!)}"}.joined(separator:",\n")
            return "@\(kind){\(key),\n\(body)\n}"
        }.joined(separator:"\n\n")
    }
    public static func importCSL(_ data:Data)throws->[Reference] {try BibliographyImporter.cslJSON(data).references}
    public static func importRIS(_ text: String) throws -> [Reference] {
        var result: [Reference] = []; var r = Reference(); var active = false
        for line in text.components(separatedBy:.newlines) {
            guard line.count >= 6 else { continue }; let key = String(line.prefix(2)); let value = String(line.dropFirst(6)).trimmingCharacters(in:.whitespaces)
            switch key {
            case "TY": r = Reference(); active = true; r.type = value == "BOOK" ? "book" : "article-journal"
            case "TI","T1": r.title = value
            case "AU","A1": r.authors += (r.authors.isEmpty ? "" : "; ")+value
            case "PY","Y1": r.year = String(value.prefix(4))
            case "JO","JF","T2": r.container = value
            case "PB": r.publisher = value
            case "DO": r.doi = value
            case "UR": r.url = value
            case "VL": r.volume = value
            case "IS": r.issue = value
            case "SP": r.pages = value
            case "EP": r.pages += "–"+value
            case "ER": if active { result.append(r) }; active = false
            default: break
            }
        }
        guard !result.isEmpty else { throw NabError.invalid(L10n.text("No se encontraron registros RIS completos (TY / ER).")) }; return result
    }
    public static func importBibTeX(_ text:String)throws->[Reference] {try BibliographyImporter.bibTeX(text).references}
}
