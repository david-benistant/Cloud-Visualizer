# Navigation Component for SwiftUI

This component allows for navigation between different views in a SwiftUI application. It provides functionality for managing a stack of views, including going forward, backward, and managing the history of navigation.

## Structure Overview

### 1. **NavItem**

A `NavItem` represents a single navigation item, holding a reference to a view (`component`) and its corresponding label (`label`). It conforms to the `Identifiable` and `ObservableObject` protocols.

#### Properties:
- `id`: A unique identifier for the `NavItem`.
- `label`: The label to display for the item in the navigation bar.
- `component`: The view associated with the navigation item.

#### Initializer:
```
init(component: AnyView, label: String)
```

### 2. **NavModel**

`NavModel` is the observable model that tracks the navigation state. It maintains the stack of navigation items and the history of navigation.

#### Properties:
- `navItems`: The current stack of `NavItem` objects.
- `history`: A stack to store previously visited `NavItem` objects (used for going backward and forward in navigation).
- `current`: The current view to display, based on the last item in the `navItems` stack.

#### Methods:
- `navigate(_ component: AnyView, label: String)`: Adds a new `NavItem` to the navigation stack.
- `goTo(_ item: NavItem)`: Moves to a specific navigation item and resets the history.
- `goBack()`: Goes back to the previous navigation item.
- `goForward()`: Moves forward to a previously visited item in the history.

---

## Example Usage

### Basic Navigation Example

```
struct S3View: View {
    var body: some View {
        Nav(AnyView(S3()), rootLabel: "S3")
    }
}
```

This example demonstrates using the `Nav` component to render the `S3` view as the root navigation item.

### Programmatic Navigation Example

```
@EnvironmentObject var navModel: NavModel

navModel.navigate(
    AnyView(
        S3Content(s3Client: s3Client, bucket: bucket, path: item.path!)
    ),
    label: bucket.bucket.name!
)
```

In this example, we navigate programmatically by calling `navigate` on the `NavModel` to push a new view (`S3Content`) onto the navigation stack.

---

## Customization Options

### Navigation Bar Visibility

The navigation bar can be disabled by setting the `navBar` property to `false`:

```
Nav(AnyView(S3()), rootLabel: "S3", navBar: false)
```

### Managing Navigation Stack

You can control navigation using the following methods:
- `goBack()`: Goes back one step in the navigation stack.
- `goForward()`: Goes forward one step in the history.
- `goTo(item: NavItem)`: Goes directly to a specified `NavItem`.

---

## Conclusion

The `Nav` component provides an intuitive way to manage navigation in a SwiftUI application. It maintains the navigation state, allows forward and backward navigation, and supports dynamic view navigation with programmatic control.
