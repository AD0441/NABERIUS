import Foundation

public struct ImportedReference:Codable,Equatable,Sendable {
    public var format:String
    public var entryType:String
    public var key:String
    public var fields:[String:String]
    public var original:String
    public var cslData:Data
    public var snapshot:[String:String]
    public var warnings:[String]
}
public struct BibliographyImportIssue:Identifiable,Sendable {
    public let id=UUID()
    public let key:String
    public let field:String
    public let message:String
}
public struct BibliographyImportReport:Sendable {
    public var references:[Reference]
    public var issues:[BibliographyImportIssue]
    public var format:String
    public var sourceName:String=""
}

public enum BibliographyImporter {
    public static func snapshot(_ r:Reference)->[String:String] {
        ["type":r.type,"title":r.title,"authors":r.authors,"year":r.year,"container":r.container,"publisher":r.publisher,"volume":r.volume,"issue":r.issue,"pages":r.pages,"doi":r.doi,"url":r.url]
    }
    public static func bibTeX(_ text:String)throws->BibliographyImportReport {
        guard text.utf8.count<=10*1024*1024 else{throw NabError.invalid(L10n.text("La bibliografía supera 10 MB."))}
        var parser=BibParser(text);let entries=try parser.parse()
        var issues=parser.issues
        let definitions=parser.definitions
        let eligible=entries.filter{$0.kind != "xdata"}
        guard !eligible.isEmpty else{throw NabError.invalid(L10n.text("No se encontraron registros bibliográficos."))}
        var byKey:[String:BibEntry]=[:]
        for entry in entries {
            if byKey[entry.key] != nil {issues.append(.init(key:entry.key,field:"",message:L10n.text("Clave repetida; se conservarán registros separados. La herencia usa la primera entrada.")))}
            else {byKey[entry.key]=entry}
        }
        var resolvedBytes=0
        func resolve(_ parts:[BibPart],key:String,field:String,visited:Set<String>=[])throws->String {
            let values=try parts.map {part in
                switch part {
                case .literal(let value):return value
                case .macro(let name):
                    let lower=name.lowercased()
                    guard !visited.contains(lower),visited.count<24 else{issues.append(.init(key:key,field:field,message:L10n.text("Abreviatura circular: ")+name+L10n.text(". Se conserva su nombre literal.")));return name}
                    if let value=definitions[lower] {return try resolve(value,key:key,field:field,visited:visited.union([lower]))}
                    let months=["jan":"January","feb":"February","mar":"March","apr":"April","may":"May","jun":"June","jul":"July","aug":"August","sep":"September","oct":"October","nov":"November","dec":"December"]
                    if let month=months[lower] {return month}
                    issues.append(.init(key:key,field:field,message:L10n.text("Abreviatura no definida: ")+name+L10n.text(". No se inventó su contenido.")));return name
                }
            }
            resolvedBytes += values.reduce(0){$0+$1.utf8.count}
            guard resolvedBytes<=20*1024*1024 else {throw NabError.invalid(L10n.text("Las abreviaturas bibliográficas expanden más de 20 MB. Divide el archivo antes de importar."))}
            return values.joined()
        }
        var expansionCount=0
        func expanded(_ entry:BibEntry,visited:Set<String>=[])throws->[String:String] {
            expansionCount += 1
            guard expansionCount<=100_000 else {throw NabError.invalid(L10n.text("La herencia bibliográfica es demasiado compleja. Divide el archivo antes de importar."))}
            var own=Dictionary(uniqueKeysWithValues:try entry.fields.map {name,parts in (name,try resolve(parts,key:entry.key,field:name))})
            guard !visited.contains(entry.key),visited.count<24 else{issues.append(.init(key:entry.key,field:"crossref",message:L10n.text("Herencia circular o demasiado profunda; no se aplicó.")));return own}
            let parents=(own["xdata"] ?? "").split(separator:",").map{String($0).trimmingCharacters(in:.whitespaces)}+([own["crossref"]].compactMap{$0})
            for parentKey in parents {
                guard let parent=byKey[parentKey] else{issues.append(.init(key:entry.key,field:"crossref",message:L10n.text("No se encontró la entrada heredada: ")+parentKey));continue}
                let values=try expanded(parent,visited:visited.union([entry.key]))
                for (name,value) in values where !["title","author","crossref","xdata"].contains(name) && own[name]==nil {own[name]=value}
                if own["booktitle"]==nil,let title=values["title"] {own["booktitle"]=title}
            }
            return own
        }
        var references:[Reference]=[]
        let supported:Set<String>=["title","author","year","date","journal","journaltitle","booktitle","publisher","institution","school","volume","number","issue","pages","doi","url","editor","translator","edition","isbn","issn","address","location","language","abstract","keywords","note","urldate","pagetotal","crossref","xdata","month","organization","eventtitle","eventdate"]
        let types=["article":"article-journal","book":"book","booklet":"book","inbook":"chapter","incollection":"chapter","inproceedings":"paper-conference","conference":"paper-conference","proceedings":"book","phdthesis":"thesis","mastersthesis":"thesis","thesis":"thesis","techreport":"report","report":"report","manual":"report","online":"webpage","www":"webpage","misc":"article","unpublished":"manuscript"]
        for entry in eligible {
            let fields=try expanded(entry)
            var unknown=Set<String>()
            for value in fields.values {_ = TeXMetadata.decode(value,unknown:&unknown)}
            func plain(_ key:String)->String {TeXMetadata.decode(fields[key] ?? "",unknown:&unknown,preserveTilde:["url","doi"].contains(key))}
            var r=Reference();r.type=types[entry.kind] ?? "article"
            r.title=plain("title");let authors=TeXMetadata.names(fields["author"] ?? "",unknown:&unknown)
            r.authors=authors.map {person in person["literal"] ?? [person["family"],person["given"]].compactMap{$0}.joined(separator:", ")}.joined(separator:"; ")
            var issued=date(fields["date"] ?? fields["year"] ?? "")
            if let month=fields["month"],let parts=issued?["date-parts"] as? [[Int]],parts.first?.count==1,fields["date"]==nil {
                let months=["january","february","march","april","may","june","july","august","september","october","november","december"]
                let number=Int(month) ?? months.firstIndex(of:month.lowercased()).map{$0+1}
                if let number,(1...12).contains(number) {issued=["date-parts":[[parts[0][0],number]]]}
                else {issues.append(.init(key:entry.key,field:"month",message:L10n.text("Mes no interpretado; se conserva el valor original.")))}
            }
            for key in ["date","urldate","eventdate"] where fields[key] != nil && date(fields[key]!)==nil {
                issues.append(.init(key:entry.key,field:key,message:L10n.text("Fecha no interpretada como año-mes-día; se conserva el valor original.")))
            }
            r.year=(issued?["date-parts"] as? [[Int]])?.first?.first.map(String.init) ?? plain("year")
            r.container=plain(fields["journaltitle"] != nil ? "journaltitle" : (fields["journal"] != nil ? "journal" : "booktitle"))
            r.publisher=plain(fields["publisher"] != nil ? "publisher" : (fields["institution"] != nil ? "institution" : "school"))
            r.volume=plain("volume");r.issue=plain(fields["number"] != nil ? "number" : "issue");r.pages=plain("pages").replacingOccurrences(of:"--",with:"–")
            r.doi=plain("doi");r.url=plain("url")
            var csl:[String:Any]=["type":r.type,"title":r.title,"author":authors]
            if let issued {csl["issued"]=issued}
            for (bib,key) in [("editor","editor"),("translator","translator")] where fields[bib] != nil {csl[key]=TeXMetadata.names(fields[bib]!,unknown:&unknown)}
            for (bib,key) in [("edition","edition"),("isbn","ISBN"),("issn","ISSN"),("location","publisher-place"),("address","publisher-place"),("language","language"),("abstract","abstract"),("keywords","keyword"),("note","note"),("pagetotal","number-of-pages"),("organization","authority"),("eventtitle","event-title")] where fields[bib] != nil {csl[key]=plain(bib)}
            if let value=fields["urldate"],let accessed=date(value) {csl["accessed"]=accessed}
            if let value=fields["eventdate"],let event=date(value) {csl["event-date"]=event}
            for name in fields.keys.sorted() where !supported.contains(name) {issues.append(.init(key:entry.key,field:name,message:L10n.text("Campo sin correspondencia CSL; se conserva en los datos originales y en BibTeX.")))}
            for name in unknown.sorted() {issues.append(.init(key:entry.key,field:"",message:L10n.text("Comando TeX no interpretado: ")+name+L10n.text(". El original se conserva y no se ejecuta.")))}
            if types[entry.kind]==nil {issues.append(.init(key:entry.key,field:"type",message:L10n.text("Tipo no representado en el formulario: ")+entry.kind+L10n.text(". Se conserva su tipo original.")))}
            if r.title.isEmpty {issues.append(.init(key:entry.key,field:"title",message:L10n.text("Falta el título; no se completó automáticamente.")))}
            let warnings=issues.filter{$0.key==entry.key}.map{($0.field.isEmpty ? "" : $0.field+": ")+$0.message}
            r.imported=ImportedReference(format:"BibTeX/BibLaTeX",entryType:entry.kind,key:entry.key,fields:fields,original:entry.original,cslData:try JSONSerialization.data(withJSONObject:csl,options:.sortedKeys),snapshot:snapshot(r),warnings:warnings)
            references.append(r)
        }
        return .init(references:references,issues:issues,format:"BibTeX/BibLaTeX")
    }
    static func date(_ value:String)->[String:Any]? {
        let dates=value.split(separator:"/",omittingEmptySubsequences:false).prefix(2).compactMap {part->[Int]? in
            let raw=part.split(separator:"-",omittingEmptySubsequences:false)
            let components=raw.compactMap{Int($0)}
            guard raw.count==components.count else{return nil}
            guard let year=components.first,(1...9999).contains(year),components.count<=3 else{return nil}
            if components.count>1 && !(1...12).contains(components[1]) {return nil}
            if components.count>2 && !(1...31).contains(components[2]) {return nil}
            return components
        }
        return dates.isEmpty ? nil : ["date-parts":dates]
    }
    public static func cslJSON(_ data:Data)throws->BibliographyImportReport {
        guard data.count<=10*1024*1024,let entries=try JSONSerialization.jsonObject(with:data) as? [[String:Any]],entries.count<=10_000 else{throw NabError.invalid(L10n.text("Se esperaba una lista CSL-JSON de menos de 10 MB."))}
        var result:[Reference]=[],issues:[BibliographyImportIssue]=[]
        for entry in entries {
            var r=Reference();r.type=entry["type"] as? String ?? "article";r.title=entry["title"] as? String ?? ""
            r.authors=(entry["author"] as? [[String:Any]] ?? []).map{person in person["literal"] as? String ?? [person["family"] as? String,person["given"] as? String].compactMap{$0}.joined(separator:", ")}.joined(separator:"; ")
            r.year=(entry["issued"] as? [String:Any])?["date-parts"].flatMap{$0 as? [[Int]]}?.first?.first.map(String.init) ?? ""
            r.container=entry["container-title"] as? String ?? "";r.publisher=entry["publisher"] as? String ?? "";r.volume=string(entry["volume"]);r.issue=string(entry["issue"]);r.pages=string(entry["page"]);r.doi=string(entry["DOI"]);r.url=string(entry["URL"])
            let key=string(entry["id"]),data=try JSONSerialization.data(withJSONObject:entry,options:.sortedKeys)
            if let custom=entry["custom"] as? [String:Any],let metadata=custom["naberius-import"],let restored=try? JSONDecoder().decode(ImportedReference.self,from:JSONSerialization.data(withJSONObject:metadata)) {r.imported=restored}
            else {r.imported=ImportedReference(format:"CSL-JSON",entryType:r.type,key:key,fields:[:],original:String(decoding:data,as:UTF8.self),cslData:data,snapshot:snapshot(r),warnings:[])}
            if r.title.isEmpty {issues.append(.init(key:key,field:"title",message:L10n.text("Falta el título; no se inventó.")))}
            result.append(r)
        }
        return .init(references:result,issues:issues,format:"CSL-JSON")
    }
    public static func read(_ data:Data,fileExtension:String)throws->BibliographyImportReport {
        guard data.count<=10*1024*1024 else{throw NabError.invalid(L10n.text("La bibliografía supera 10 MB."))}
        if fileExtension.lowercased()=="json" {return try cslJSON(data)}
        let utf8=String(data:data,encoding:.utf8)
        guard let text=utf8 ?? String(data:data,encoding:.isoLatin1) else{throw NabError.invalid(L10n.text("No se pudo leer la codificación del archivo."))}
        var report:BibliographyImportReport
        if fileExtension.lowercased()=="ris" {
            let references=try Bibliography.importRIS(text)
            var records:[String]=[],current:[String]=[]
            for line in text.components(separatedBy:.newlines) {
                if line.hasPrefix("TY  -") {current=[]}
                current.append(line)
                if line.hasPrefix("ER  -") {records.append(current.joined(separator:"\n"));current=[]}
            }
            var refs:[Reference]=[],issues:[BibliographyImportIssue]=[]
            for (index,reference) in references.enumerated() {
                var reference=reference
                let original=records.indices.contains(index) ? records[index] : ""
                var fields:[String:String]=[:]
                for line in original.components(separatedBy:.newlines) where line.count>=6 {
                    let tag=String(line.prefix(2)),value=String(line.dropFirst(6))
                    fields[tag]=(fields[tag].map{$0+"\n"} ?? "")+value
                }
                let supported:Set<String>=["TY","TI","T1","AU","A1","PY","Y1","JO","JF","T2","PB","DO","UR","VL","IS","SP","EP","ER"]
                let extra=fields.keys.filter{!supported.contains($0)}.sorted()
                let warning=L10n.text("Campo RIS sin correspondencia; se conserva en .nab y CSL-JSON, pero no en BibTeX.")
                for field in extra {issues.append(.init(key:"ris-\(index+1)",field:field,message:warning))}
                reference.imported=ImportedReference(format:"RIS",entryType:reference.type,key:"ris-\(index+1)",fields:fields,original:original,cslData:try JSONSerialization.data(withJSONObject:reference.csl),snapshot:snapshot(reference),warnings:extra.map{$0+": "+warning})
                refs.append(reference)
            }
            report = .init(references:refs,issues:issues,format:"RIS")
        } else {report=try bibTeX(text)}
        if utf8==nil {report.issues.insert(.init(key:"Archivo",field:"codificación",message:L10n.text("Se leyó como Latin-1 y se convirtió a Unicode.")),at:0)}
        return report
    }
    static func string(_ value:Any?)->String {if let s=value as? String{return s};if let n=value as? NSNumber{return n.stringValue};return ""}
}

private enum BibPart {case literal(String),macro(String)}
private struct BibEntry {let kind:String;let key:String;let fields:[String:[BibPart]];let original:String}
private struct BibParser {
    let bytes:[UInt8]
    var i=0
    var definitions:[String:[BibPart]]=[:]
    var issues:[BibliographyImportIssue]=[]
    init(_ text:String) {bytes=Array(text.utf8)}
    mutating func skip() {
        while i<bytes.count {
            if [9,10,13,32,44].contains(bytes[i]) {i += 1}
            else if bytes[i]==37 {while i<bytes.count && bytes[i] != 10 {i += 1}}
            else {break}
        }
    }
    mutating func identifier()->String {
        let start=i
        while i<bytes.count && ((65...90).contains(bytes[i]) || (97...122).contains(bytes[i]) || (48...57).contains(bytes[i]) || [45,95,58,46].contains(bytes[i])) {i += 1}
        return String(decoding:bytes[start..<i],as:UTF8.self)
    }
    mutating func value(close:UInt8)throws->[BibPart] {
        var parts:[BibPart]=[]
        while i<bytes.count {
            skip();guard i<bytes.count else{throw NabError.invalid(L10n.text("Valor BibTeX incompleto."))}
            let start=i
            if bytes[i]==123 || bytes[i]==34 {
                let quoted=bytes[i]==34;i += 1;let content=i;var depth=1
                while i<bytes.count {
                    let c=bytes[i]
                    if c==92 {i=min(bytes.count,i+2);continue}
                    if c==123 {depth += 1}
                    if c==125 {if !quoted {depth -= 1;if depth==0 {break}} else if depth>1 {depth -= 1}}
                    if quoted && c==34 && depth==1 {break}
                    i += 1
                }
                guard i<bytes.count else{throw NabError.invalid(L10n.text("Un campo BibTeX quedó sin cerrar."))}
                parts.append(.literal(String(decoding:bytes[content..<i],as:UTF8.self)));i += 1
            } else {
                while i<bytes.count && ![9,10,13,32,44,35,close].contains(bytes[i]) {i += 1}
                guard i>start else{throw NabError.invalid(L10n.text("Valor BibTeX no válido."))}
                let token=String(decoding:bytes[start..<i],as:UTF8.self)
                parts.append(token.allSatisfy(\.isNumber) ? .literal(token) : .macro(token))
            }
            while i<bytes.count && [9,10,13,32].contains(bytes[i]) {i += 1}
            if i<bytes.count && bytes[i]==35 {i += 1;continue}
            return parts
        }
        throw NabError.invalid(L10n.text("Valor BibTeX incompleto."))
    }
    mutating func parse()throws->[BibEntry] {
        var entries:[BibEntry]=[]
        while i<bytes.count {
            skip();guard i<bytes.count else{break}
            guard bytes[i]==64 else{i += 1;continue}
            let start=i;i += 1;let kind=identifier().lowercased();skip()
            guard i<bytes.count,[123,40].contains(bytes[i]) else{throw NabError.invalid(L10n.text("Entrada BibTeX sin apertura válida."))}
            let close:UInt8=bytes[i]==123 ? 125 : 41;i += 1
            if ["comment","preamble"].contains(kind) {
                var depth=1
                while i<bytes.count && depth>0 {if bytes[i]==92 {i=min(bytes.count,i+2);continue};if bytes[i]==close {depth -= 1};if bytes[i]==(close==125 ? 123 : 40) {depth += 1};i += 1}
                guard depth==0 else{throw NabError.invalid(L10n.text("Comentario o preámbulo sin cerrar."))}
                if kind=="preamble" {issues.append(.init(key:"Archivo",field:"preamble",message:L10n.text("Preámbulo omitido: no se ejecuta ni se incorpora a LaTeX. Conserva el archivo original si depende de él.")))}
                continue
            }
            if kind=="string" {
                skip();let name=identifier().lowercased();skip();guard i<bytes.count,bytes[i]==61 else{throw NabError.invalid(L10n.text("Definición @string no válida."))};i += 1
                definitions[name]=try value(close:close);skip();guard i<bytes.count,bytes[i]==close else{throw NabError.invalid(L10n.text("Definición @string incompleta."))};i += 1;continue
            }
            let keyStart=i;while i<bytes.count && bytes[i] != 44 && bytes[i] != close {i += 1}
            let key=String(decoding:bytes[keyStart..<i],as:UTF8.self).trimmingCharacters(in:.whitespacesAndNewlines)
            var fields:[String:[BibPart]]=[:];var closed=false
            while i<bytes.count {
                skip();if i<bytes.count && bytes[i]==close {i += 1;closed=true;break}
                let field=identifier().lowercased();skip();guard !field.isEmpty,i<bytes.count,bytes[i]==61 else{throw NabError.invalid(L10n.text("Campo BibTeX inválido en ")+key)};i += 1
                if fields[field] != nil {issues.append(.init(key:key,field:field,message:L10n.text("Campo repetido: se utiliza el último valor y se conserva la entrada original.")))}
                fields[field]=try value(close:close)
            }
            guard closed else{throw NabError.invalid(L10n.text("Entrada BibTeX incompleta: ")+key)}
            entries.append(.init(kind:kind,key:key,fields:fields,original:String(decoding:bytes[start..<i],as:UTF8.self)))
            guard entries.count<=10_000 else{throw NabError.invalid(L10n.text("La bibliografía supera 10.000 entradas."))}
        }
        return entries
    }
}

enum TeXMetadata {
    static func decode(_ value:String,unknown:inout Set<String>,preserveTilde:Bool=false)->String {
        let chars=Array(value);var i=0
        let replacements=["LaTeX":"LaTeX","TeX":"TeX","textendash":"–","textemdash":"—","textasciitilde":"~","textbackslash":"\\","ae":"æ","AE":"Æ","oe":"œ","OE":"Œ","ss":"ß","o":"ø","O":"Ø","l":"ł","L":"Ł","i":"ı","j":"ȷ"]
        let accents:[Character:String]=["'":"\u{0301}","\"":"\u{0308}","`":"\u{0300}","^":"\u{0302}","~":"\u{0303}","=":"\u{0304}",".":"\u{0307}","u":"\u{0306}","v":"\u{030C}","H":"\u{030B}","c":"\u{0327}","k":"\u{0328}","b":"\u{0331}","d":"\u{0323}","r":"\u{030A}"]
        let wrappers:Set<String>=["emph","textit","textbf","textsc","textrm","textnormal","mbox","url"]
        var output=""
        while i<chars.count {
            let c=chars[i];i += 1
            if c=="{" || c=="}" {continue}
            if c=="~" {output.append(preserveTilde ? "~" : " ");continue}
            guard c=="\\",i<chars.count else{output.append(c);continue}
            let next=chars[i]
            if let accent=accents[next],(!next.isLetter || i+1==chars.count || !chars[i+1].isLetter) {
                i += 1;while i<chars.count && (chars[i].isWhitespace || chars[i]=="{") {i += 1}
                guard i<chars.count else{break}
                var base=String(chars[i]);i += 1
                if base=="\\",i<chars.count,["i","j"].contains(chars[i]) {base=String(chars[i]);i += 1}
                output += (base+accent).precomposedStringWithCanonicalMapping
                if i<chars.count && chars[i]=="}" {i += 1};continue
            }
            if !next.isLetter {output.append(next);i += 1;continue}
            let start=i;while i<chars.count && chars[i].isLetter {i += 1};let command=String(chars[start..<i])
            if let replacement=replacements[command] {output += replacement}
            else if !wrappers.contains(command) {unknown.insert("\\"+command);output += "\\"+command}
            if i<chars.count && chars[i].isWhitespace {i += 1}
        }
        return output
    }
    static func names(_ value:String,unknown:inout Set<String>)->[[String:String]] {
        let chars=Array(value);var depth=0,start=0,i=0;var parts:[String]=[]
        while i<chars.count {
            if chars[i]=="{" {depth += 1};if chars[i]=="}" {depth=max(0,depth-1)}
            if depth==0,i+5<=chars.count,String(chars[i..<i+5]).lowercased()==" and " {parts.append(String(chars[start..<i]));i += 5;start=i;continue}
            i += 1
        }
        parts.append(String(chars[start...]))
        return parts.compactMap {raw in
            let raw=raw.trimmingCharacters(in:.whitespacesAndNewlines);guard !raw.isEmpty else{return nil}
            if raw.hasPrefix("{"),raw.hasSuffix("}") {return ["literal":decode(raw,unknown:&unknown)]}
            let comma=raw.components(separatedBy:",").map{decode($0.trimmingCharacters(in:.whitespaces),unknown:&unknown)}
            if comma.count>=2 {var name=["family":comma[0],"given":comma.last!];if comma.count>2 {name["suffix"]=comma[1]};return name}
            let words=comma[0].split(separator:" ").map(String.init)
            guard words.count>1 else{return ["family":comma[0]]}
            let particle=words.indices.dropFirst().first(where:{words[$0].first?.isLowercase==true}) ?? words.count-1
            return ["given":words[..<particle].joined(separator:" "),"family":words[particle...].joined(separator:" ")]
        }
    }
}
