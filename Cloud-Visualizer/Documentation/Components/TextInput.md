# TextInput Component Documentation

## Overview
The `TextInput` component is a SwiftUI view designed to create a labeled text input field with an optional disabled state.

## Properties

| Property  | Type     | Description |
|-----------|---------|-------------|
| `label`   | `String` | The label displayed next to the text field. |
| `disabled` | `Bool` | Determines whether the text field is interactive. If `true`, the input is disabled. |
| `field` | `Binding<String>` | A binding to a string that holds the text entered in the field. |

## Usage

```swift
@State private var text: String = ""

var body: some View {
    TextInput(label: "Username", disabled: false, field: $text)
}
```

## Behavior
- The component supports text input with a dynamic binding.
- The field can be disabled by setting `disabled` to `true`, preventing user interaction.

