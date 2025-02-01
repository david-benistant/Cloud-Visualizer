# Viewer Components Documentation

## Overview
The viewer components (`TextViewer`, `PDFViewer`, `ImageViewer`, `HtmlViewer`) are SwiftUI-based views designed to display different types of content in a macOS application. Each viewer provides a way to present data in a window with a standard interface.

## Initialization
Each viewer supports two initializers:

### With Data
```swift
let viewer = TextViewer(textData: data)
```

### With ByteStream
```swift
let viewer = try await TextViewer(imageStream: byteStream)
```

## Methods

### `open(title: String)`
Opens the viewer in a new window.

```swift
viewer.open(title: "Document Viewer")
```

## Behavior
- Displays content in a standard macOS window.
- Supports initialization with either raw `Data` or a `ByteStream`.
- Maintains a consistent API across different types of viewers.

