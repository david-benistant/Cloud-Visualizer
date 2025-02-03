import SwiftUI
import AWSDynamoDB


struct DynamoCreateTable: View {
    @Binding var isOpen: Bool
    @ObservedObject var tableItems: TableModel
    let dynamoClient: DynamoClientWrapper
    @State private var error: String?
    
    @State private var tableName: String = ""
    
    @State private var partitionKeyType: FieldTypes = .string
    @State private var sortKeyType: FieldTypes = .string
    @State private var partitionKey: String = ""
    @State private var sortKey: String = ""
    @State private var errorCount: Int = 0
    
    private func typeToDynamoType(type: FieldTypes) -> DynamoDBClientTypes.ScalarAttributeType {
        if (type == .string) {
            return .s
        } else if (type == .number) {
            return .n
        } else {
            return .b
        }
    }
    
    private func confirm()  {
        Task {
            do {
                let pKey = (partitionKey, typeToDynamoType(type: partitionKeyType))
                var sKey: (String, DynamoDBClientTypes.ScalarAttributeType)? = nil
                
                if (!sortKey.isEmpty) {
                    sKey = (sortKey, typeToDynamoType(type: sortKeyType))
                }
                _ = try await createDynamoTable(client: dynamoClient, tableName: tableName, partitionKey: pKey, sortKey: sKey)
                
                tableItems.items.append(TableLine(items: [
                    TableItem(type: .string, value: tableName),
                    TableItem(type: .string, value: "CREATING" ),
                    TableItem(type: .size, value: 0)
                ]))
                tableItems.objectWillChange.send()
                isOpen = false
            } catch let error as DynamoError{
                self.error = error.message
            }
        }
    }
    
    private func isDisabled() -> Bool {
        if (partitionKey.isEmpty || tableName.isEmpty) {
            return true
        }
        
        if !verifContent(type: partitionKeyType, value: partitionKey) {
            return true
        }
        
        if !verifContent(type: sortKeyType, value: sortKey) {
            return true
        }
        return false
    }
    
    private func verifContent(type: FieldTypes, value: String) -> Bool {
        if value.count > 255 {
            return false
        }
        
        if (type == .number) {
            let numberRegex = "^-?\\d*$"
            let predicate = NSPredicate(format: "SELF MATCHES %@", numberRegex)

            if value.isEmpty {
                return false
            } else if !predicate.evaluate(with: value) {
                return false
            }
        } else if (type == .binary) {
            if Data(base64Encoded: value) == nil {
                return false
            }
        }
        return true
    }
    
    var body: some View {
        VStack {
            ModalHeader(title: "Create table", errorMessage: $error)
            
            Spacer()
            TextInput(label: "Table name", disabled: false, field: $tableName)
                .padding(.trailing, 108)
            HStack {
                TextInput(label: "Partition key", disabled: false, field: $partitionKey, foregroundColor: verifContent(type: partitionKeyType, value: partitionKey) ? .primary : .red)
                
                Picker("", selection: $partitionKeyType) {
                    Text(FieldTypes.string.rawValue).tag(FieldTypes.string)
                    Text(FieldTypes.number.rawValue).tag(FieldTypes.number)
                    Text(FieldTypes.binary.rawValue).tag(FieldTypes.binary)
                }
                .frame(width: 100)
            }
            
            HStack {
                TextInput(label: "Sort key", disabled: false, field: $sortKey, foregroundColor: verifContent(type: sortKeyType, value: sortKey) ? .primary : .red)
                
                Picker("", selection: $sortKeyType) {
                    Text(FieldTypes.string.rawValue).tag(FieldTypes.string)
                    Text(FieldTypes.number.rawValue).tag(FieldTypes.number)
                    Text(FieldTypes.binary.rawValue).tag(FieldTypes.binary)
                }
                .frame(width: 100)
            }

            Spacer()
            
            HStack {
                Button(action: {
                    isOpen = false
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
        .frame(width: 400, height: 300)
        .padding()
        
        
        
    }
    
}
