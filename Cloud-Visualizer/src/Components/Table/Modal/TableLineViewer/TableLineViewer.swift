import SwiftUI
import AWSDynamoDB

struct TableValueEditor: View {
    @ObservedObject var item: TableItem
    let editable: Bool
    let required: Bool
    let labelEditable: Bool
    @Binding var key: String?
    var removeFunction: (() -> Void)?
    let displayEmpty: Bool
    @Binding var errorCount: Int
    let allowedTypes: [FieldTypes]
    var keyVerifFunction: ((String) -> Bool)?
//    let tableConfigs: [TableConfig]? = nil

//    @EnvironmentObject var tableModel: TableModel
//    @EnvironmentObject var line: TableLine

    @State var textField: String = ""
    @State var error: Bool = false
    @State var keyError = false
    @State var keyTextField: String = ""

    private func validateNumber(_ text: String) -> Bool {
        let numberRegex = "^-?\\d*$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", numberRegex)

        if text.isEmpty {
            return false
        } else if !predicate.evaluate(with: text) {
            return false
        } else {
            return true
        }
    }

    private func validateSize(_ text: String) -> Bool {
        let numberRegex = "^?\\d*$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", numberRegex)

        if text.isEmpty {
            return false
        } else if !predicate.evaluate(with: text) {
            return false
        } else {
            return true
        }
    }

    private func setError(from: Bool, to: Bool ) -> Bool {
        if from == false && to == true {
            self.errorCount += 1
        } else if from == true && to == false {
            self.errorCount -= 1
        }
        return to
    }

    var body: some View {
        HStack {
            if self.key != nil {
                TextField("", text: $keyTextField)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(width: 90, alignment: .topLeading)
                    .disabled(!labelEditable)
                    .foregroundColor(keyError ? .red : .primary)
                    .onChange(of: keyTextField) {
                        self.key = keyTextField

                        if let verfiFunc = keyVerifFunction {
                            self.keyError = setError(from: self.keyError, to: verfiFunc(keyTextField))
                        }
                    }
                    .onAppear {
                        keyTextField = self.key!
                    }
            }
            if self.item.value == nil {
                Button(action: {
                    self.item.value = defaultFieldsValue(self.item.type)
                }
                ) {
                    Image(systemName: "plus")
                }
            } else {
                if self.item.type == .string {
                    TextField("", text: Binding<String>(
                        get: {
                            self.item.value as? String ?? ""
                        },
                        set: { newValue in
                            self.item.value = newValue
                        }
                    ))
                    .disabled(!editable)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 300)
                    .foregroundColor(error ? .red : .primary)
                }
                if self.item.type == .date {
                    DatePicker("Date", selection: Binding<Date>(
                        get: {
                            (self.item.value as? Date)!
                        },
                        set: { newValue in
                            self.item.value = newValue
                        }
                    ), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .disabled(!editable)
                }
                if self.item.type == .boolean {
                    Toggle("", isOn: Binding<Bool>(
                        get: {
                            (self.item.value as? Bool)!
                        },
                        set: { newValue in
                            self.item.value = newValue
                        }
                    ))
                }
                if self.item.type == .number {
                    TextField("", text: $textField)
                        .onChange(of: textField) {
                            if !validateNumber(textField) {
                                error = setError(from: self.error, to: true)
                            } else {
                                error = setError(from: self.error, to: false)
                                self.item.value = Int(textField)
                            }
                        }
                        .foregroundColor(error ? .red : .primary)
                        .onAppear {
                            textField = String(describing: self.item.value as! Int)
                        }
                        .frame(width: 300)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                if self.item.type == .size {
                    TextField("", text: $textField)
                        .onChange(of: textField) {
                            if !validateSize(textField) {
                                error = setError(from: self.error, to: true)
                            } else {
                                error = setError(from: self.error, to: false)
                                self.item.value = Int(textField)
                            }
                        }
                        .foregroundColor(error ? .red : .primary)
                        .onAppear {
                            textField = String(describing: self.item.value as! Int)
                        }
                        .frame(width: 260)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Text("bytes")
                }
                if self.item.type == .null {
                    Text("NULL")
                }
                if self.item.type == .binary {
                    if let data = (self.item.value as? Data) {
                        TextField("", text: $textField)
                            .onChange(of: textField) {
                                if let base64 = Data(base64Encoded: textField) {
                                    error = setError(from: self.error, to: false)
                                    self.item.value = base64
                                } else {
                                    error = setError(from: self.error, to: true)
                                }
                            }
                            .foregroundColor(error ? .red : .primary)
                            .onAppear {
                                textField = data.base64EncodedString()
                            }
                            .frame(width: 300)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                if self.item.type.rawValue.contains("set") {
                    if (self.item.value as? [TableItem]) != nil {
                        TableSetViewer(item: item, type: getSetPrimitiveType(self.item.type), editable: editable, required: required, removeFunction: removeFunction, errorCount: $errorCount, allowedTypes: self.allowedTypes)
                    }
                }
                if self.item.type == .list {
                    if (self.item.value as? [TableItem]) != nil {
                        TableListViewer(item: item, editable: editable, required: required, removeFunction: removeFunction, errorCount: $errorCount, allowedTypes: self.allowedTypes)
                    }
                }
                if self.item.type == .map {
                    if (self.item.value as? [(key: String, value: TableItem)]) != nil {
                        TableMapViewer(item: item, editable: editable, required: required, removeFunction: removeFunction, errorCount: $errorCount, allowedTypes: self.allowedTypes)
                    }
                }
                if !required {
                    if !self.item.type.rawValue.contains("set") && self.item.type != .list && self.item.type != .map {
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
            }
        }
        .frame(width: 500, alignment: .leading)
    }
}

private struct EditTableLineContent: View {
    @ObservedObject var line: TableLine
    let displayEmpty: Bool
    let addNewItem: Bool
    @Binding var errorCount: Int
    let allowedTypes: [FieldTypes]

    @EnvironmentObject var tableModel: TableModel

    var body: some View {
        List {
            VStack {
                ForEach(Array(tableModel.tableConfig.enumerated()), id: \.element.id) { index, config in
                    if index < line.items.count {
                        if line.items[index].value != nil || displayEmpty {
                            let keyBinding = Binding<String?>(
                                get: { config.label },
                                set: { newValue in
                                    tableModel.tableConfig[index].label = newValue!
                                }
                            )
                            HStack {
                                Divider()
                                TableValueEditor(item: line.items[index], editable: config.editable, required: config.required, labelEditable: config.labelEditable, key: keyBinding, removeFunction: {
                                    line.items[index].value = nil
                                    line.objectWillChange.send()
                                }, displayEmpty: displayEmpty, errorCount: $errorCount, allowedTypes: self.allowedTypes, keyVerifFunction: { key in
                                    for (i, _) in tableModel.tableConfig.enumerated().filter({ $0.element.label == key }) {
                                        if line.items[i].id != line.items[index].id && (line.items[i].value != nil || displayEmpty) {
                                            return true
                                        }
                                    }
                                    return false
                                })
                                .padding(.vertical, 5)
                            }
                        }
                    }
                }
            }
        }
    }
}
struct TableLineViewer: View {
    @Binding var isOpen: Bool
    @ObservedObject var line: TableLine
    @ObservedObject var tmpLine: TableLine
    @ObservedObject var tableModel: TableModel
    @ObservedObject var tmpTableModel: TableModel

    let confirmFunction: (TableLine, TableModel, TableLine, TableModel) async -> String?
    let displayEmpty: Bool = false
    let addNewItem: Bool = true

    @State private var errorMessage: String?
    @State private var selectedType: FieldTypes?

    @State private var errorCount: Int = 0

    private let allowedTypes: [FieldTypes]

    init (isOpen: Binding<Bool>, line: TableLine, tableModel: TableModel, confirmFunction: @escaping (TableLine, TableModel, TableLine, TableModel) async -> String?, allowedTypes: [FieldTypes]? = nil) {
        self._isOpen = isOpen
        self.line = line
        self.tmpLine = line.copy() as! TableLine
        self.tableModel = tableModel
        self.tmpTableModel = tableModel.copy() as! TableModel
        self.confirmFunction = confirmFunction
        if let tmp = allowedTypes {
            self.allowedTypes = tmp
        } else {
            self.allowedTypes = FieldTypes.allCases
        }
    }

    private func isDisabled() -> Bool {
        return self.errorCount > 0
    }

    var body: some View {
        VStack {
            ModalHeader(title: "Edit item", errorMessage: $errorMessage)
                .padding(.bottom)

            EditTableLineContent(line: tmpLine, displayEmpty: displayEmpty, addNewItem: addNewItem, errorCount: $errorCount, allowedTypes: self.allowedTypes)
                .environmentObject(tmpTableModel)
                .environmentObject(tmpLine)

            HStack {
                Button(action: {
                    if selectedType != nil {
                        if tmpTableModel.tableConfig.count > tmpLine.items.count {
                            for _ in 0..<(tmpTableModel.tableConfig.count - tmpLine.items.count) {
                                tmpLine.items.append(TableItem(type: .string))
                            }
                        }
                        tmpTableModel.tableConfig.append(TableConfig(label: "", labelEditable: true))
                        tmpLine.items.append(TableItem(type: selectedType!, value: defaultFieldsValue(selectedType!)))
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
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            HStack {
                Button(action: {
                    self.isOpen = false
                    print("cancel")
                }) {
                    Text("Cancel")
                }
                Button(action: {
                    confirm()
                }) {
                    Text("Confirm")
                }
                .disabled(isDisabled())
                .keyboardShortcut(.defaultAction)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(width: 600, height: 400, alignment: .leading)
        .padding()
    }

    private func confirm () {
        var tableSize = tmpTableModel.tableConfig.count

        if tableSize > tmpLine.items.count {
            for _ in tmpLine.items.count..<tableSize {
                tmpLine.items.append(TableItem(type: .string, value: nil))
            }
        }

        for i in 0..<tableSize {
            for j in i..<tableSize {
                if i != j && i < tableSize && j < tableSize {
                    if tmpTableModel.tableConfig[i].label == tmpTableModel.tableConfig[j].label {
                        tmpLine.items[i].value =  tmpLine.items[j].value
                        tmpLine.items[i].type =  tmpLine.items[j].type
                        tmpTableModel.tableConfig.remove(at: j)
                        tmpLine.items.remove(at: j)
                        tableSize -= 1
                    }
                }
            }
        }
        Task {
            if let error = await confirmFunction(self.tmpLine, self.tmpTableModel, self.line, self.tableModel) {
                errorMessage = error
            } else {
                self.line.items = self.tmpLine.items
                self.tableModel.tableConfig = self.tmpTableModel.tableConfig
                self.isOpen = false
            }
        }
    }
}
