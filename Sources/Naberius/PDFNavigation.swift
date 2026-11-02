import Foundation
import NaberiusCore

struct PDFNavigationRequest:Identifiable {
    let id=UUID()
    let pdf:URL
    let location:PDFSourceLocation
}
protocol PDFNavigating {
    func locations(_ map:PDFSynchronization,_ blockID:UUID,_ pageHint:Int)async throws->[PDFSourceLocation]
    func source(_ map:PDFSynchronization,_ point:CGPoint,_ page:Int)async throws->PDFSourceLocation?
}
struct SystemPDFNavigator:PDFNavigating {
    func locations(_ map:PDFSynchronization,_ blockID:UUID,_ pageHint:Int)async throws->[PDFSourceLocation] {
        try await map.locations(for:blockID,pageHint:pageHint)
    }
    func source(_ map:PDFSynchronization,_ point:CGPoint,_ page:Int)async throws->PDFSourceLocation? {
        try await map.source(at:point,page:page)
    }
}

import SwiftUI

struct PDFSynchronizationButton:View {
    let session:Session
    var body:some View {
        Button {session.locateSelectionInPDF()} label:{Image(systemName:"scope")}
            .help(L10n.text("Localizar selección del editor en el PDF · ⌥⌘J"))
            .accessibilityLabel(L10n.text("Localizar selección en el PDF"))
            .disabled(!session.canSynchronize || session.synchronizing)
    }
}
struct PDFSynchronizationHint:View {
    let session:Session
    var body:some View {
        Text(session.synchronizationMessage ?? (session.proofNeedsUpdate ? L10n.text("Actualiza el PDF para sincronizarlo con los cambios del documento.") : L10n.text("⌘-clic en el PDF: mostrar el párrafo en el editor.")))
            .font(.caption).foregroundStyle(.secondary).frame(maxWidth:.infinity,alignment:.leading)
            .padding(.horizontal,12).padding(.vertical,6)
    }
}
