#if DEBUG
import AppKit
import Foundation
@MainActor enum DevelopmentEvidence {
    static func capture() {
        Task {
            let defaults=UserDefaults.standard,previous=defaults.string(forKey:"appearance") ?? "Sistema"
            for appearance in ["Claro","Oscuro"] {
                defaults.set(appearance,forKey:"appearance")
                try? await Task.sleep(for:.milliseconds(450))
                captureWindow(name:appearance == "Oscuro" ? "editor-dark" : "editor-light")
            }
            defaults.set(previous,forKey:"appearance")
        }
    }
    private static func captureWindow(name:String) {
        guard let window=NSApp.keyWindow ?? NSApp.mainWindow,let content=window.contentView else{return}
        let view=content.superview ?? content
        let arguments=CommandLine.arguments
        let projectIndex=arguments.firstIndex(of:"--project-root")
        let project=projectIndex.flatMap { $0+1<arguments.count ? URL(fileURLWithPath:arguments[$0+1]) : nil }
        let folder=project?.appendingPathComponent(".impeccable/review") ?? FileManager.default.temporaryDirectory.appendingPathComponent("Naberius-Evidence")
        do {
            try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
            view.layoutSubtreeIfNeeded()
            guard let rep=view.bitmapImageRepForCachingDisplay(in:view.bounds)else{return}
            view.effectiveAppearance.performAsCurrentDrawingAppearance {view.cacheDisplay(in:view.bounds,to:rep)}
            if let data=rep.representation(using:.png,properties:[:]){try data.write(to:folder.appendingPathComponent(name+".png"),options:.atomic)}
            try "Window: \(window.frame)\nView: \(view.bounds)\n".write(to:folder.appendingPathComponent(name+".txt"),atomically:true,encoding:.utf8)
        }catch{NSLog("Capture failed: %@",error.localizedDescription)}
    }
}
#endif
