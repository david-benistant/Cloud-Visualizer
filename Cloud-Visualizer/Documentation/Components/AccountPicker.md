# AccountPicker Component Documentation

## Overview
The `AccountPicker` component is a SwiftUI view designed to be used in the toolbar. It provides a dropdown menu for selecting a user account from available credentials.

## Properties

| Property        | Type                         | Description |
|----------------|-----------------------------|-------------|
| `selectedOption` | `Binding<CredentialItem>`   | The currently selected credential. |

## Initialization

```swift
@State private var selectedCredential: CredentialItem

var body: some View {
    AccountPicker(selectedOption: $selectedCredential, type: "someType")
}
```

## Behavior
- Displays a dropdown menu populated with credentials from `CredentialsViewModel`.
- If no credential is selected, it defaults to the first available credential.
- Automatically sets the selected credential as the current credential in `CredentialsViewModel`.
- Designed for use in the toolbar to facilitate quick account selection.

