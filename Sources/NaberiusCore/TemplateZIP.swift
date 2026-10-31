import Foundation

public struct TemplateFile:Codable,Equatable,Sendable {
    public var path:String
    public var data:Data
    public init(path:String,data:Data) {self.path=path;self.data=data}
}

/// Reads ZIP members as data; never extracts paths or runs anything supplied by the archive.
enum TemplateZIP {
    static let maximumArchive=16*1024*1024
    static let maximumExpanded=48*1024*1024
    static let maximumFile=12*1024*1024
    struct Entry {let path:String;let size:Int;let directory:Bool}
    static func safePath(_ path:String)->Bool {
        let components=path.split(separator:"/",omittingEmptySubsequences:false)
        return !path.isEmpty && path.utf8.count<=512 && !path.hasPrefix("/") && !path.hasPrefix("-") &&
        !path.contains(where:{"\\:*?[]\u{0}\n\r".contains($0)}) &&
        components.enumerated().allSatisfy {index,component in
            component != ".." && component != "." && (!component.isEmpty || index==components.count-1 && path.hasSuffix("/"))
        }
    }
    static func entries(_ data:Data)throws->[Entry] {
        guard data.count>=22,data.count<=maximumArchive else {throw NabError.invalid(L10n.text("El paquete ZIP está vacío o supera 16 MB."))}
        let b=[UInt8](data)
        func u16(_ i:Int)->Int {Int(b[i]) | Int(b[i+1])<<8}
        func u32(_ i:Int)->Int {u16(i) | u16(i+2)<<16}
        guard let end=stride(from:b.count-22,through:max(0,b.count-65557),by:-1).first(where:{u32($0)==0x06054b50 && $0+22+u16($0+20)==b.count}),u16(end+4)==0,u16(end+6)==0,u16(end+8)==u16(end+10) else {
            throw NabError.invalid(L10n.text("El ZIP está incompleto, es multidisco o usa un formato no admitido."))
        }
        let count=u16(end+10),length=u32(end+12),offset=u32(end+16)
        guard count>0,count<=1000,offset>=0,length>=0,offset+length<=end else {throw NabError.invalid(L10n.text("El ZIP supera el límite de 1.000 entradas o tiene un índice inválido."))}
        var index=offset,total=0,seen=Set<String>(),result:[Entry]=[]
        for _ in 0..<count {
            guard index+46<=offset+length,u32(index)==0x02014b50 else {throw NabError.invalid(L10n.text("El índice del ZIP está dañado."))}
            let flags=u16(index+8),method=u16(index+10),size=u32(index+24),nameLength=u16(index+28),extra=u16(index+30),comment=u16(index+32)
            guard flags&1==0,[0,8].contains(method),index+46+nameLength+extra+comment<=offset+length,size<=maximumFile else {throw NabError.invalid(L10n.text("ZIP cifrado, compresión no admitida o archivo mayor de 12 MB."))}
            let bytes=Data(b[(index+46)..<(index+46+nameLength)])
            guard let name=String(data:bytes,encoding:.utf8) ?? String(data:bytes,encoding:.isoLatin1),safePath(name),((u32(index+38)>>16)&0xf000) != 0xa000 else {
                throw NabError.invalid(L10n.text("El ZIP contiene rutas inseguras, nombres ambiguos o enlaces simbólicos."))
            }
            let normalized=name.precomposedStringWithCanonicalMapping.lowercased()
            guard seen.insert(normalized).inserted else {throw NabError.invalid(L10n.text("El ZIP repite una ruta o solo cambia sus mayúsculas."))}
            total += size
            guard total<=maximumExpanded else {throw NabError.invalid(L10n.text("La expansión del paquete supera 48 MB."))}
            result.append(Entry(path:name,size:size,directory:name.hasSuffix("/")))
            index += 46+nameLength+extra+comment
        }
        guard index==offset+length else {throw NabError.invalid(L10n.text("El índice del ZIP no coincide con sus entradas."))}
        return result
    }
    static func read(_ url:URL)throws->[TemplateFile] {
        let size=try url.resourceValues(forKeys:[.fileSizeKey]).fileSize ?? 0
        guard size<=maximumArchive else {throw NabError.invalid(L10n.text("La plantilla supera 16 MB."))}
        let inventory=try entries(Data(contentsOf:url))
        var files:[TemplateFile]=[],total=0
        for entry in inventory where !entry.directory && !entry.path.hasPrefix("__MACOSX/") && !(entry.path as NSString).lastPathComponent.hasPrefix("._") {
            let process=Process();process.executableURL=URL(fileURLWithPath:"/usr/bin/unzip");process.arguments=["-p",url.path,entry.path]
            let pipe=Pipe();process.standardOutput=pipe;process.standardError=FileHandle.nullDevice
            try process.run();var content=Data()
            while let chunk=try pipe.fileHandleForReading.read(upToCount:65536),!chunk.isEmpty {
                content.append(chunk)
                if content.count>maximumFile || total+content.count>maximumExpanded {process.terminate();process.waitUntilExit();throw NabError.invalid(L10n.text("Una entrada excede el límite de expansión del paquete."))}
            }
            process.waitUntilExit()
            guard process.terminationStatus==0,content.count==entry.size else {throw NabError.invalid(L10n.text("No se pudo leer una entrada completa del ZIP."))}
            total += content.count;files.append(TemplateFile(path:entry.path,data:content))
        }
        // Remove only a common enclosing directory. Relative relationships remain intact.
        while !files.isEmpty,files.allSatisfy({$0.path.contains("/")}),let component=files.first?.path.split(separator:"/").first,files.allSatisfy({$0.path.split(separator:"/").first==component}) {
            files=files.map{TemplateFile(path:String($0.path.dropFirst(component.count+1)),data:$0.data)}
        }
        return files
    }
}
