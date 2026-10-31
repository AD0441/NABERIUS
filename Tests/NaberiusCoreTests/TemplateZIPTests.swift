import Foundation
import Testing
@testable import NaberiusCore

private struct StoredZIP {
    struct File {
        var name:String
        var bytes:Data
        var mode:UInt32=0o100644
        var declaredSize:UInt32?
    }
    static func archive(_ files:[File])->Data {
        func number(_ value:UInt32,_ count:Int)->Data {Data((0..<count).map{UInt8(truncatingIfNeeded:value >> ($0*8))})}
        func crc(_ data:Data)->UInt32 {
            var value:UInt32=0xffffffff
            for byte in data {value ^= UInt32(byte);for _ in 0..<8 {value=(value >> 1) ^ (value & 1 == 0 ? 0 : 0xedb88320)}}
            return value ^ 0xffffffff
        }
        var output=Data(),index=Data()
        for file in files {
            let name=Data(file.name.utf8),offset=UInt32(output.count),checksum=crc(file.bytes),size=UInt32(file.bytes.count)
            for (value,count):(UInt32,Int) in [(0x04034b50,4),(20,2),(0x800,2),(0,2),(0,2),(0,2),(checksum,4),(size,4),(size,4),(UInt32(name.count),2),(0,2)] {output.append(number(value,count))}
            output.append(name);output.append(file.bytes)
            for (value,count):(UInt32,Int) in [(0x02014b50,4),(0x314,2),(20,2),(0x800,2),(0,2),(0,2),(0,2),(checksum,4),(size,4),(file.declaredSize ?? size,4),(UInt32(name.count),2),(0,2),(0,2),(0,2),(0,2),(file.mode << 16,4),(offset,4)] {index.append(number(value,count))}
            index.append(name)
        }
        let offset=UInt32(output.count);output.append(index)
        for (value,count):(UInt32,Int) in [(0x06054b50,4),(0,2),(0,2),(UInt32(files.count),2),(UInt32(files.count),2),(UInt32(index.count),4),(offset,4),(0,2)] {output.append(number(value,count))}
        return output
    }
}

struct TemplateZIPTests {
    @Test(arguments:["../outside.tex","/absolute.tex","folder/../outside.tex","a//b.tex","C:drive.tex","link\\file.tex"])
    func `unsafe ZIP paths are rejected before reading members`(_ path:String) {
        let bytes=StoredZIP.archive([.init(name:path,bytes:Data())])
        #expect(throws:(any Error).self) {try TemplateZIP.entries(bytes)}
    }
    @Test func `ambiguous duplicate symlink oversized and truncated archives are rejected`() {
        let cases=[
            StoredZIP.archive([.init(name:"main.tex",bytes:Data()),.init(name:"MAIN.tex",bytes:Data())]),
            StoredZIP.archive([.init(name:"linked.cls",bytes:Data("/tmp/outside".utf8),mode:0o120777)]),
            StoredZIP.archive([.init(name:"huge.cls",bytes:Data(),declaredSize:UInt32(TemplateZIP.maximumFile+1))]),
            Data(StoredZIP.archive([.init(name:"main.tex",bytes:Data())]).dropLast(1))
        ]
        for bytes in cases {#expect(throws:(any Error).self) {try TemplateZIP.entries(bytes)}}
    }
    @Test func `a complete ZIP configures unknown classes and retains binary resources`()throws {
        let source="\\documentclass{independent}\n\\title{Portable journal}\n\\author{Example}\n\\begin{document}\n\\maketitle\n\\section{Introduction}Example\\end{document}"
        let resource=Data([0,255,10,40,92,1])
        let bytes=StoredZIP.archive([
            .init(name:"journal/main.tex",bytes:Data(source.utf8)),
            .init(name:"journal/independent.cls",bytes:Data("\\LoadClass{article}".utf8)),
            .init(name:"journal/figures/sample.bin",bytes:resource)
        ])
        let url=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".zip")
        defer{try? FileManager.default.removeItem(at:url)}
        try bytes.write(to:url)
        let analysis=try TemplateImporter.analyze(url),package=try #require(analysis.template.package)
        #expect(analysis.compatible);#expect(package.plan.documentClass=="independent")
        #expect(package.plan.mainFile=="main.tex");#expect(package.files.first{$0.path=="figures/sample.bin"}?.data==resource)
        let document=TemplatePackageTests.document(package)
        let restored=try NabArchive.decode(NabArchive.encode(document))
        #expect(restored.template.package?.files==package.files)
    }
    @Test func `multiple entry variants can be selected without discarding package files`()throws {
        let a="\\documentclass{article}\n\\begin{document}\\section{One}\\end{document}"
        let b="\\documentclass[twocolumn]{report}\n\\begin{document}\\chapter{Two}\\end{document}"
        let files=[TemplateFile(path:"main.tex",data:Data(a.utf8)),TemplateFile(path:"variants/paper.tex",data:Data(b.utf8))]
        let automatic=try LaTeXTemplatePackage.analyze(files:files,sourceName:"variants.zip")
        let chosen=try LaTeXTemplatePackage.analyze(files:files,sourceName:"variants.zip",selectedMain:"variants/paper.tex")
        #expect(automatic.plan.mainFile=="main.tex");#expect(chosen.plan.documentClass=="report")
        #expect(chosen.plan.options==["twocolumn"]);#expect(chosen.files==files)
    }
    @Test func `compiler profile permits its workspace and denies sibling private data`()throws {
        let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let outside=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString+".txt")
        defer{try? FileManager.default.removeItem(at:root);try? FileManager.default.removeItem(at:outside)}
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        let inside=root.appendingPathComponent("inside.txt")
        try Data("owned workspace probe".utf8).write(to:inside);try Data("private sibling probe".utf8).write(to:outside)
        for (path,permitted) in [(inside,true),(outside,false)] {
            let process=Process();process.executableURL=URL(fileURLWithPath:"/usr/bin/sandbox-exec")
            process.arguments=["-p",TemplateSandbox.profile(engine:URL(fileURLWithPath:"/bin/cat"),root:root,allowNetwork:false),"/bin/cat",path.path]
            process.standardOutput=FileHandle.nullDevice;process.standardError=FileHandle.nullDevice
            try process.run();process.waitUntilExit()
            #expect((process.terminationStatus==0)==permitted)
        }
    }
}
