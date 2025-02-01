# ConfirmModal Component Documentation

## Overview
The `ConfirmModal` component is a SwiftUI view that provides a confirmation dialog with cancel and confirm actions.

## Properties

| Property  | Type                | Description |
|-----------|--------------------|-------------|
| `isOpen`  | `Binding<Bool>`    | Controls the visibility of the modal. Setting it to `false` closes the modal. |
| `onConfirm` | `() async -> Void` | An asynchronous closure that executes when the confirm button is pressed. |

## Usage

```swift
@State private var isModalOpen: Bool = false

var body: some View {
    ConfirmModal(isOpen: $isModalOpen, onConfirm: handleConfirm)
}

func handleConfirm() async {
    // Perform confirmation action
}
```

## Behavior
- The modal displays a warning message.
- Includes an image indicating caution.
- Provides a "Cancel" button that closes the modal.
- Provides a "Confirm" button that triggers the `onConfirm` function asynchronously and then closes the modal.

