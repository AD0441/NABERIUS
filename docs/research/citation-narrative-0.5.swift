// Historical diagnostic of the narrative algorithm in Naberius 0.5.0 (f6bb712).
// Run from the repository root; reads only bundled CSL resources and synthetic metadata.
import Foundation
import JavaScriptCore
let project = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath)
let root = project.appendingPathComponent("Sources/NaberiusCore/Resources")
let context=JSContext()!
context.exceptionHandler={_,error in print("JS ERROR:",error?.toString() ?? "")}
context.evaluateScript(try String(contentsOf:root.appendingPathComponent("citeproc.js"),encoding:.utf8))
context.setObject(try String(contentsOf:root.appendingPathComponent("CSL/apa.csl"),encoding:.utf8),forKeyedSubscript:"style" as NSString)
var locales:[String:String]=[:]
for lang in ["es-ES","en-US"] {locales[lang]=try String(contentsOf:root.appendingPathComponent("CSL/locales-\(lang).xml"),encoding:.utf8)}
context.setObject(locales,forKeyedSubscript:"locales" as NSString)
let item:[String:Any] = ["id":"synthetic1","type":"article-journal","title":"Documento sintético","author":[["family":"Pérez","given":"Ana"],["family":"Gómez","given":"Luis"],["family":"Rojas","given":"Eva"]],"issued":["date-parts":[[2024]]],"container-title":"Revista de prueba"]
context.setObject(item,forKeyedSubscript:"item" as NSString)
context.evaluateScript("var sys={retrieveLocale:function(lang){return locales[lang]||locales['en-US'];},retrieveItem:function(id){return item;}};var engine=new CSL.Engine(sys,style,'es-ES');engine.setOutputFormat('text');engine.updateItems(['synthetic1']);")
let year=context.evaluateScript("engine.makeCitationCluster([{id:'synthetic1','suppress-author':true}])")!.toString()!
let author=context.evaluateScript("engine.makeCitationCluster([{id:'synthetic1','author-only':true}])")!.toString()!
let currentAuthor="Pérez, Ana; Gómez, Luis; Rojas, Eva".components(separatedBy:";").first!.components(separatedBy:",").first!
print("NABERIUS actual:",currentAuthor+" "+year)
print("Motor CSL author-only:",author)
print("Composición usando nombre calculado por CSL:",author+" "+year)
