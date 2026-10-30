import Foundation

/// Shared interface catalog, packaged with the core and also copied into the app bundle
/// for SwiftUI's native LocalizedStringKey controls. User document content is never looked up.
public enum L10n {
    static let bundle=Bundle.module
    public static func text(_ key:String)->String {
        bundle.localizedString(forKey:key,value:key,table:"Localizable")
    }
    public static func format(_ key:String,_ arguments:Any...)->String {
        String(format:text(key),locale:Locale.current,arguments:arguments.map {String(describing:$0) as CVarArg})
    }
}
