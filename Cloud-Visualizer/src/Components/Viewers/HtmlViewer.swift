import SwiftUI
import WebKit
import Smithy


struct HtmlViewer {
    private let view: WKWebView
    
    init (htmlData: Data) {
        self.view = WKWebView()
        if let htmlContent = String(data: htmlData, encoding: .utf8) {
            self.view.loadHTMLString(htmlContent, baseURL: nil)
        }
    }
    
    @MainActor
    init(htmlStream: ByteStream) async throws {
        do {
            if let data = try await htmlStream.readData() {
                self.view = WKWebView()
                if let htmlContent = String(data: data, encoding: .utf8) {
                    self.view.loadHTMLString(htmlContent, baseURL: nil)
                }
            } else {
                throw NSError(domain: "HtmlViewer", code: 0)
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
