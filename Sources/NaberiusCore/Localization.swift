import Foundation

/// Shared interface catalog, packaged with the core and also copied into the app bundle
/// for SwiftUI's native LocalizedStringKey controls. User document content is never looked up.
public enum L10n {
    static let bundle=catalog(preferences:Locale.preferredLanguages)
    // Select the package's available language independently of a test/CLI host's locale.
    // resourceURL works for both Xcode and command-line SwiftPM bundle layouts.
    static func catalog(preferences:[String])->Bundle {
        let available=Bundle.module.localizations.filter{$0 != "Base"}
        let language=Bundle.preferredLocalizations(from:available,forPreferences:preferences).first ?? "es"
        guard let url=Bundle.module.resourceURL?.appendingPathComponent(language+".lproj"),let selected=Bundle(url:url) else{return Bundle.module}
        return selected
    }
    public static func text(_ key:String)->String {
        bundle.localizedString(forKey:key,value:key,table:"Localizable")
    }
    public static func format(_ key:String,_ arguments:Any...)->String {
        String(format:text(key),locale:Locale.current,arguments:arguments.map {String(describing:$0) as CVarArg})
    }
}
