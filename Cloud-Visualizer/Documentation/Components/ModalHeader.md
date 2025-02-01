# ModalHeader Component Documentation

## Overview
The `ModalHeader` component is a SwiftUI view used as a common header for all modal views. It displays a title and optionally an error message.

## Properties

| Property      | Type                | Description |
|--------------|--------------------|-------------|
| `title`      | `String`            | The title displayed in the modal header. |
| `errorMessage` | `Binding<String?>` | An optional binding to an error message. If not `nil`, the error message is displayed in red. |

## Usage

```swift
@State private var errorMessage: String? = nil

var body: some View {
    ModalHeader(title: "My Modal", errorMessage: $errorMessage)
}
```

## Behavior
- The component dynamically displays an error message if provided.
- The title remains visible regardless of the error state.

