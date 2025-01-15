import SwiftUI
import AWSS3

struct TableConfigItem: Hashable, Identifiable {
    private let _id: UUID = UUID()
    var label: String
    var type: FieldTypes
    var minWidth: CGFloat? = nil
    var maxWidth: CGFloat? = nil
    var alignment: Alignment = .leading
    
    var id: UUID {
        return _id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class TableItemsModel: ObservableObject {
    @Published var items: [TableItem]
    @Published var tableConfig: [TableConfigItem]
    
    init(tableConfig: [TableConfigItem] = [], items: [TableItem] = []) {
        self.items = items
        self.tableConfig = tableConfig
    }
    
    
    func clearSelected() {
        items.forEach { item in
            item.isSelected = false
        }
    }

}
