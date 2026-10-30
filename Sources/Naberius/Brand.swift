import SwiftUI
import NaberiusCore

enum Brand {
    static let author = "Creado por Sebastián Pastén F."
    static let donation = URL(string:"https://ko-fi.com/C0C51WQ1T0")!
    static var accent: Color { Color(nsColor:NSColor(name:nil) { appearance in
        appearance.bestMatch(from:[.darkAqua,.aqua]) == .darkAqua ? NSColor(srgbRed:0.51,green:0.71,blue:0.77,alpha:1) : NSColor(srgbRed:0.137,green:0.29,blue:0.376,alpha:1)
    }) }
}
struct NaberiusMark: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        func p(_ x:Double,_ y:Double)->CGPoint {CGPoint(x:rect.minX+(x-16)/64*rect.width,y:rect.minY+(y-18)/64*rect.height)}
        var path=Path()
        path.move(to:p(30,24));path.addLine(to:p(30,76))
        for y in [43.0,57] {path.move(to:p(20,y));path.addLine(to:p(58,y))}
        path.move(to:p(55,24));path.addCurve(to:p(62,50),control1:p(79,31),control2:p(79,41));path.addCurve(to:p(55,76),control1:p(79,59),control2:p(79,69))
        return path
    }
}
enum Appearance: String, CaseIterable { case system = "Sistema", light = "Claro", dark = "Oscuro"
    var label:String {L10n.text(rawValue)}
    var scheme: ColorScheme? { switch self { case .system: nil; case .light: .light; case .dark: .dark } }
}
struct BrandFooter: View {
    var body: some View {
        VStack(alignment:.leading,spacing:9) {
            HStack(spacing:9) { NaberiusMark().stroke(Brand.accent,style:StrokeStyle(lineWidth:1.2,lineCap:.round,lineJoin:.round)).frame(width:28,height:28); Text("NABERIUS").font(.system(size:14,weight:.semibold)).tracking(1) }
            SettingsLink { Label(L10n.text("Configuración"),systemImage:"gearshape") }.buttonStyle(.plain)
            Text(Brand.author).font(.system(size:10)).foregroundStyle(.secondary)
            Link(destination:Brand.donation) { Label(L10n.text("Apoyar en Ko-fi"),systemImage:"cup.and.saucer") }.font(.caption).help(L10n.text("Apoyo voluntario. Abre Ko-fi al hacer clic."))
        }.frame(maxWidth:.infinity,alignment:.leading).padding(18)
    }
}
