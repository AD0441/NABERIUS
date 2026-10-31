import Foundation
public struct TemplateAnalysis: Sendable {
    public var compatible: Bool
    public var partial: Bool
    public var messages: [String]
    public var template: DocumentTemplate
}
public enum TemplateImporter {
    public static func analyze(_ url: URL) throws -> TemplateAnalysis {
        guard (try url.resourceValues(forKeys:[.fileSizeKey]).fileSize ?? 0)<=TemplateZIP.maximumArchive else {throw NabError.invalid(L10n.text("La plantilla supera 16 MB."))}
        let data = try Data(contentsOf:url,options:.mappedIfSafe)
        guard data.count <= TemplateZIP.maximumArchive else { throw NabError.invalid(L10n.text("La plantilla supera 16 MB.")) }
        var source = ""; var notes: [String] = []
        if url.pathExtension.lowercased() == "zip" {
            let files=try TemplateZIP.read(url)
            let package=try LaTeXTemplatePackage.analyze(files:files,sourceName:url.lastPathComponent)
            var template=DocumentTemplate(id:UUID().uuidString,name:(["sn-jnl":"Springer Nature","elsarticle":"Elsevier","IEEEtran":"IEEE","acmart":"ACM"][package.plan.documentClass] ?? package.plan.documentClass),detail:L10n.text("Paquete editorial completo. El PDF conserva su clase y recursos originales."))
            template.category="Paquetes LaTeX";template.package=package;template.fontSize=10;template.lineSpacing=1.2
            template.lockedProperties=TemplateProperty.allCases
            if let kind=DocumentClass(rawValue:package.plan.documentClass) {template.effectiveLayout=DocumentLayout(documentClass:kind)}
            let messages=[L10n.format("Archivo principal: %@",package.plan.mainFile),L10n.format("Clase: %@ · Opciones: %@",package.plan.documentClass,package.plan.options.joined(separator:", ")),L10n.format("%@ archivos conservados · %@ estilos bibliográficos",files.count,package.plan.bibliographyStyles.count),L10n.format("Motor detectado: %@ · Bibliografía: %@",package.plan.requiredEngine,package.plan.bibliographyBackend),L10n.text("El análisis no compila el ZIP ni ejecuta programas del paquete. La composición utiliza un directorio aislado y el modo restringido del motor.")]
            return TemplateAnalysis(compatible:true,partial:package.plan.requiredEngine != "tectonic" || package.plan.bibliographyBackend=="biber",messages:messages,template:template)
        } else {
            guard ["tex","cls","sty"].contains(url.pathExtension.lowercased()), let s = String(data:data,encoding:.utf8) else { throw NabError.invalid(L10n.text("Selecciona .tex, .cls, .sty o .zip UTF-8.")) }; source = s
        }
        let unsafe = ["\\write18","\\openout","\\openin","\\read","\\catcode","\\directlua","\\csname","\\input|","/etc/","../","\\immediate"]
        let found = unsafe.filter { source.contains($0) }
        let macros = source.contains("\\newcommand") || source.contains("\\def") || source.contains("\\usepackage")
        var t = DocumentTemplate(id:UUID().uuidString,name:url.deletingPathExtension().lastPathComponent,detail:L10n.text("Importada con mapeo semántico seguro; no ejecuta código externo.")); t.category = L10n.text("Importadas")
        let compatible = found.isEmpty
        if !found.isEmpty { notes.append(L10n.text("No compatible: contiene instrucciones que requieren acceso o ejecución no admitidos: ")+found.joined(separator:", ")) }
        if macros { notes.append(L10n.text("Compatibilidad parcial: paquetes y macros externos no se ejecutan. Se instala una variante semántica basada en los estilos de Naberius; revisar el documento de prueba.")) }
        if compatible && !macros { notes.append(L10n.text("Compatible con el mapeo básico de artículo. Se conserva el contenido del documento al aplicar.")) }
        func captures(_ pattern:String)->[[String]] {
            guard let regex=try? NSRegularExpression(pattern:pattern)else{return []}
            let ns=source as NSString
            return regex.matches(in:source,range:NSRange(location:0,length:ns.length)).map {match in (1..<match.numberOfRanges).map {match.range(at:$0).location == NSNotFound ? "" : ns.substring(with:match.range(at:$0))}}
        }
        if let match=captures(#"\\documentclass(?:\[([^\]]*)\])?\{([^}]+)\}"#).first {
            if let kind=DocumentClass(rawValue:match[1]) {t.effectiveLayout=DocumentLayout(documentClass:kind);notes.append(L10n.text("Clase mapeada: ")+kind.rawValue+".")}
            else {notes.append(L10n.text("Clase externa no incorporada: ")+match[1]+L10n.text(". La variante usa article; verificar el documento de prueba."))}
            if let size=captures(#"(?:\[|,)(10|11|12)pt(?:,|\])"#).first.flatMap({Double($0[0])}) {t.fontSize=size}
        }
        if source.contains("letterpaper") {t.paper="letterpaper"}
        if source.contains("legalpaper") {t.paper="legalpaper"}
        if let margin=captures(#"margin\s*=\s*([0-9]+(?:\.[0-9]+)?)\s*(mm|cm)"#).first,let value=Double(margin[0]) {
            let mm=value*(margin[1]=="cm" ? 10 : 1)
            if (10...50).contains(mm) {t.marginMM=mm;notes.append(L10n.format("Márgenes mapeados: %@ mm.",mm))}
        }
        if let font=captures(#"\\setmainfont(?:\[[^\]]*\])?\{([^}]+)\}"#).first?.first {
            if DocumentTypography.supportedFonts.contains(font) {t.font=font}
            else {notes.append(L10n.text("Fuente externa no incluida: ")+font+L10n.text(". La variante usa Latin Modern."))}
        }
        let dependencies=captures(#"\\usepackage(?:\[[^\]]*\])?\{([^}]+)\}"#).flatMap {$0[0].split(separator:",").map(String.init)}
        if !dependencies.isEmpty {notes.append(L10n.text("Dependencias detectadas: ")+dependencies.joined(separator:", ")+L10n.text(". No se ejecutan ni instalan durante el análisis."))}

        notes.append(L10n.text("La importación nunca instala ejecutables ni compila el archivo recibido."))
        return TemplateAnalysis(compatible:compatible,partial:macros || notes.contains(where:{$0.contains(L10n.text("no incorporada")) || $0.contains(L10n.text("no incluida"))}),messages:notes,template:t)
    }
}
