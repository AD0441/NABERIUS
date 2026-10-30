import AppKit
import Foundation
let root=URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
let brand=root.appendingPathComponent("Resources/Brand")
try FileManager.default.createDirectory(at:brand,withIntermediateDirectories:true)
// Free, reduced interpretation of the Naberius seal: staff, two bars, one open curve.
let pathData="M 30 24 V 76 M 20 43 H 58 M 20 57 H 58 M 55 24 C 79 31 79 41 62 50 C 79 59 79 69 55 76"
func mark()->NSBezierPath {
    let p=NSBezierPath()
    p.move(to:NSPoint(x:30,y:24));p.line(to:NSPoint(x:30,y:76))
    for y in [43.0,57] {p.move(to:NSPoint(x:20,y:y));p.line(to:NSPoint(x:58,y:y))}
    p.move(to:NSPoint(x:55,y:24));p.curve(to:NSPoint(x:62,y:50),controlPoint1:NSPoint(x:79,y:31),controlPoint2:NSPoint(x:79,y:41));p.curve(to:NSPoint(x:55,y:76),controlPoint1:NSPoint(x:79,y:59),controlPoint2:NSPoint(x:79,y:69))
    p.lineCapStyle = .round;p.lineJoinStyle = .round
    return p
}
for (name,color) in [("symbol-light","#234A60"),("symbol-dark","#E8E6D9")] {
    let svg="<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"16 18 64 64\"><title>Naberius · sello reducido</title><path d=\"\(pathData)\" fill=\"none\" stroke=\"\(color)\" stroke-width=\"3.2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/></svg>"
    try svg.write(to:brand.appendingPathComponent(name+".svg"),atomically:true,encoding:.utf8)
}
func render(_ size:Int)->Data {
    let rep=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:size,pixelsHigh:size,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
    NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:rep)
    let context=NSGraphicsContext.current!.cgContext;context.scaleBy(x:Double(size)/1024,y:Double(size)/1024)
    NSColor(srgbRed:17/255,green:27/255,blue:38/255,alpha:1).setFill()
    NSBezierPath(roundedRect:CGRect(x:75,y:75,width:874,height:874),xRadius:194,yRadius:194).fill()
    context.translateBy(x:92,y:950);context.scaleBy(x:8.75,y:-8.75)
    NSColor(srgbRed:232/255,green:230/255,blue:217/255,alpha:1).setStroke()
    let path=mark();path.lineWidth=size<=16 ? 7.2 : (size<=32 ? 4.8 : (size<=64 ? 4 : 3.4));path.stroke()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using:.png,properties:[:])!
}
let iconset=root.appendingPathComponent("Resources/AppIcon.iconset")
try FileManager.default.createDirectory(at:iconset,withIntermediateDirectories:true)
for size in [16,32,64,128,256,512,1024] {try render(size).write(to:brand.appendingPathComponent("icon-\(size).png"))}
try render(1024).write(to:brand.appendingPathComponent("app-icon.png"))
for size in [16,32,128,256,512] {
    try render(size).write(to:iconset.appendingPathComponent("icon_\(size)x\(size).png"))
    try render(size*2).write(to:iconset.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
let svg="<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 1024 1024\"><title>Naberius · icono reducido</title><rect x=\"75\" y=\"75\" width=\"874\" height=\"874\" rx=\"194\" fill=\"#111B26\"/><path transform=\"translate(92 74) scale(8.75)\" d=\"\(pathData)\" fill=\"none\" stroke=\"#E8E6D9\" stroke-width=\"3.4\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/></svg>"
try svg.write(to:brand.appendingPathComponent("app-icon.svg"),atomically:true,encoding:.utf8)
