import SwiftUI
import Smithy

fileprivate struct ImageView: View {
    let imageData: Data
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
    }
}

struct ImageViewer {
    private let view: NSHostingView<ImageView>
    
    init (imageData: Data) {
        self.view = NSHostingView(rootView: ImageView(imageData: imageData))
    }
    
    @MainActor
    init(imageStream: ByteStream) async throws {
        do {
            if let data = try await imageStream.readData() {
                self.view = NSHostingView(rootView: ImageView(imageData: data))
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
