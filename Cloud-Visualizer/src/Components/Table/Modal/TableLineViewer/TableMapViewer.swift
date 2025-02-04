import SwiftUI
import AWSDynamoDB

struct TableMapViewer: View {
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
                    Text("Map:")
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

                    ForEach((item.value as? [(key: String, value: TableItem)])!.indices, id: \.self) { index in
                        let keyBinding = Binding<String?>(
                            get: { (item.value as? [(key: String, value: TableItem)])![index].key },
                            set: { newValue in
                                if newValue != nil {
                                    if var fields = (item.value as? [(key: String, value: TableItem)]) {
                                        fields[index].key = newValue!
                                        item.value = fields
                                    }
                                }
                            }
                        )

                        TableValueEditor(item: ((item.value as? [(key: String, value: TableItem)])![index].value), editable: self.editable, required: false, labelEditable: true, key: keyBinding, removeFunction: {
                            if var fields = (item.value as? [(key: String, value: TableItem)]) {
                                fields.remove(at: index)
                                item.value = fields
                            }
                        }, displayEmpty: false, errorCount: $errorCount, allowedTypes: self.allowedTypes, keyVerifFunction: { key in
                            if let fields = (item.value as? [(key: String, value: TableItem)]) {
                                if fields.enumerated().filter({ $0.element.key == key }).count > 1 {
                                    return true
                                }
                            }
                            return false
                        })
                    }
                }
                HStack {
                    Button(action: {
                        if selectedType != nil {
                            if var fields = (item.value as? [(key: String, value: TableItem)]) {
                                fields.append((key: "", value: TableItem(type: selectedType!, value: defaultFieldsValue(selectedType!)) ))
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
