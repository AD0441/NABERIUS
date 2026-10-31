import Foundation

/// Shared interface catalog, packaged with the core and also copied into the app bundle
/// for SwiftUI's native LocalizedStringKey controls. User document content is never looked up.
public enum L10n {
    static let bundle=catalog(preferences:Locale.preferredLanguages)
    // Xcode places localizations under resourceURL; classic SwiftPM may put them
    // at bundleURL while treating the copied Resources directory as resourceURL.
    // Resolve a concrete language directory in either layout, independent of the host.
    static func catalog(preferences:[String])->Bundle {
        let roots=[Bundle.module.resourceURL,Bundle.module.bundleURL].compactMap{$0}
        let folders=roots.flatMap {root in
            ((try? FileManager.default.contentsOfDirectory(at:root,includingPropertiesForKeys:nil)) ?? []).filter{$0.pathExtension=="lproj"}
        }
        let languages=Array(Set(folders.map{$0.deletingPathExtension().lastPathComponent})).sorted()
        let language=Bundle.preferredLocalizations(from:languages,forPreferences:preferences).first ?? "es"
        for folder in folders where folder.deletingPathExtension().lastPathComponent==language {
            if let selected=Bundle(url:folder) {return selected}
        }
        return Bundle.module
    }
    public static func text(_ key:String)->String {
        bundle.localizedString(forKey:key,value:key,table:"Localizable")
    }
    public static func format(_ key:String,_ arguments:Any...)->String {
        String(format:text(key),locale:Locale.current,arguments:arguments.map {String(describing:$0) as CVarArg})
    }
}
