import SwiftUI
import Smithy



fileprivate struct TextView: View {
    @State private var text: String = ""
    
    init(textData: Data) {
        self._text = State(initialValue: dataToString(textData))
    }
    func dataToString(_ data: Data) -> String {
        let encodings: [String.Encoding] = [.utf8, .ascii, .isoLatin1, .utf16, .utf32]
        
        for encoding in encodings {
            if let string = String(data: data, encoding: encoding) {
                return string
            }
        }
        return data.map { String(format: "%02hhx", $0) }.joined()
    }
    
    
    var body: some View {
        
        VStack {
            TextEditor(text: $text)
                .frame(minWidth: 800, minHeight: 800)
                .font(.system(size: 12, design: .monospaced))
        }
    }
}

struct TextViewer {
    private let view: NSHostingView<TextView>
    
    init (textData: Data) {
        self.view = NSHostingView(rootView: TextView(textData: textData))
    }
    
    @MainActor
    init(imageStream: ByteStream) async throws {
        do {
            if let data = try await imageStream.readData() {
                self.view = NSHostingView(rootView: TextView(textData: data))
            } else {
                throw NSError(domain: "ImageViewer", code: 0)
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
