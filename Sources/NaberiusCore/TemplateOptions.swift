import Foundation

public struct TemplateEditingDefaults:Equatable,Sendable {
    public var font=DocumentTypography.defaultFont
    public var fontSize=10.0
    public var marginMM=25.0
    public var paper="a4paper"
    public var columns=1
}

extension LaTeXTemplatePackage {
    public var hasExternalClass:Bool {!["article","report","book","letter"].contains(plan.documentClass) && !files.contains{($0.path as NSString).lastPathComponent==plan.documentClass+".cls"}}
    /// Legacy classes select PostScript NFSS families before the preamble can load fontenc.
    var needsLegacyFontEncoding:Bool {
        guard !plan.dependencies.contains(where:{["fontenc","fontspec","unicode-math"].contains($0)}) else{return false}
        let source=files.first{($0.path as NSString).lastPathComponent==plan.documentClass+".cls"}.flatMap{TeXTemplate.text($0.data)} ?? ""
        return TeXTemplate.uncomment(source).range(of:#"\\(?:re)?newcommand\s*\{\\rmdefault\}\s*\{(?:ptm|ppl|pnc|pbk)\}"#,options:.regularExpression) != nil
    }
    /// Approximate editing hints only. The compiled class remains the design authority.
    public func editingDefaults()->TemplateEditingDefaults {
        let source=plan.prefix+"\n"+(files.first{($0.path as NSString).lastPathComponent==plan.documentClass+".cls"}.flatMap{TeXTemplate.text($0.data)} ?? "")
        let clean=TeXTemplate.uncomment(source)
        let baseOptions=TeXTemplate.calls(clean).filter{$0.name=="LoadClass" || $0.name=="LoadClassWithOptions"}.flatMap{$0.optional}.map{(clean as NSString).substring(with:$0)}.joined(separator:",").components(separatedBy:",").map{$0.trimmingCharacters(in:.whitespacesAndNewlines)}
        let options=plan.options+baseOptions
        var result=TemplateEditingDefaults()
        if let size=options.first(where:{["10pt","11pt","12pt"].contains($0)}).flatMap({Double($0.dropLast(2))}) {result.fontSize=size}
        if options.contains("letterpaper") || clean.contains("{8.5in}") {result.paper="letterpaper"}
        if options.contains("a4paper") {result.paper="a4paper"}
        if options.contains("twocolumn") || clean.contains("\\CLASSOPTIONtwocolumntrue") {result.columns=2}
        if plan.options.contains("onecolumn") {result.columns=1}
        let dependencies=plan.dependencies+TeXTemplate.calls(clean).filter{["usepackage","RequirePackage"].contains($0.name)}.flatMap{TeXTemplate.value($0,in:clean).split(separator:",").map(String.init)}
        if dependencies.contains(where:{["mathptmx","pslatex","times","newtxtext","txfonts"].contains($0)}) || clean.contains("{ptm}") {result.font="Times New Roman"}
        if let expression=try? NSRegularExpression(pattern:#"(?:margin|left|right)\s*=\s*([0-9]+(?:\.[0-9]+)?)\s*(mm|cm)"#),let match=expression.firstMatch(in:plan.prefix,range:NSRange(plan.prefix.startIndex...,in:plan.prefix)),let value=Double((plan.prefix as NSString).substring(with:match.range(at:1))) {
            let mm=value*((plan.prefix as NSString).substring(with:match.range(at:2))=="cm" ? 10 : 1)
            if (10...50).contains(mm) {result.marginMM=mm}
        }
        return result
    }
    public func addingResources(_ additions:[TemplateFile])throws->Self {
        var merged=files
        for addition in additions where addition.path != plan.mainFile {
            guard TemplateZIP.safePath(addition.path) else{throw NabError.invalid(L10n.text("Nombre de recurso no válido."))}
            merged.removeAll{$0.path.precomposedStringWithCanonicalMapping.lowercased()==addition.path.precomposedStringWithCanonicalMapping.lowercased()};merged.append(addition)
        }
        return try Self.analyze(files:merged,sourceName:sourceName,selectedMain:plan.mainFile)
    }
}

extension DocumentTemplate {
    /// A separate editable design; the installed editorial package is retained.
    public func freeVariant()->Self {
        var copy=self
        copy.id=UUID().uuidString;copy.name += L10n.text(" · diseño libre")
        copy.category="Personales";copy.package=nil;copy.locked=false;copy.lockedProperties=[]
        copy.detail=L10n.text("Diseño editable basado en la tipografía y las columnas detectadas. No reproduce ni certifica el formato de la revista.")
        return copy
    }
}

extension TemplateImporter {
    public static func resources(at urls:[URL])throws->[TemplateFile] {
        var result:[TemplateFile]=[]
        for url in urls {
            if url.pathExtension.lowercased()=="zip" {result += try TemplateZIP.read(url)}
            else {
                let size=try url.resourceValues(forKeys:[.fileSizeKey]).fileSize ?? 0
                guard size<=TemplateZIP.maximumFile else{throw NabError.invalid(L10n.text("El recurso supera 12 MB."))}
                result.append(TemplateFile(path:url.lastPathComponent,data:try Data(contentsOf:url)))
            }
            guard result.count<=1000,result.reduce(0,{$0+$1.data.count})<=TemplateZIP.maximumExpanded else{throw NabError.invalid(L10n.text("Los recursos superan el límite del paquete."))}
        }
        return result
    }
}
