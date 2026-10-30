import SwiftUI
import Observation
import PDFKit
import NaberiusCore
import UniformTypeIdentifiers
import os

struct Recent: Codable, Identifiable {
    var path: String
    var opened: Date
    var title: String
    var id: String { path }
}
@Observable final class Session {
    var document: NabDocument?
    var currentURL: URL?
    var status = L10n.text("Todo en tu Mac")
    var error: String?
    var recent: [Recent] = []
    var library: [Reference] = []
    var libraryPersonal=false
    var bibliographyImport:BibliographyImportReport?
    private var importPersonal=false
    var templates = DocumentTemplate.builtins
    var pageMode = true
    var zoom=1.0
    var focusMode = false
    var inspector = false
    var showLibrary = false
    var showFind = false
    var sheet: Sheet?
    var citations = CitationOutput()
    var previewURL: URL?
    var showProof = false
    var compilation: Compilation?
    var failedComposition:CompositionFailure?
    var proofZoom:Double?
    var proofPage = 0
    var proofPageCount = 0
    var equationImages: [MathExpression:NSImage] = [:]
    var renderingEquation = false
    private var previewVersion = -1
    var proofNeedsUpdate: Bool { previewVersion != editVersion }
    private var equationTask: Task<Void,Never>?
    var compiling = false
    var selectedStyle: BlockStyle = .paragraph
    var selectedNode: UUID?
    var inlineTableID:UUID?
    var selectedBlock: UUID?
    var revision = 0
    var recoveryFiles: [URL] = []
    var findQuery = ""
    var replaceQuery = ""
    var caseSensitive = false
    var wholeWord = false
    var matchCount = 0
    var matchPosition = 0
    var editor: NativeTextView?
    let undo = UndoManager()
    private let disk = DocumentDisk()
    private let filePanelFilter=NabFilePanelFilter()
    private var openFilePanel:NSOpenPanel?
    private var expected: Data?
    private var documentOperation=UUID()
    private var autosave: Task<Void,Never>?
    private var citationTask: Task<Void,Never>?
    private var compileTask: Task<Void,Never>?
    private var diskTask: Task<Void,Never>?
    private var journalTask:Task<Void,Never>?
    private var editVersion = 0
    private var lastTypingTime=Date.distantPast
    private var lastTypingBlock:UUID?
    private var lastTypingEnd=0
    var restoreSelection=false
    private var saving = false
    private let logger = Logger(subsystem:"cl.sebastianpasten.Naberius",category:"Document")
    let support: URL
    enum Sheet: String, Identifiable { case templates, library, insert, citation, link, reference, about, export, recovery, diagnostic; var id: String { rawValue } }
    init(supportDirectory:URL? = nil) {
        support = supportDirectory ?? FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("Naberius")
        try? FileManager.default.createDirectory(at:support,withIntermediateDirectories:true)
        recent = (try? JSONDecoder().decode([Recent].self,from:Data(contentsOf:support.appendingPathComponent("recent.json")))) ?? []
        library = (try? JSONDecoder().decode([Reference].self,from:Data(contentsOf:support.appendingPathComponent("library.json")))) ?? []
        if let personal = try? JSONDecoder().decode([DocumentTemplate].self,from:Data(contentsOf:support.appendingPathComponent("templates.json"))) { templates += personal }
        recoveryFiles = (try? FileManager.default.contentsOfDirectory(at:support.appendingPathComponent("Recovery"),includingPropertiesForKeys:nil).filter{$0.pathExtension=="nab"}) ?? []
        undo.levelsOfUndo=100
        if CommandLine.arguments.contains("--demo") { new(example:true) }
        else if UserDefaults.standard.bool(forKey:"reopenLast"),let last=recent.first,FileManager.default.fileExists(atPath:last.path){open(URL(fileURLWithPath:last.path))}
    }
    func new(template: DocumentTemplate? = nil, example: Bool = false) {
        editor?.finishTableEditing();flushRecovery();documentOperation=UUID();cancelCompile();previewURL=nil;compilation=nil;showProof=false;proofPage=0;proofPageCount=0
        let chosen=template ?? templates.first(where:{$0.id == UserDefaults.standard.string(forKey:"defaultTemplateID")}) ?? DocumentTemplate.builtins[0]
        if example {var demo=NabDocument.example;if let template {demo.template=template};document=demo} else {document=NabDocument(template:chosen)}; currentURL = nil; expected = nil; selectedNode = nil; selectedBlock = nil; undo.removeAllActions(); status = L10n.text("Sin guardar · recuperación local"); revision += 1; if let d=document{queueJournal(d)}; refreshCitations(); changed()
    }
    func reveal(blockID:UUID) {
        if showProof {showProof=false}
        guard let editor else{return}
        editor.attributedString().enumerateAttribute(NSAttributedString.Key("nab.block"),in:NSRange(location:0,length:editor.string.utf16.count)){value,range,stop in
            if value as? String == blockID.uuidString {editor.setSelectedRange(NSRange(location:range.location,length:0));editor.scrollRangeToVisible(editor.selectedRange());editor.window?.makeFirstResponder(editor);stop.pointee=true}
        }
    }
    func goHome(){editor?.finishTableEditing();flushRecovery();documentOperation=UUID();document=nil;cancelCompile()}
    func openPanel() {
        guard openFilePanel == nil else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.data]
        panel.allowsOtherFileTypes = true
        panel.delegate = filePanelFilter
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        openFilePanel = panel
        let completion: (NSApplication.ModalResponse) -> Void = { [weak self, weak panel] response in
            let url = response == .OK ? panel?.url : nil
            self?.openFilePanel = nil
            if let url { self?.open(url) }
        }
        if let window = NSApp.keyWindow {
            panel.beginSheetModal(for: window, completionHandler: completion)
        } else {
            panel.begin(completionHandler: completion)
        }
    }
    func open(_ url: URL, recovered: Bool = false) {
        editor?.finishTableEditing();flushRecovery();let operation=UUID();documentOperation=operation;cancelCompile()
        Task { do {
            let (stored, hash) = try await disk.read(url)
            let d = recovered ? try await disk.readRecovery(url) : stored
            guard documentOperation==operation else{return}
            self.previewURL=nil;self.compilation=nil;self.showProof=false;self.proofPage=0;self.proofPageCount=0;self.document = d; self.currentURL = recovered ? nil : url; self.expected = recovered ? nil : hash; self.undo.removeAllActions(); self.revision += 1; self.status = recovered ? L10n.text("Version recuperada · guarda una copia") : "Guardado"; self.selectedNode = nil
            if !recovered { self.recordRecent(url,title:d.metadata.title) }; self.refreshCitations()
        } catch { self.error = error.localizedDescription } }
    }
    func mutate(_ title: String = L10n.text("Editar documento"), registerUndo:Bool = true, _ body: (inout NabDocument)->Void) {
        guard var d = document else { return }; let old = d; body(&d); guard d != old else { return }
        if registerUndo{undo.registerUndo(withTarget:self) { target in target.restore(old,title:title) }; undo.setActionName(title)}
        if title != "Escribir"{lastTypingBlock=nil}
        d.modified = Date(); document = d; revision += 1; queueJournal(d); changed()
    }
    func restore(_ d: NabDocument, title: String) {
        if let current = document { undo.registerUndo(withTarget:self) { $0.restore(current,title:title) } }
        restoreSelection=true;lastTypingBlock=nil
        var restored=d;restored.modified=Date();document = restored; revision += 1; undo.setActionName(title);queueJournal(restored); changed(); refreshCitations()
    }
    func textChanged(_ blocks: [Block], cursor: Cursor) {
        let previous=document?.blocks ?? [],lookup=Dictionary(uniqueKeysWithValues:previous.map{($0.id,$0)})
        let changed=blocks.filter{lookup[$0.id] != $0}
        let blockID=changed.count==1 ? changed.first?.id : nil
        let coalesce=blockID != nil && blockID==lastTypingBlock && Date().timeIntervalSince(lastTypingTime)<0.8 && abs(cursor.location-lastTypingEnd)<=2 && document?.cursor.length==0
        mutate("Escribir",registerUndo:!coalesce) { $0.blocks = blocks; $0.cursor = cursor }
        lastTypingBlock=blockID;lastTypingTime=Date();lastTypingEnd=cursor.location
    }
    func changed() {
        editVersion += 1; status = currentURL == nil ? L10n.text("Sin guardar · recuperación local") : L10n.text("Cambios sin guardar")
        autosave?.cancel(); let id = document?.id
        autosave = Task { do { try await Task.sleep(for:.seconds(2)); guard document?.id == id else { return }; await persist(forcePanel:false) } catch {} }
    }
    private func queueJournal(_ snapshot:NabDocument) {
        let previous=journalTask,directory=support.appendingPathComponent("Recovery")
        journalTask=Task {await previous?.value;do{try await disk.journal(snapshot,directory:directory)}catch{self.error=L10n.text("No se pudo persistir el diario de recuperación: ")+error.localizedDescription}}
    }
    func flushRecovery() {
        autosave?.cancel()
        guard let d = document else { return }
        // A queued disk actor write owns a value snapshot even if the active document changes.
        let directory = support.appendingPathComponent("Recovery")
        Task { do { try await disk.recovery(d,directory:directory) } catch { logger.error("Recovery write failed: \(error.localizedDescription,privacy:.public)") } }
    }
    func finishRecovery() async throws {
        autosave?.cancel();await journalTask?.value
        if let d=document{try await disk.recovery(d,directory:support.appendingPathComponent("Recovery"))}
    }
    func save(copy: Bool = false) { Task { await persist(forcePanel:true,copy:copy) } }
    func persist(forcePanel: Bool, copy: Bool = false) async {
        guard !saving, let d = document else { return }
        var target = copy ? nil : currentURL
        if target == nil && forcePanel {
            let panel = NSSavePanel(); panel.allowedContentTypes = [UTType(filenameExtension:"nab") ?? .data]; panel.nameFieldStringValue = d.metadata.title+".nab"
            guard panel.runModal() == .OK else { return }; target = panel.url
        }
        let version=editVersion
        saving = true; defer { saving = false;if version != editVersion && document?.id==d.id{Task{await self.persist(forcePanel:false)}} }
        status = "Guardando…"
        do {
            await journalTask?.value
            try await disk.recovery(d,directory:support.appendingPathComponent("Recovery"))
            if let target {
                let hash = try await disk.save(d,to:target,expected:target == currentURL ? expected : nil)
                guard document?.id == d.id else { return }
                currentURL = target; expected = hash; recordRecent(target,title:d.metadata.title)
            }
            status = version == editVersion ? (target == nil ? L10n.text("Recuperación local guardada") : "Guardado") : L10n.text("Cambios sin guardar")
        } catch { self.error = error.localizedDescription; status = L10n.text("No se pudo guardar · contenido conservado") }
    }
    func recordRecent(_ url: URL, title: String) {
        recent.removeAll{$0.path==url.path}; recent.insert(Recent(path:url.path,opened:Date(),title:title),at:0); recent = Array(recent.prefix(20)); persistLocal()
    }
    func persistLocal() {
        do {
            try JSONEncoder().encode(recent).write(to:support.appendingPathComponent("recent.json"),options:.atomic)
            try JSONEncoder().encode(library).write(to:support.appendingPathComponent("library.json"),options:.atomic)
            try JSONEncoder().encode(templates.filter{$0.category != "Integradas"}).write(to:support.appendingPathComponent("templates.json"),options:.atomic)
        } catch { self.error = L10n.text("No se pudo guardar la biblioteca o configuración local: ")+error.localizedDescription }
    }
    func refreshCitations() {
        citationTask?.cancel(); guard let d = document else { return }
        citationTask = Task {
            do {try await Task.sleep(for:.milliseconds(250));try Task.checkCancellation();let result = try await Self.citationsFor(d); guard document?.id == d.id, !Task.isCancelled else { return }; citations = result; revision += 1 }
            catch { self.error = error.localizedDescription }
        }
    }
    @concurrent static func citationsFor(_ d: NabDocument) async throws -> CitationOutput { try Bibliography.render(d) }
    func insert(_ input: AcademicNode) {
        guard !showProof else{return}
        var node=input;node.normalizeTableIdentity()
        mutate(L10n.text("Insertar elemento")) { $0.nodes.append(node) }
        editor?.insertNode(node); selectedNode = node.id; inspector = true; refreshCitations()
    }
    func pasteImage(_ image:NSImage) {
        guard let tiff=image.tiffRepresentation,let rep=NSBitmapImageRep(data:tiff),let png=rep.representation(using:.png,properties:[:]),png.count<=32*1024*1024 else{error=L10n.text("La imagen del portapapeles no pudo convertirse.");return}
        let a=Asset(name:L10n.text("Imagen pegada.png"),mediaType:"image/png",data:png)
        mutate(L10n.text("Pegar imagen")){$0.assets.append(a)};var n=AcademicNode(.figure);n.assetID=a.id;n.caption=L10n.text("Imagen pegada");insert(n)
    }
    func importFigure() {
        let p = NSOpenPanel(); p.allowedContentTypes = [.png,.jpeg,.tiff,.pdf]; guard p.runModal() == .OK, let url = p.url else { return }
        do { try addFigure(url) } catch { self.error = error.localizedDescription }
    }
    func addFigure(_ url: URL) throws {
        let data = try Data(contentsOf:url); guard data.count <= 32*1024*1024, let image = NSImage(data:data), image.size.width <= 24000, image.size.height <= 24000 else { throw NabError.invalid(L10n.text("La imagen no es válida o supera el tamaño admitido.")) }
        let ext = url.pathExtension.lowercased(); let media = ext == "pdf" ? "application/pdf" : (["jpg","jpeg"].contains(ext) ? "image/jpeg" : "image/png")
        var encoded = data
        if ext == "tiff", let rep = NSBitmapImageRep(data:data), let png = rep.representation(using:.png,properties:[:]) { encoded = png }
        var asset = Asset(name:url.lastPathComponent,mediaType:media,data:encoded);if ext=="tiff"{asset.originalData=data}
        mutate(L10n.text("Añadir imagen")) { $0.assets.append(asset) }
        var n = AcademicNode(.figure); n.assetID = asset.id; n.caption = url.deletingPathExtension().lastPathComponent; insert(n)
    }
    func importReferences(personal:Bool=false) {
        let panel=NSOpenPanel();panel.allowedContentTypes=[.json,.plainText];panel.allowsOtherFileTypes=true;panel.canChooseDirectories=false
        let completion:(NSApplication.ModalResponse)->Void = { [weak self] response in
            guard response == .OK,let url=panel.url,let self else{return}
            let targetID=self.document?.id
            Task {
                do {
                    var report=try await Self.analyzeBibliography(url)
                    report.sourceName=url.lastPathComponent
                    guard personal || self.document?.id==targetID else{self.error=L10n.text("El documento cambió durante el análisis. Vuelve a importar el archivo.");return}
                    self.bibliographyImport=report;self.importPersonal=personal;self.libraryPersonal=personal;self.sheet = .library
                } catch {self.error=error.localizedDescription}
            }
        }
        if let window=NSApp.keyWindow {panel.beginSheetModal(for:window,completionHandler:completion)}
        else {panel.begin(completionHandler:completion)}
    }
    @concurrent private static func analyzeBibliography(_ url:URL)async throws->BibliographyImportReport {
        let size=try url.resourceValues(forKeys:[.fileSizeKey]).fileSize ?? 0
        guard size<=10*1024*1024 else{throw NabError.invalid(L10n.text("La bibliografía supera 10 MB."))}
        return try BibliographyImporter.read(Data(contentsOf:url),fileExtension:url.pathExtension)
    }
    func acceptBibliography(_ ids:Set<UUID>) {
        guard let report=bibliographyImport else{return}
        let references=report.references.filter{ids.contains($0.id)}
        if importPersonal {library += references;persistLocal()}
        else {mutate(L10n.text("Importar bibliografía")){$0.references += references};refreshCitations()}
        libraryPersonal=importPersonal;bibliographyImport=nil;sheet = .library
    }
    func openProof() {
        editor?.finishTableEditing()
        showProof = true
        if previewURL == nil && !compiling { compile() }
    }
    func compile(allowNetwork: Bool = false) {
        editor?.finishTableEditing()
        guard let d = document, !compiling else { return }
        showProof = true
        guard let engine = Composer.detectedEngine(custom:UserDefaults.standard.string(forKey:"enginePath") ?? "") else { error = NabError.missingEngine.localizedDescription; return }
        let version = editVersion
        compiling = true
        compileTask = Task {
            defer { compiling = false }
            do {
                let result = try await Composer.compile(d,engine:engine,allowNetwork:allowNetwork)
                guard document?.id == d.id, !Task.isCancelled else { return }
                previewURL = result.pdf; compilation = result; previewVersion = version
                proofPageCount = PDFDocument(url: result.pdf)?.pageCount ?? 0
                proofPage = min(proofPage, max(0, proofPageCount-1))
            } catch {
                if !Task.isCancelled { self.failedComposition=error as? CompositionFailure; self.error = error.localizedDescription }
            }
        }
    }
    func renderEquation(_ id: UUID) {
        guard !renderingEquation, let node=document?.nodes.first(where: { $0.id == id && $0.kind == .equation }) else { return }
        guard let engine=Composer.detectedEngine(custom:UserDefaults.standard.string(forKey:"enginePath") ?? "") else {error=NabError.missingEngine.localizedDescription;return}
        let math=node.math, documentID=document?.id
        renderingEquation = true
        equationTask = Task {
            defer { renderingEquation = false }
            do {
                let result=try await Composer.compileMath(math,engine:engine)
                guard !Task.isCancelled, document?.id == documentID else{return}
                let image=try EquationTypesetter.image(from:result.pdf)
                if equationImages.count >= 32 { equationImages.removeAll() }
                equationImages[math]=image;revision += 1
            } catch {if !Task.isCancelled {self.failedComposition=error as? CompositionFailure;self.error=error.localizedDescription}}
        }
    }
    func cancelCompile() { compileTask?.cancel();equationTask?.cancel() }
    func autosaveForTestingCleanup() {autosave?.cancel();citationTask?.cancel()}
    func exportProject() {
        guard let d = document else { return }; let p = NSOpenPanel(); p.canChooseFiles = false; p.canChooseDirectories = true; p.canCreateDirectories = true; p.message = L10n.text("Selecciona la carpeta donde crear el proyecto LaTeX.")
        guard p.runModal() == .OK, let root = p.url else { return }
        let dest = root.appendingPathComponent("Naberius-"+String(d.id.uuidString.prefix(8))+"-"+String(Int(Date().timeIntervalSince1970)))
        Task { do { try await Self.exportDocument(d,to:dest); status = L10n.text("Proyecto LaTeX exportado"); NSWorkspace.shared.activateFileViewerSelecting([dest]) } catch { self.error = error.localizedDescription } }
    }
    @concurrent static func exportDocument(_ d: NabDocument,to url: URL) async throws { try LaTeX.writeProject(d,at:url) }
    func exportBibliography(csl: Bool) {
        guard let d = document else { return }; let p = NSSavePanel(); p.nameFieldStringValue = csl ? "referencias.json" : "referencias.bib"
        guard p.runModal() == .OK, let url = p.url else { return }
        do { let data = try csl ? Bibliography.cslJSON(d.references) : Data(Bibliography.bibTeX(d.references).utf8); try data.write(to:url,options:.atomic) } catch { self.error = error.localizedDescription }
    }
}

/// Extension filtering remains available while Launch Services refreshes a moved app bundle.
final class NabFilePanelFilter:NSObject,NSOpenSavePanelDelegate {
    func panel(_ sender:Any,shouldEnable url:URL)->Bool {
        if url.hasDirectoryPath || (try? url.resourceValues(forKeys:[.isDirectoryKey]).isDirectory)==true{return true}
        return url.pathExtension.lowercased()=="nab"
    }
}
