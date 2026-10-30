import SwiftUI
import NaberiusCore

@main struct NaberiusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var session=Session()
    @AppStorage("appearance") private var appearance=Appearance.system.rawValue
    var body: some Scene {
        Window("Naberius",id:"main") {
            RootView(session:session).tint(Brand.accent).preferredColorScheme(Appearance(rawValue:appearance)?.scheme)
                .frame(minWidth:940,minHeight:640)
                .onAppear { delegate.session=session }
        }.defaultSize(width:1280,height:850)
        .commands { AppCommands(session:session) }
        Settings { SettingsView(session:session).tint(Brand.accent).preferredColorScheme(Appearance(rawValue:appearance)?.scheme) }
    }
}
final class AppDelegate:NSObject,NSApplicationDelegate {
    private var pendingURL:URL?
    weak var session:Session? {didSet {if let url=pendingURL,let session {pendingURL=nil;session.open(url)}}}
    func application(_ application:NSApplication,open urls:[URL]) {
        guard let url=urls.first else{return}
        if let session {session.open(url)} else {pendingURL=url}
        NSApp.activate(ignoringOtherApps:true)
        NSApp.windows.first(where:{$0.canBecomeMain})?.makeKeyAndOrderFront(nil)
    }
    func applicationDidFinishLaunching(_ notification:Notification) { NSApp.setActivationPolicy(.regular); NSApp.activate(ignoringOtherApps:true) }
    func applicationShouldTerminate(_ sender:NSApplication)->NSApplication.TerminateReply {
        guard let session,session.document != nil else { return .terminateNow }
        Task {
            do{try await session.finishRecovery();sender.reply(toApplicationShouldTerminate:true)}
            catch{let alert=NSAlert();alert.messageText=L10n.text("No se pudo guardar la recuperación");alert.informativeText=error.localizedDescription;alert.addButton(withTitle:L10n.text("Volver al documento"));alert.runModal();sender.reply(toApplicationShouldTerminate:false)}
        }
        return .terminateLater
    }
}
struct AppCommands:Commands {
    let session:Session
    var body:some Commands {
        fileCommands
        CommandMenu(L10n.text("Formato")) {
            Group {
            ForEach(BlockStyle.allCases,id:\.rawValue) { style in Button(style.label) { session.editor?.applyStyle(style) } }
            Divider(); Button(L10n.text("Negrita")) { session.editor?.toggleBold() }.keyboardShortcut("b"); Button(L10n.text("Cursiva")) { session.editor?.toggleItalic() }.keyboardShortcut("i")
            Button(L10n.text("Superíndice")) { session.editor?.superscript(nil) }; Button(L10n.text("Subíndice")) { session.editor?.subscript(nil) }
            }.disabled(session.showProof || session.document == nil)
        }
        CommandMenu(L10n.text("Insertar")) { InsertMenu(session:session).disabled(session.showProof || session.document == nil) }
        CommandMenu(L10n.text("Documento")) { Button(L10n.text("Propiedades")) { session.inspector.toggle() }; Button(L10n.text("Aplicar plantilla…")) { session.sheet = .templates }; Divider(); Button(L10n.text("Vista previa PDF")) { session.compile() }; Button(L10n.text("Exportar proyecto LaTeX…")) { session.exportProject() } }
        CommandMenu(L10n.text("Referencias")) { Button(L10n.text("Insertar cita…")) { session.sheet = .citation }.disabled(session.showProof); Button(L10n.text("Biblioteca…")) { session.sheet = .library }; Button(L10n.text("Importar bibliografía…")) { session.importReferences() }; Divider(); Button(L10n.text("Exportar BibTeX…")) { session.exportBibliography(csl:false) }; Button(L10n.text("Exportar CSL-JSON…")) { session.exportBibliography(csl:true) } }
        CommandGroup(after:.toolbar) { Button(L10n.text("Páginas / continuo")) { session.pageMode.toggle() }; Button(L10n.text("Modo concentración")) { session.focusMode.toggle() }.keyboardShortcut("f",modifiers:[.command,.shift]); Button(L10n.text("Mostrar inspector")) { session.inspector.toggle() } }
        CommandGroup(replacing:.help) {
            Link(L10n.text("Apoyar en Ko-fi"),destination:Brand.donation);Button(L10n.text("Acerca de Naberius")){session.sheet = .about}
            #if DEBUG
            Button(L10n.text("Capturar evidencia de desarrollo")){DevelopmentEvidence.capture()}.keyboardShortcut("s",modifiers:[.command,.option,.control])
            #endif
        }
    }
    // Older macOS SDKs limit CommandsBuilder to ten children per group.
    @CommandsBuilder private var fileCommands:some Commands {
        CommandGroup(replacing:.appInfo) { Button(L10n.text("Acerca de Naberius")) { session.sheet = .about } }
        CommandGroup(replacing:.newItem) {
            Button(L10n.text("Nuevo documento")) { session.new() }.keyboardShortcut("n")
            Button(L10n.text("Abrir documento…")) { session.openPanel() }.keyboardShortcut("o")
            Menu(L10n.text("Abrir recientes")) { ForEach(session.recent) { r in Button(r.title) { session.open(URL(fileURLWithPath:r.path)) } } }
        }
        CommandGroup(replacing:.saveItem) { Button(L10n.text("Guardar")) { session.save() }.keyboardShortcut("s").disabled(session.document==nil); Button(L10n.text("Guardar copia…")) { session.save(copy:true) }.keyboardShortcut("s",modifiers:[.command,.shift]) }
        CommandGroup(replacing:.undoRedo) {
            Button(L10n.text("Deshacer")) { session.undo.undo() }.keyboardShortcut("z").disabled(!session.undo.canUndo)
            Button(L10n.text("Rehacer")) { session.undo.redo() }.keyboardShortcut("z",modifiers:[.command,.shift]).disabled(!session.undo.canRedo)
        }
        CommandGroup(after:.pasteboard) { Button(L10n.text("Buscar y reemplazar…")) { session.showFind.toggle() }.keyboardShortcut("f") }
    }

}
struct InsertMenu:View {
    let session:Session
    var body:some View {
        Button(L10n.text("Tabla…")) { session.sheet = .insert }
        Button(L10n.text("Figura desde archivo…")) { session.importFigure() }
        Button(L10n.text("Ecuación visual…")) { var n=AcademicNode(.equation);n.numbered=true;session.insert(n) }
        Divider(); Button(L10n.text("Enlace…")) { session.sheet = .link }
        Button(L10n.text("Nota al pie")) { var n=AcademicNode(.footnote);n.note=L10n.text("Escribe la nota en el inspector");session.insert(n) }
        Button(L10n.text("Referencia cruzada…")) { session.sheet = .reference }
        Button(L10n.text("Índice automático")) { session.insert(AcademicNode(.contents)) }
        Button(L10n.text("Salto de página")) {session.editor?.insertPageBreak()}
        Button(L10n.text("Separador estructural")) {session.insert(AcademicNode(.separator))}
    }
}
