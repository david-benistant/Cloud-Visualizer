import SwiftUI
import AWSDynamoDB

struct TableListViewer: View {
    @ObservedObject var item: TableItem
    let editable: Bool
    let required: Bool
    let removeFunction: (() -> Void)?
    @Binding var errorCount: Int
    let allowedTypes: [FieldTypes]

    @State private var selectedType: FieldTypes? = .string

    init(item: TableItem, editable: Bool, required: Bool, removeFunction: (() -> Void)? = nil, errorCount: Binding<Int>, allowedTypes: [FieldTypes]) {
        self.item = item
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
                    Text("List:")
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
                        let keyBinding = Binding<String?>(
                            get: { String(index) },
                            set: { _ in }
                        )
                        TableValueEditor(item: ((item.value as? [TableItem])![index]), editable: self.editable, required: false, labelEditable: false, key: keyBinding, removeFunction: {
                            if var fields = (item.value as? [TableItem]) {
                                fields.remove(at: index)
                                item.value = fields
                            }
                        }, displayEmpty: false, errorCount: $errorCount, allowedTypes: self.allowedTypes)
                    }
                }
                HStack {
                    Button(action: {
                        if selectedType != nil {
                            if var fields = (item.value as? [TableItem]) {
                                fields.append(TableItem(type: selectedType!, value: defaultFieldsValue(selectedType!)))
                                item.value = fields
                            }
                        }
                    }
                    ) {
                        Image(systemName: "plus")
                    }
                    .disabled(selectedType == nil)
                    Picker("", selection: $selectedType) {
                        ForEach(allowedTypes) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .frame(width: 100)
                }
                .frame(width: 500, alignment: .leading)
                .padding(.leading, 10)
            }
            .padding(.leading, 5)
        }
    }
}
