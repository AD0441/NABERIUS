import AppKit
import NaberiusCore

enum TemplateResourcePanel {
    static func choose(_ completion:@escaping ([URL])->Void) {
        let panel=NSOpenPanel();panel.allowsMultipleSelection=true;panel.canChooseDirectories=false
        panel.message=L10n.text("Selecciona un ZIP de recursos o los archivos de clase, estilo y bibliografía que faltan. El documento principal se conserva.")
        let finish:(NSApplication.ModalResponse)->Void={response in if response == .OK {completion(panel.urls)}}
        if let window=NSApp.keyWindow {panel.beginSheetModal(for:window,completionHandler:finish)} else {panel.begin(completionHandler:finish)}
    }
    @concurrent static func complete(_ package:LaTeXTemplatePackage,urls:[URL])async throws->LaTeXTemplatePackage {
        try package.addingResources(TemplateImporter.resources(at:urls))
    }
}
