import SwiftUI
import NaberiusCore

enum EditorMode:String,CaseIterable,Identifiable {
    case writing,combined,pdf
    var id:String {rawValue}
    var label:String {switch self {case .writing:L10n.text("Escritura");case .combined:L10n.text("Editor + PDF");case .pdf:L10n.text("PDF")}}
}

protocol DocumentCompiling {
    func engine()->URL?
    func run(_ document:NabDocument,_ engine:URL,_ allowNetwork:Bool)async throws->Compilation
}

struct SystemDocumentCompiler:DocumentCompiling {
    func engine()->URL? {Composer.detectedEngine(custom:UserDefaults.standard.string(forKey:"enginePath") ?? "")}
    func run(_ document:NabDocument,_ engine:URL,_ allowNetwork:Bool)async throws->Compilation {
        try await Composer.compile(document,engine:engine,allowNetwork:allowNetwork)
    }
}
