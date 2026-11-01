import Foundation

extension LaTeXTemplatePackage {
    func fieldValue(_ field:TemplateField,metadata:Metadata)->String {
        switch field.alias {
        case .title:metadata.title
        case .subtitle:metadata.subtitle
        case .authors:metadata.authors
        case .institution:metadata.institution
        case .abstract:metadata.abstract
        case .keywords:metadata.keywords
        case .date:metadata.date
        case .custom:metadata.templateFields?[field.id] ?? field.plainValue
        }
    }
    public func prefix(metadata:Metadata)->String {
        let edits=plan.fields.compactMap {field->(NSRange,String)? in
            let value=fieldValue(field,metadata:metadata)
            guard value != field.plainValue else{return nil}
            if field.macro=="thanks",value.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,
               let call=TeXTemplate.calls(plan.prefix).first(where:{$0.name=="thanks" && $0.arguments.first==field.range}) {return (call.range,"")}
            let replacement=field.id.hasSuffix(".environment") && field.macro.lowercased().contains("keywords") && field.original.contains("\\item") ? "\n"+value.components(separatedBy:CharacterSet(charactersIn:",;")).map{$0.trimmingCharacters(in:.whitespacesAndNewlines)}.filter{!$0.isEmpty}.map{"\\item "+LaTeX.bodyText($0)}.joined(separator:"\n")+"\n" : LaTeX.bodyText(value)
            return (field.range,replacement)
        }
        return TeXTemplate.replacing(plan.prefix,edits)
    }
    public func authors(metadata:Metadata)->String {
        let prefix=prefix(metadata:metadata)
        return TeXTemplate.calls(prefix).filter{["author","Author"].contains($0.name)}.map{TeXTemplate.plain(TeXTemplate.value($0,in:prefix))}.joined(separator:"; ")
    }
    public func source(_ document:NabDocument,citations:CitationOutput)->String {
        var effective=document
        if let title=document.blocks.first(where:{$0.style == .title}) {effective.metadata.title=title.text}
        if let subtitle=document.blocks.first(where:{$0.style == .subtitle}) {effective.metadata.subtitle=subtitle.text}
        var header=prefix(metadata:effective.metadata)
        if needsLegacyFontEncoding {header="\\RequirePackage[T1]{fontenc}\n"+header}
        guard let begin=TeXTemplate.calls(header).first(where:{$0.name=="begin" && TeXTemplate.value($0,in:header)=="document"}) else{return header}
        let packages=["graphicx","amsmath","amssymb","tabularx","booktabs","longtable","hyperref"]
        let additions="\n% Naberius semantic objects; the editorial class retains page and font settings.\n\\makeatletter\n"+packages.map{"\\@ifpackageloaded{\($0)}{}{\\RequirePackage{\($0)}}"}.joined(separator:"\n")+"\n\\makeatother\n"
        header=TeXTemplate.replacing(header,[(NSRange(location:begin.range.location,length:0),additions)])
        if !plan.hasClassStyle && !plan.dependencies.contains("biblatex") && plan.bibliographyBackend=="bibtex" {
            let style=plan.bibliographyStyles.first.map{(($0 as NSString).lastPathComponent as NSString).deletingPathExtension} ?? "plain"
            header += "\n\\bibliographystyle{\(style)}\n"
        }
        if plan.dependencies.contains("biblatex") {
            let resources=TeXTemplate.calls(header).filter{$0.name=="addbibresource"}.compactMap{$0.arguments.first}.map{($0,"naberius-references.bib")}
            header=TeXTemplate.replacing(header,resources)
            if resources.isEmpty {header=TeXTemplate.replacing(header,[(NSRange(location:begin.range.location,length:0),"\\addbibresource{naberius-references.bib}\n")])}
        }
        header += "\n\\hypersetup{pdftitle={\(LaTeX.escape(effective.metadata.title))},pdfauthor={\(LaTeX.escape(authors(metadata:document.metadata)))}}\n"
        let body=LaTeX.body(document,citations:citations,omitTitle:true)
        var bibliography=""
        if document.metadata.bibliography && document.nodes.contains(where:{$0.kind == .citation && !$0.referenceIDs.isEmpty}) && !document.references.isEmpty {
            bibliography=plan.dependencies.contains("biblatex") ? "\\printbibliography" : "\\bibliography{naberius-references}"
        }
        return header+"\n"+body+"\n"+bibliography+"\n\\end{document}\n"
    }
    var originalDirectoryName:String {
        let occupied=Set(files.compactMap{$0.path.split(separator:"/").first?.lowercased()})
        var name="original-template",suffix=2
        while occupied.contains(name) {name="original-template-"+String(suffix);suffix += 1}
        return name
    }
    /// Retains an untouched snapshot as well as the working resources used by the engine.
    func materialize(at root:URL)throws->URL {
        try validate()
        let manager=FileManager.default
        for file in files {
            for base in [root.appendingPathComponent(originalDirectoryName),root] {
                let target=base.appendingPathComponent(file.path)
                try manager.createDirectory(at:target.deletingLastPathComponent(),withIntermediateDirectories:true)
                try file.data.write(to:target,options:.atomic)
            }
        }
        let directory=root.appendingPathComponent((plan.mainFile as NSString).deletingLastPathComponent)
        let generated=directory.appendingPathComponent("main.tex")
        // BibTeX resolves styles relative to its working directory. Keep the original bst/ tree too.
        for file in files where (file.path as NSString).pathExtension.lowercased()=="bst" {
            let target=directory.appendingPathComponent((file.path as NSString).lastPathComponent)
            if manager.fileExists(atPath:target.path),try Data(contentsOf:target) != file.data {throw NabError.invalid(L10n.text("Dos estilos bibliográficos tienen el mismo nombre con contenidos distintos."))}
            try file.data.write(to:target,options:.atomic)
        }
        return generated
    }
    static func referenceKey(_ id:UUID)->String {"nab"+id.uuidString.replacingOccurrences(of:"-",with:"")}
    func citation(_ node:AcademicNode,in document:NabDocument)->String {
        let ids=node.referenceIDs.filter{id in document.references.contains{$0.id==id}}
        guard !ids.isEmpty else{return LaTeX.escape("[Referencia no encontrada]")}
        let command=node.narrative ? "citet" : "citep"
        let pre=LaTeX.bodyText(node.prefix)
        let post=[node.locator,node.suffix].filter{!$0.isEmpty}.map(LaTeX.bodyText).joined(separator:", ")
        let usesNatbib=plan.dependencies.contains("natbib")
        let name=plan.dependencies.contains("biblatex") ? (node.narrative ? "textcite" : "autocite") : (usesNatbib ? command : "cite")
        let extended=usesNatbib || plan.dependencies.contains("biblatex")
        let options=extended ? (pre.isEmpty && post.isEmpty ? "" : (pre.isEmpty ? "[\(post)]" : "[\(pre)][\(post)]")) : (post.isEmpty ? "" : "[\(post)]")
        let prefix=extended || pre.isEmpty ? "" : pre+" "
        return prefix+"\\\(name)\(options){\(ids.map(Self.referenceKey).joined(separator:","))}"
    }
    /// The compiled bibliography contains escaped data, never commands from an imported .bib.
    func bibliography(_ references:[Reference])->String {
        references.map {reference in
            let kind=["book":"book","chapter":"incollection","paper-conference":"inproceedings","thesis":"phdthesis","report":"techreport","webpage":"misc","article-journal":"article"][reference.type] ?? "misc"
            var fields:[String:String]=["title":reference.title,"year":reference.year,"journal":reference.container,"publisher":reference.publisher,"volume":reference.volume,"number":reference.issue,"pages":reference.pages,"doi":reference.doi,"url":reference.url]
            let csl=reference.csl
            if ["incollection","inproceedings"].contains(kind) {fields["booktitle"]=fields.removeValue(forKey:"journal")}
            if kind=="phdthesis" {fields["school"]=reference.publisher}
            if kind=="techreport" {fields["institution"]=reference.publisher}
            for (key,bib) in [("edition","edition"),("publisher-place","address"),("ISBN","isbn"),("ISSN","issn"),("collection-title","series"),("note","note"),("authority","organization")] {
                if let value=csl[key] as? String {fields[bib]=value}
            }
            func names(_ role:String)->String {
                (csl[role] as? [[String:String]] ?? []).map {person in
                    if let literal=person["literal"] {return "{"+LaTeX.escape(literal)+"}"}
                    let family=[person["non-dropping-particle"],person["family"]].compactMap{$0}.joined(separator:" ")
                    return [family,person["suffix"],person["given"]].compactMap{$0}.map(LaTeX.escape).joined(separator:", ")
                }.joined(separator:" and ")
            }
            let authors=names("author"),editors=names("editor")
            if authors.isEmpty {fields["author"]=reference.authors.replacingOccurrences(of:";",with:" and ")}
            let data=fields.keys.sorted().filter{!(fields[$0] ?? "").isEmpty}.map{"  \($0) = {\(LaTeX.bodyText(fields[$0]!))}"}
            let contributors=(authors.isEmpty ? [] : ["  author = {\(authors)}"])+(editors.isEmpty ? [] : ["  editor = {\(editors)}"])
            return "@\(kind){\(Self.referenceKey(reference.id)),\n"+(data+contributors).joined(separator:",\n")+"\n}"
        }.joined(separator:"\n\n")
    }
}
