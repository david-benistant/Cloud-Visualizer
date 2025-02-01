# PasswordInput Component Documentation

## Overview
The `PasswordInput` component is a SwiftUI view designed to create a labeled secure text input field with an optional disabled state.

## Properties

| Property  | Type     | Description |
|-----------|---------|-------------|
| `label`   | `String` | The label displayed next to the secure text field. |
| `disabled` | `Bool` | Determines whether the text field is interactive. If `true`, the input is disabled. |
| `field` | `Binding<String>` | A binding to a string that holds the text entered in the field. |

## Usage

```swift
@State private var password: String = ""

var body: some View {
    PasswordInput(label: "Password", disabled: false, field: $password)
}
```

## Behavior
- The component supports password input with a dynamic binding.
- The field can be disabled by setting `disabled` to `true`, preventing user interaction.
- Uses `SecureField` to obscure the text entered by the user.