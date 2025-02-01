# `TableLineViewer` View

The `TableLineViewer` view allows you to display and edit the information of a `TableLine`. It provides an interface for editing the line's items, including adding new items and confirming or canceling the changes.


The initializer for `TableLineViewer` takes several parameters that configure the view and the edit functionality.

``` swift

init(isOpen: Binding<Bool>, line: TableLine, tableModel: TableModel, confirmFunction: @escaping (TableLine, TableModel, TableLine, TableModel) async -> String?, allowedTypes: [FieldTypes]? = nil)

```


## Parameters:
- `isOpen: Binding<Bool>`
  - A binding to a boolean value indicating whether the viewer is open or closed.

- `line: TableLine`
  - The `TableLine` object that represents the line to be edited. This will be displayed in the viewer and can be modified.

- `tableModel: TableModel`
  - The `TableModel` object that holds the table data. This model is used to manage the table's content and configuration.

- `confirmFunction: @escaping (TableLine, TableModel, TableLine, TableModel) async -> String?`
  - A closure that will be executed when the user confirms the edit. It accepts the original `TableLine`, the original `TableModel`, the modified `TableLine`, and the modified `TableModel`. It returns an optional error message if the confirmation fails.

- `allowedTypes: [FieldTypes]?`
  - An optional array of `FieldTypes` that specifies the types of fields allowed to be added during the editing process. If `nil`, all available field types are allowed.

## Example Usage

```swift
TableLineViewer(
    isOpen: $isViewerOpen,
    line: lineToEdit,
    tableModel: tableModel,
    confirmFunction: confirmEdit,
    allowedTypes: [.string, .integer]
)
```
In this example, the `TableLineViewer` is initialized with the following parameters:

- `isOpen`: A binding to a boolean value (`$isViewerOpen`) that controls whether the viewer is open or closed.
- `line`: The `TableLine` (`lineToEdit`) that is being displayed and edited.
- `tableModel`: The `TableModel` (`tableModel`) containing the data for the table.
- `confirmFunction`: A closure (`confirmEdit`) that handles the confirmation logic when changes are made to the line, such as validating or saving the edits.
- `allowedTypes`: An array specifying the allowed field types for the new items in the table line, such as `.string` and `.integer`.

This setup allows the user to edit a table line while ensuring control over the types of fields that can be added and providing a mechanism to confirm the changes.