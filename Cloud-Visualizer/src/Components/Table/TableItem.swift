import SwiftUI
import AWSS3

enum FieldTypes: String {
    case date
    case string
    case size
}

struct TableFieldItem: Hashable, Identifiable, Equatable {
    private let _id: UUID = UUID()
    var value: Any? = nil
    
    
    static func ==(lhs: TableFieldItem, rhs: TableFieldItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: UUID {
        return _id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}


class TableItem : Identifiable, ObservableObject, Equatable, Hashable {
    private let _id: UUID = UUID()
    @Published var fields: [TableFieldItem] = []
    @Published var isSelected: Bool = false
    @Published var action: ((TableItem) -> Void) = { item in }
    @Published var additional: Any? = nil
    @Published var disabled: Bool = false
        
    var id: UUID {
        return _id
    }
    
    static func ==(lhs: TableItem, rhs: TableItem) -> Bool {
        return lhs.id == rhs.id
    }
    init(fields: [TableFieldItem] = [], action: ((TableItem) -> Void)? = nil, additional: Any? = nil, disabled: Bool = false) {
        self.fields = fields
        self.isSelected = isSelected
        self.action = action ?? { _ in }
        self.additional = additional
        self.disabled = disabled
    }
    
    init(fields: [TableFieldItem] = [], additional: Any? = nil, disabled: Bool = false) {
        self.fields = fields
        self.isSelected = isSelected
        self.action = { _ in }
        self.additional = additional
        self.disabled = disabled
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    
    
}
