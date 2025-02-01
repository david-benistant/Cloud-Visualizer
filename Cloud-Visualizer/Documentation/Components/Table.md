# Table Component for SwiftUI

This component provides a table structure that allows displaying rows of data in a SwiftUI view, with support for optional sidebars, search functionality, and pagination.

## Structure Overview

### 1. **Table** View

The main `Table` view displays a table with optional sidebar items and a search bar functionality. It uses the `TableModel` to manage the data and provide interactivity.

#### Initializer:
```
init(tableModel: TableModel, sideBarItems: [TableSideBarItem]? = nil, searchBarFunction: ((TableLine, String) -> Bool)? = nil)
```

#### Body:
- Displays the sidebar if `sideBarItems` are provided and not empty.
- Displays the searchbar if `searchBarFunction` is provided.

---

### 2. **TableItem** Struct

The `TableItem` represents a single item in a table row. It can store any type of value and includes its type information.

#### Properties:
- `type`: The type of the field represented by the `TableItem`.
- `value`: The actual value stored by the `TableItem`.

#### Methods:
- `==`: Compares two `TableItem` instances for equality.
- `hash`: Computes a hash value for the `TableItem`.
- `copy`: Creates a copy of the `TableItem`.

---

### 3. **TableLine** Struct

A `TableLine` represents a row in the table, containing multiple `TableItem` objects. It also handles selection, actions, and any additional data for the row.

#### Properties:
- `items`: A list of `TableItem` objects.
- `isSelected`: A boolean indicating if the row is selected.
- `action`: A closure that defines the action when the row is clicked.
- `additional`: Any additional data associated with the row.
- `disabled`: A boolean indicating if the row is disabled.

#### Methods:
- `==`: Compares two `TableLine` instances for equality.
- `hash`: Computes a hash value for the `TableLine`.
- `copy`: Creates a copy of the `TableLine`.

---

### 4. **TableConfig** Struct

The `TableConfig` defines the configuration for a column in the table.

#### Properties:
- `label`: The label for the column.
- `minWidth`: The minimum width of the column.
- `maxWidth`: The maximum width of the column.
- `alignment`: The alignment of the column (e.g., `.leading`, `.center`).
- `editable`: A boolean indicating if the column is editable.
- `labelEditable`: A boolean indicating if the column's label is editable.
- `required`: A boolean indicating if the column is required when edited.

#### Methods:
- `hash`: Computes a hash value for the `TableConfig`.

---

### 5. `TableSideBarItem` Struct

The `TableSideBarItem` struct represents an item in a sidebar for a table view. It includes a label, an icon, an associated action, and a state to determine if it is disabled.

#### Properties

- `name`: The label displayed for the sidebar item.
- `icon`: A system icon used for the sidebar item. The default value is `"star"`. You can customize this with any valid SF Symbol name.
- `action`: A closure that gets triggered when the sidebar item is selected. By default, it is an empty closure that performs no action.
- `disabled` A flag indicating whether the sidebar item is disabled. If `true`, the item will be unselectable. The default value is `false`.


---

### 6. **TableModel** Struct

The `TableModel` manages the entire table's data, configuration, and pagination.

#### Properties:
- `items`: The list of `TableLine` objects representing the rows of the table.
- `tableConfig`: The configuration for the table columns.
- `nbPages`: The total number of pages in the table (used for pagination).
- `currentPage`: The current page being displayed.
- `loadContentFunction`: A closure for loading content for a specific page.
- `editable`: A boolean indicating if the table's columns are editable.

#### Methods:
- `reload`: Reloads the content for the current page.
- `reInit`: Reinitializes the pagination to the first page.
- `clearSelected`: Clears the selection of all rows.
- `copy`: Creates a copy of the `TableModel`.

---

### Example Usage

#### Custom Sidebar and Search Bar:
```swift

fileprivate let tableConfig = [
    TableConfig(label: "First Name"),
    TableConfig(label: "Last Name", maxWidth: 300, alignment: .trailing)
]

let tableLine = TableLine(
    items: [
        TableItem(type: .text, value: "John"),
        TableItem(type: .text, value: "Doe")
    ],
    action: { line in print("Row selected: \(line.items)") }
)

struct CustomTableView: View {
    @ObservedObject private var tableItems: TableModel = TableModel(
        items: [tableLine],
        tableConfig: tableConfig
    )

    private let tableConfi 

    var body: some View {
        Table(
            tableModel: tableModel,
            sideBarItems: [
                TableSideBarItem(label: "Item 1", icon: "plus", action: { print("Item 1 selected") }),
                TableSideBarItem(label: "Item 2", icon: "minus", action: { print("Item 2 selected") })
            ],
            searchBarFunction: { line, searchString in
                guard let item = line.items.first(where: { $0.value as? String == searchString }) else {
                    return false
                }
                return true
            }
        )
    }
}
```

---

## Conclusion

This SwiftUI table component is highly flexible and can be customized with sidebars, search functionality, pagination, and actions on rows. The `TableModel` class provides the necessary structure to manage data, while the individual table items (`TableItem`, `TableLine`) allow for easy data representation and interaction within each row. 

By using the provided `TableConfig`, users can further fine-tune column behavior, including making them editable, setting their width constraints, and more.

This structure is ideal for applications that require table views with complex data handling, pagination, and customizable interactions.
