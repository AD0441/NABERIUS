import Foundation
public enum DocumentSearch {
    public static func ranges(_ query:String,in text:String,caseSensitive:Bool,wholeWord:Bool)->[NSRange] {
        guard !query.isEmpty else { return [] }
        let escaped=NSRegularExpression.escapedPattern(for:query)
        let pattern=wholeWord ? "(?<![\\p{L}\\p{N}_])"+escaped+"(?![\\p{L}\\p{N}_])" : escaped
        guard let regex=try? NSRegularExpression(pattern:pattern,options:caseSensitive ? [] : [.caseInsensitive]) else { return [] }
        return regex.matches(in:text,range:NSRange(location:0,length:text.utf16.count)).map(\.range)
    }
    public static func replacing(_ text:String,query:String,replacement:String,caseSensitive:Bool,wholeWord:Bool)->String {
        let mutable=NSMutableString(string:text)
        for range in ranges(query,in:text,caseSensitive:caseSensitive,wholeWord:wholeWord).reversed() { mutable.replaceCharacters(in:range,with:replacement) }; return mutable as String
    }
}
