import SwiftUI
import AWSDynamoDB

struct TableSetViewer: View {
    @ObservedObject var item: TableItem
    let type: FieldTypes
    let editable: Bool
    let required: Bool
    let removeFunction: (() -> Void)?
    @Binding var errorCount: Int
    let allowedTypes: [FieldTypes]

    @State var key: String?

    init(item: TableItem, type: FieldTypes, editable: Bool, required: Bool, removeFunction: (() -> Void)? = nil, errorCount: Binding<Int>, allowedTypes: [FieldTypes]) {
        self.item = item
        self.type = type
        self.editable = editable
        self.required = required
        self.removeFunction = removeFunction
        self._errorCount = errorCount
        self.allowedTypes = allowedTypes
    }

    var body: some View {
        HStack {
            Divider()
            VStack {
                HStack {
                    Text("Set: " + type.rawValue)
                    if !required {
                        if let rmFunc = removeFunction {
                            Button(action: {
                                rmFunc()
                            }
                            ) {
                                Image(systemName: "minus")
                                    .frame(width: 10)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .frame(width: 500, alignment: .leading)
                .padding(.leading, 10)
                if item.value != nil {
                    ForEach((item.value as? [TableItem])!.indices, id: \.self) { index in
                        TableValueEditor(item: ((item.value as? [TableItem])![index]), editable: self.editable, required: false, labelEditable: false, key: $key, removeFunction: {
                            if var fields = (item.value as? [TableItem]) {
                                fields.remove(at: index)
                                item.value = fields
                            }
                        }, displayEmpty: false, errorCount: $errorCount, allowedTypes: self.allowedTypes)
                    }
                }
                HStack {
                    Button(action: {
                        if var fields = (item.value as? [TableItem]) {
                            fields.append(TableItem(type: type, value: defaultFieldsValue(type)))
                            item.value = fields
                        }
                    }
                    ) {
                        Image(systemName: "plus")
                    }
                }
                .frame(width: 500, alignment: .leading)
                .padding(.leading, 10)
            }
            .padding(.leading, 5)
        }
    }
}
