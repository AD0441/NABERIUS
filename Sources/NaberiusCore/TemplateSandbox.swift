import Foundation

/// Imported classes are TeX programs. Restrict their filesystem and process access
/// in addition to Tectonic's untrusted mode; relative parent paths need an OS boundary.
enum TemplateSandbox {
    static func profile(engine:URL,root:URL,allowNetwork:Bool)->String {
        func literal(_ value:String)->String {"\""+value.replacingOccurrences(of:"\\",with:"\\\\").replacingOccurrences(of:"\"",with:"\\\"")+"\""}
        func subpath(_ path:String)->String {"(subpath "+literal(path)+")"}
        let manager=FileManager.default,home=manager.homeDirectoryForCurrentUser
        let caches=manager.urls(for:.cachesDirectory,in:.userDomainMask).first ?? home.appendingPathComponent("Library/Caches")
        let texCaches=["Tectonic","TectonicProject.Tectonic"].map{caches.appendingPathComponent($0).path}
        let fontCache=caches.appendingPathComponent("fontconfig").path
        let resolved=root.resolvingSymlinksInPath().path
        let physical=(root.path.hasPrefix("/var/") || root.path.hasPrefix("/tmp/")) ? "/private"+root.path : resolved
        let roots=Array(Set([root.path,resolved,physical]))
        let readable=roots+[engine.deletingLastPathComponent().path,fontCache,home.appendingPathComponent("Library/Application Support/Tectonic").path,home.appendingPathComponent("Library/Application Support/TectonicProject.Tectonic").path,home.appendingPathComponent("Library/Fonts").path]+texCaches
        let writable=roots+[fontCache]+texCaches
        var rules=["(version 1)","(allow default)","(deny file-read-data "+["/Users","/Volumes","/private/var","/private/tmp","/var","/tmp"].map(subpath).joined(separator:" ")+")","(allow file-read-data "+readable.map(subpath).joined(separator:" ")+")","(deny file-write*)","(allow file-write* "+writable.map(subpath).joined(separator:" ")+")","(deny process-exec)","(allow process-exec (literal "+literal(engine.path)+"))"]
        if !allowNetwork {rules.append("(deny network*)")}
        return rules.joined(separator:"\n")
    }
}
