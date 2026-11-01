import Foundation

struct TeXCall {
    var name:String
    var range:NSRange
    var arguments:[NSRange]
    var optional:[NSRange]
}

enum TeXTemplate {
    static func text(_ data:Data)->String? {String(data:data,encoding:.utf8) ?? String(data:data,encoding:.windowsCP1252) ?? String(data:data,encoding:.isoLatin1)}
    /// Comments become spaces so ranges remain valid in the original UTF-16 string.
    static func uncomment(_ source:String)->String {
        let input=source as NSString,result=NSMutableString(string:source);var i=0
        while i<input.length {
            if input.character(at:i)==92 {i += min(2,input.length-i);continue}
            if input.character(at:i)==37 {
                let start=i
                while i<input.length && ![10,13].contains(input.character(at:i)) {i += 1}
                result.replaceCharacters(in:NSRange(location:start,length:i-start),with:String(repeating:" ",count:i-start))
            } else {i += 1}
        }
        return result as String
    }
    static func calls(_ source:String)->[TeXCall] {
        let s=uncomment(source) as NSString;var i=0,result:[TeXCall]=[],budget=max(1,s.length)*16
        func whitespace(_ n:unichar)->Bool {[9,10,13,32].contains(n)}
        func letter(_ n:unichar)->Bool {(65...90).contains(n) || (97...122).contains(n) || n==64}
        func balanced(_ start:Int,_ open:unichar,_ close:unichar)->(NSRange,Int)? {
            var j=start+1,depth=1
            while j<s.length {
                guard budget>0 else{return nil};budget -= 1
                let c=s.character(at:j)
                if c==92 {j += min(2,s.length-j);continue}
                if c==open {depth += 1};if c==close {depth -= 1;if depth==0{return (NSRange(location:start+1,length:j-start-1),j+1)}}
                j += 1
            }
            return nil
        }
        while i<s.length {
            guard s.character(at:i)==92 else {i += 1;continue}
            let start=i;i += 1;let nameStart=i
            while i<s.length && letter(s.character(at:i)) {i += 1}
            guard i>nameStart else {i += min(1,s.length-i);continue}
            let name=s.substring(with:NSRange(location:nameStart,length:i-nameStart))
            var cursor=i;if cursor<s.length && s.character(at:cursor)==42 {cursor += 1}
            var args:[NSRange]=[],options:[NSRange]=[];var end=cursor
            while cursor<s.length && args.count<4 && options.count<4 {
                while cursor<s.length && whitespace(s.character(at:cursor)) {cursor += 1}
                let c=cursor<s.length ? s.character(at:cursor) : 0
                guard c==123 || c==91,let (range,next)=balanced(cursor,c,c==123 ? 125 : 93) else {break}
                if c==123 {args.append(range)} else {options.append(range)}
                end=next;cursor=next
            }
            result.append(TeXCall(name:name,range:NSRange(location:start,length:end-start),arguments:args,optional:options))
            // Scan nested calls too; field selection later removes overlapping containers.
        }
        return result
    }
    static func value(_ call:TeXCall,in source:String)->String {call.arguments.first.map{(source as NSString).substring(with:$0)} ?? ""}
    static func plain(_ source:String)->String {
        var value=source.replacingOccurrences(of:#"\\[A-Za-z@]+\*?(?:\s*\[[^\]]*\])?\s*(?=\{)"#,with:"",options:.regularExpression)
        var unknown=Set<String>();value=TeXMetadata.decode(value,unknown:&unknown)
        value=value.replacingOccurrences(of:#"\\[A-Za-z@]+\*?"#,with:"",options:.regularExpression).replacingOccurrences(of:#"\s+"#,with:" ",options:.regularExpression)
        return value.trimmingCharacters(in:.whitespacesAndNewlines)
    }
    static func replacing(_ source:String,_ edits:[(NSRange,String)])->String {
        let value=NSMutableString(string:source)
        for (range,replacement) in edits.sorted(by:{$0.0.location>$1.0.location}) where range.location>=0 && NSMaxRange(range)<=value.length {value.replaceCharacters(in:range,with:replacement)}
        return value as String
    }
}

public enum TemplateFieldAlias:String,Codable,Sendable {case title,subtitle,authors,institution,abstract,keywords,date,custom}
public struct TemplateField:Codable,Equatable,Identifiable,Sendable {
    public var id:String
    public var macro:String
    public var ordinal:Int
    public var location:Int
    public var length:Int
    public var original:String
    public var alias:TemplateFieldAlias
    public var plainValue:String {
        if id.hasSuffix(".environment"),macro.lowercased().contains("keywords"),original.contains("\\item") {
            return original.components(separatedBy:"\\item").map(TeXTemplate.plain).filter{!$0.isEmpty}.joined(separator:"; ")
        }
        return TeXTemplate.plain(original)
    }
    var range:NSRange {NSRange(location:location,length:length)}
    public var label:String {
        let names=["fnm":L10n.text("Nombre"),"sur":L10n.text("Apellido"),"spfx":L10n.text("Prefijo del apellido"),"sfx":L10n.text("Sufijo del nombre"),"email":L10n.text("Correo"),"orgdiv":L10n.text("Departamento"),"orgname":L10n.text("Organización"),"street":L10n.text("Dirección"),"city":L10n.text("Ciudad"),"postcode":L10n.text("Código postal"),"state":L10n.text("Región"),"country":L10n.text("País"),"IEEEauthorblockN":L10n.text("Autor"),"IEEEauthorblockA":L10n.text("Afiliación"),"thanks":L10n.text("Financiación / nota del título"),"thisvolume":L10n.text("Volumen"),"thismonth":L10n.text("Mes de publicación"),"thisyear":L10n.text("Año de publicación"),"thisdoi":L10n.text("DOI editorial"),"thisstartpage":L10n.text("Página inicial"),"thisendpage":L10n.text("Página final"),"frenchabstract":L10n.text("Resumen en francés"),"englishabstract":L10n.text("Resumen en inglés")]
        return L10n.format("%@ · %@",names[macro] ?? macro,ordinal+1)
    }
}
public struct TemplatePackagePlan:Codable,Equatable,Sendable {
    public var mainFile:String
    public var candidates:[String]
    public var documentClass:String
    public var options:[String]
    public var dependencies:[String]
    public var bibliographyStyles:[String]
    public var bibliographyBackend:String
    public var requiredEngine:String
    public var prefix:String
    public var fields:[TemplateField]
    public var firstHeading:String
    public var hasClassStyle:Bool
}

public struct LaTeXTemplatePackage:Codable,Equatable,Sendable {
    public var files:[TemplateFile]
    public var plan:TemplatePackagePlan
    public var sourceName:String
    public var customFields:[TemplateField] {plan.fields.filter{$0.alias == .custom}}
    public var hasSeparateAuthors:Bool {customFields.contains{["fnm","sur","author","IEEEauthorblockN"].contains($0.macro)}}
    public var hasSeparateInstitutions:Bool {customFields.contains{["orgdiv","orgname","affil","affiliation","institution","department","IEEEauthorblockA"].contains($0.macro)}}
    public var byteCount:Int {files.reduce(0){$0+$1.data.count}}
    public var previewPDF:Data? {
        let wanted=(plan.mainFile as NSString).deletingPathExtension+".pdf"
        return files.first(where:{$0.path==wanted})?.data
    }
    public func validate()throws {
        guard !files.isEmpty,files.count<=1000,byteCount<=TemplateZIP.maximumExpanded,files.allSatisfy({TemplateZIP.safePath($0.path) && $0.data.count<=TemplateZIP.maximumFile}),Set(files.map{$0.path.precomposedStringWithCanonicalMapping.lowercased()}).count==files.count,
              files.contains(where:{$0.path==plan.mainFile}),plan.prefix.utf8.count<=TemplateZIP.maximumFile,
              plan.fields.allSatisfy({$0.location>=0 && $0.length>=0 && $0.location<=plan.prefix.utf16.count && $0.length<=plan.prefix.utf16.count-$0.location}) else {
            throw NabError.invalid(L10n.text("El paquete de plantilla contiene archivos o campos inválidos."))
        }
        let ordered=plan.fields.sorted{$0.location<$1.location}
        guard Set(plan.fields.map(\.id)).count==plan.fields.count,plan.fields.count<=500,
              ordered.enumerated().allSatisfy({index,field in
                  (plan.prefix as NSString).substring(with:field.range)==field.original && (index==0 || NSMaxRange(ordered[index-1].range)<=field.location)
              }) else {throw NabError.invalid(L10n.text("Los campos editoriales se solapan o no coinciden con la plantilla."))}
    }
    public func initialMetadata()->Metadata {
        var metadata=Metadata()
        for field in plan.fields {
            switch field.alias {
            case .title:metadata.title=field.plainValue
            case .subtitle:metadata.subtitle=field.plainValue
            case .authors:metadata.authors=field.plainValue
            case .institution:metadata.institution=field.plainValue
            case .abstract:metadata.abstract=field.plainValue
            case .keywords:metadata.keywords=field.plainValue
            case .date:metadata.date=field.plainValue
            case .custom:break
            }
        }
        let authorCalls=TeXTemplate.calls(plan.prefix).filter{$0.name=="author"}
        if hasSeparateAuthors {metadata.authors=authorCalls.map{TeXTemplate.plain(TeXTemplate.value($0,in:plan.prefix))}.joined(separator:"; ")}
        let affiliations=TeXTemplate.calls(plan.prefix).filter{["affil","affiliation","institute"].contains($0.name)}
        if hasSeparateInstitutions {metadata.institution=affiliations.map{TeXTemplate.plain(TeXTemplate.value($0,in:plan.prefix))}.joined(separator:"; ")}
        metadata.templateFields=[:]
        let languages=TeXTemplate.calls(plan.prefix).filter{["usepackage","PassOptionsToPackage"].contains($0.name) && TeXTemplate.value($0,in:plan.prefix).contains("babel")}
        let french=plan.prefix.contains("[french]") || plan.options.contains("french") || languages.last?.optional.contains(where:{(plan.prefix as NSString).substring(with:$0)=="french"}) == true
        metadata.language=plan.options.contains("spanish") || plan.prefix.contains("{spanish}") ? "es-ES" : (french ? "fr-FR" : "en-US")
        return metadata
    }
    public static func analyze(files:[TemplateFile],sourceName:String,selectedMain:String?=nil)throws->LaTeXTemplatePackage {
        let candidates=files.compactMap {file->(String,String,Int)? in
            guard (file.path as NSString).pathExtension.lowercased()=="tex",let source=TeXTemplate.text(file.data) else{return nil}
            let calls=TeXTemplate.calls(source)
            guard calls.contains(where:{$0.name=="documentclass"}),calls.contains(where:{$0.name=="begin" && TeXTemplate.value($0,in:source)=="document"}) else{return nil}
            let base=(file.path as NSString).lastPathComponent.lowercased()
            let score=(base=="main.tex" ? 100 : (["manuscript.tex","paper.tex","article.tex"].contains(base) ? 80 : 50))-file.path.filter{$0=="/"}.count
            return (file.path,source,score)
        }.sorted {$0.2 != $1.2 ? $0.2>$1.2 : $0.0<$1.0}
        guard let chosen=selectedMain.flatMap({wanted in candidates.first(where:{$0.0==wanted})}) ?? candidates.first else {throw NabError.invalid(L10n.text("El ZIP no contiene un archivo principal con documentclass y begin document."))}
        let source=chosen.1,calls=TeXTemplate.calls(source),ns=source as NSString
        let classCall=calls.first(where:{$0.name=="documentclass"})!
        let className=TeXTemplate.value(classCall,in:source)
        let options=classCall.optional.first.map{ns.substring(with:$0).split(separator:",").map{$0.trimmingCharacters(in:.whitespacesAndNewlines)}} ?? []
        let begin=calls.first(where:{$0.name=="begin" && TeXTemplate.value($0,in:source)=="document"})!
        guard let end=calls.last(where:{$0.name=="end" && TeXTemplate.value($0,in:source)=="document"}),end.range.location>begin.range.location else {throw NabError.invalid(L10n.text("El documento principal no cierra el entorno document."))}
        let headings=calls.filter{["section","chapter","part"].contains($0.name) && $0.range.location>NSMaxRange(begin.range) && $0.range.location<end.range.location}
        let titleEnd=calls.first(where:{$0.name=="maketitle" && $0.range.location>begin.range.location}).map{NSMaxRange($0.range)} ?? NSMaxRange(begin.range)
        let boundary=headings.first?.range.location ?? titleEnd
        var prefix=ns.substring(to:boundary)
        if !TeXTemplate.calls(prefix).contains(where:{$0.name=="bibliographystyle"}),let style=calls.last(where:{$0.name=="bibliographystyle"}) {
            prefix += "\n"+ns.substring(with:style.range)+"\n"
        }
        let prefixCalls=TeXTemplate.calls(prefix)
        let definitions=prefixCalls.filter{["newcommand","renewcommand","providecommand","DeclareRobustCommand"].contains($0.name)}
        let aliases:[String:TemplateFieldAlias]=["title":.title,"Title":.title,"subtitle":.subtitle,"author":.authors,"Author":.authors,"affil":.institution,"affiliation":.institution,"institute":.institution,"address":.institution,"abstract":.abstract,"keywords":.keywords,"keyword":.keywords,"Keywords":.keywords,"date":.date]
        let custom:Set<String>=["fnm","sur","spfx","sfx","email","orgdiv","orgname","street","city","postcode","state","country","institution","department","organization","authorrunning","titlerunning","shorttitle","shortauthors","IEEEauthorblockN","IEEEauthorblockA","thanks","thisvolume","thismonth","thisyear","thisdoi","thisstartpage","thisendpage"]
        let editable=prefixCalls.filter{call in
            (aliases[call.name] != nil || custom.contains(call.name)) && !call.arguments.isEmpty && !definitions.contains(where:{$0.range.location<call.range.location && NSMaxRange($0.range)>=NSMaxRange(call.range)})
        }
        var fields:[TemplateField]=[],counts:[String:Int]=[:]
        for call in editable {
            var range=call.arguments[0]
            let nested=editable.filter{$0.range.location>range.location && NSMaxRange($0.range)<=NSMaxRange(range)}
            if ["title","Title"].contains(call.name),let note=nested.first(where:{$0.name=="thanks"}) {
                range.length=note.range.location-range.location
            } else if !nested.isEmpty {continue}
            let ordinal=counts[call.name,default:0];counts[call.name]=ordinal+1
            let repeated=["author","affil","affiliation","institute"].contains(call.name) && editable.filter{$0.name==call.name}.count>1
            let alias=ordinal==0 && !repeated ? aliases[call.name] ?? .custom : .custom
            let raw=(prefix as NSString).substring(with:range)
            fields.append(TemplateField(id:call.name+"."+String(ordinal),macro:call.name,ordinal:ordinal,location:range.location,length:range.length,original:raw,alias:alias))
            if call.name=="title",let short=call.optional.first,(prefix as NSString).substring(with:short)==raw {
                fields.append(TemplateField(id:"title.short",macro:"title",ordinal:0,location:short.location,length:short.length,original:raw,alias:.title))
            }
        }
        for environment in ["abstract","englishabstract","frenchabstract","IEEEkeywords","keywords"] {
            guard let opening=prefixCalls.first(where:{$0.name=="begin" && TeXTemplate.value($0,in:prefix)==environment}),
                  let closing=prefixCalls.first(where:{$0.name=="end" && TeXTemplate.value($0,in:prefix)==environment && $0.range.location>NSMaxRange(opening.range)}) else{continue}
            let range=NSRange(location:NSMaxRange(opening.range),length:closing.range.location-NSMaxRange(opening.range))
            let keywords=environment.lowercased().contains("keywords")
            let alias:TemplateFieldAlias=keywords ? .keywords : (environment=="frenchabstract" || fields.contains(where:{$0.alias == .abstract}) ? .custom : .abstract)
            fields.append(TemplateField(id:environment+".environment",macro:environment,ordinal:0,location:range.location,length:range.length,original:(prefix as NSString).substring(with:range),alias:alias))
        }
        let classSource=files.first(where:{($0.path as NSString).lastPathComponent==className+".cls"}).flatMap{TeXTemplate.text($0.data)} ?? ""
        let dependencies=Array(Set(TeXTemplate.calls(prefix+"\n"+classSource).filter{["usepackage","RequirePackage"].contains($0.name)}.flatMap{TeXTemplate.value($0,in:prefix+"\n"+classSource).split(separator:",").map{$0.trimmingCharacters(in:.whitespaces)}})).sorted()
        let biblatexCall=prefixCalls.first{["usepackage","RequirePackage"].contains($0.name) && TeXTemplate.value($0,in:prefix).split(separator:",").contains("biblatex")}
        let biblatexOptions=biblatexCall?.optional.map{(prefix as NSString).substring(with:$0).replacingOccurrences(of:" ",with:"")}.joined(separator:",") ?? ""
        let backend=(dependencies.contains("biblatex") || calls.contains(where:{$0.name=="printbibliography"})) && !biblatexOptions.contains("backend=bibtex") ? "biber" : "bibtex"
        let directive=source.split(whereSeparator:\.isNewline).prefix(8).joined(separator:" ").lowercased()
        let engine=directive.contains("lualatex") || dependencies.contains("luacode") ? "lualatex" : "tectonic"
        let plan=TemplatePackagePlan(mainFile:chosen.0,candidates:candidates.map{$0.0},documentClass:className,options:options,dependencies:dependencies,bibliographyStyles:files.filter{($0.path as NSString).pathExtension.lowercased()=="bst"}.map{$0.path}.sorted(),bibliographyBackend:backend,requiredEngine:engine,prefix:prefix,fields:fields,firstHeading:headings.first.map{TeXTemplate.plain(TeXTemplate.value($0,in:source))} ?? "",hasClassStyle:TeXTemplate.uncomment(prefix+"\n"+classSource).contains("\\bibliographystyle"))
        let package=LaTeXTemplatePackage(files:files,plan:plan,sourceName:sourceName);try package.validate();return package
    }
}
