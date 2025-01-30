import SwiftUI
import PDFKit
import Smithy

struct PDFViewer {
    private let view: NSView

    init (pdfData: Data) {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: pdfData)
        pdfView.autoScales = true
        self.view = pdfView
    }

    @MainActor
    init(pdfStream: ByteStream) async throws {
        do {
            if let data = try await pdfStream.readData() {
                let pdfView = PDFView()
                pdfView.document = PDFDocument(data: data)
                pdfView.autoScales = true
                self.view = pdfView
            } else {
                throw NSError(domain: "PDFViewer", code: 0)
            }
        } catch {
            throw error
        }
    }

    func open(title: String) {
        let window = NSWindow(
            contentRect: NSRect(x: 300, y: 300, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.isReleasedWhenClosed = false
        window.title = title
        window.contentView = view
        window.makeKeyAndOrderFront(nil)
    }
}
