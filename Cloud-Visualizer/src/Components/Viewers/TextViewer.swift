import SwiftUI
import AppKit
import Smithy

private struct SelectableTextView: NSViewRepresentable {
    typealias NSViewType = NSScrollView

    final class Coordinator: NSObject {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    let text: String

    func makeNSView(context: NSViewRepresentableContext<SelectableTextView>) -> NSScrollView {
        let textView = NSTextView(frame: .zero)
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.string = text
        textView.backgroundColor = .clear
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        let scrollView = NSScrollView(frame: .zero)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: NSViewRepresentableContext<SelectableTextView>) {
        guard let tv = nsView.documentView as? NSTextView else { return }
        if tv.string != text {
            let selectedRange = tv.selectedRange()
            tv.string = text
            tv.setSelectedRange(selectedRange)
        }
    }
}

private struct TextView: View {
    @State private var text: String = ""

    init(textData: Data) {
        _text = State(initialValue: Self.dataToString(textData))
    }

    private static func dataToString(_ data: Data) -> String {
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
            SelectableTextView(text: text)
                .frame(minWidth: 800, minHeight: 800)
        }
    }
}

struct TextViewer {
    private let view: NSHostingView<TextView>

    init(textData: Data) {
        self.view = NSHostingView(rootView: TextView(textData: textData))
    }

    @MainActor
    init(imageStream: ByteStream) async throws {
        guard let data = try await imageStream.readData() else {
            throw NSError(domain: "ImageViewer", code: 0)
        }
        self.view = NSHostingView(rootView: TextView(textData: data))
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

