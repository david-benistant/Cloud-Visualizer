import SwiftUI
import AWSS3
import Foundation

enum FieldTypes: String, CaseIterable, Identifiable {
    case date = "date"
    case string = "string"
    case size = "size"
    case number = "number"
    case boolean = "boolean"
    case binary = "binary"
    case null = "null"
    case list = "list"
    case map = "map"
    case string_set = "string set"
    case number_set = "number set"
    case binary_set = "binary set"
    case boolean_set = "boolean set"
    case size_set = "size set"
    case date_set = "date set"

    var id: String { self.rawValue }
}

func getSetPrimitiveType(_ fieldType: FieldTypes) -> FieldTypes {
    switch fieldType {
    case .string_set:
        return .string
    case .number_set:
        return .number
    case .binary_set:
        return .binary
    case .boolean_set:
        return .boolean
    case .size_set:
        return .size
    case .date_set:
        return .date
    default:
        return fieldType
    }
}

func defaultFieldsValue(_ fieldType: FieldTypes) -> Any? {
    switch fieldType {
    case .binary:
        return Data()
    case .null:
        return 0
    case .string:
        return ""
    case .number:
        return 0
    case .boolean:
        return false
    case .date:
        return Date()
    case .size:
        return 0
    case .string_set, .binary_set, .boolean_set, .number_set, .size_set, .date_set:
        return []
    case .list:
        return []
    case .map:
        return []
    }
}

class TableItem: NSCopying, Hashable, Identifiable, Equatable, ObservableObject {
    private let _id: UUID = UUID()
    @Published var type: FieldTypes
    @Published var value: Any?

    init(type: FieldTypes, value: Any? = nil) {
        self.type = type
        self.value = value
    }

    static func ==(lhs: TableItem, rhs: TableItem) -> Bool {
        if (lhs.value == nil && rhs.value != nil) || (lhs.value != nil && rhs.value == nil) {
            return false
        }
        if lhs.value == nil && rhs.value == nil {
            return lhs.id == rhs.id
        }
        return lhs.id == rhs.id && (lhs.value! as? AnyHashable)?.hashValue == (rhs.value! as? AnyHashable)?.hashValue

    }

    var id: UUID {
        return _id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TableItem(type: type, value: value)
        return copy
    }
}

class TableLine: NSCopying, Identifiable, ObservableObject, Equatable, Hashable {
    private let _id: UUID = UUID()
    @Published var items: [TableItem] = []
    @Published var isSelected: Bool = false
    @Published var action: ((TableLine) -> Void) = { _ in }
    @Published var additional: Any?
    @Published var disabled: Bool = false

    var id: UUID {
        return _id
    }

    static func ==(lhs: TableLine, rhs: TableLine) -> Bool {
        return lhs.id == rhs.id
    }
    init(items: [TableItem] = [], action: ((TableLine) -> Void)? = nil, additional: Any? = nil, disabled: Bool = false) {
        self.items = items
        self.isSelected = isSelected
        self.action = action ?? { _ in }
        self.additional = additional
        self.disabled = disabled
    }

    init(items: [TableItem] = [], additional: Any? = nil, disabled: Bool = false) {
        self.items = items
        self.isSelected = isSelected
        self.action = { _ in }
        self.additional = additional
        self.disabled = disabled
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TableLine(items: items.map { item in item.copy() as! TableItem}, action: action, additional: additional, disabled: disabled)
        copy.isSelected = isSelected
        return copy
    }
}

struct TableConfig: Hashable, Identifiable {
    private let _id: UUID = UUID()
    var label: String
    var minWidth: CGFloat?
    var maxWidth: CGFloat?
    var alignment: Alignment = .leading
    var editable: Bool = true               // edit the item
    var labelEditable: Bool = false         // edit the label
    var required: Bool = false              // is the item required when edited

    var id: UUID {
        return _id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class TableModel: NSObject, NSCopying, ObservableObject {
    @Published var items: [TableLine]
    @Published var tableConfig: [TableConfig]
    @Published var nbPages: Int = 1
    @Published var currentPage: Int = 1
    @Published var loadContentFunction: ((Int) -> Void)?
    @Published var editable = false                             // edit the columns

    init(tableConfig: [TableConfig] = [], items: [TableLine] = [], loadContentFunction: ((Int) -> Void)? = nil, nbPages: Int = 1) {
        self.items = items
        self.tableConfig = tableConfig
        self.nbPages = nbPages
        self.loadContentFunction = loadContentFunction
    }

    func reload() {
        if let loadContent = self.loadContentFunction {
            loadContent(currentPage)
        }
    }

    func reInit() {
        self.nbPages = 1
        self.currentPage = 1
        self.reload()
    }

    func clearSelected() {
        items.forEach { item in
            item.isSelected = false
        }
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = TableModel(
            tableConfig: tableConfig,
            items: items,
            loadContentFunction: loadContentFunction,
            nbPages: nbPages
        )
        copy.currentPage = currentPage
        copy.editable = editable
        return copy
    }
}
