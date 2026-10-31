import Foundation
import Testing
@testable import NaberiusCore

struct LocalizationTests {
    @Test func `all explicit interface keys exist in the packaged Spanish catalog`() throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Sources")
        let enumerator=try #require(FileManager.default.enumerator(at:root,includingPropertiesForKeys:nil))
        let regex=try NSRegularExpression(pattern:#"L10n\.(?:text|format)\("((?:\\.|[^"\\])*)""#)
        _ = try #require(L10n.bundle.url(forResource:"Localizable",withExtension:"strings"),"The selected language directory must contain the packaged catalog.")
        var count=0
        for case let url as URL in enumerator where url.pathExtension=="swift" {
            let source=try String(contentsOf:url,encoding:.utf8),ns=source as NSString
            for match in regex.matches(in:source,range:NSRange(location:0,length:ns.length)) {
                let escaped=ns.substring(with:match.range(at:1))
                let key=try JSONDecoder().decode(String.self,from:Data(("\""+escaped+"\"").utf8))
                #expect(L10n.bundle.localizedString(forKey:key,value:"__MISSING__",table:"Localizable") != "__MISSING__", "Missing key in \(url.lastPathComponent): \(key)")
                count += 1
            }
        }
        #expect(count>400)
        let englishHost=L10n.catalog(preferences:["en-US"])
        #expect(englishHost.localizedString(forKey:"Listo",value:"__MISSING__",table:"Localizable")=="Listo")
        #expect(L10n.format("Fila %@, columna %@",2,3)=="Fila 2, columna 3")
    }
}
