import SwiftUI
import AWSDynamoDB

struct DynamoContent: View {
    let dynamoClient: DynamoClientWrapper
    let table: DynamoDBClientTypes.TableDescription

    @State private var isEditItemOpen: Bool = false
    @State private var isAddItemOpen: Bool = false

    @ObservedObject private var tableItems: TableModel

    init (dynamoClient: DynamoClientWrapper, table: DynamoDBClientTypes.TableDescription) {
        self.dynamoClient = dynamoClient
        self.table = table
        self.tableItems = TableModel()
    }

    private var sideBarItems: [TableSideBarItem] {
        [
            TableSideBarItem(
                name: "Add",
                icon: "plus",
                action: { self.isAddItemOpen = true }
            ),
            TableSideBarItem(
                name: "Edit",
                icon: "pencil",
                action: { self.isEditItemOpen = true },
                disabled: isOnlyOneItemSelected()
            )
        ]
    }

    private func isOnlyOneItemSelected() -> Bool {
        return tableItems.items.filter {item in item.isSelected == true}.count != 1
    }

    private func updateLineCallback(newLine: TableLine, newTableModel: TableModel, originalLine: TableLine, originalTableModel: TableModel) async -> String? {
        var changes = false
        var key: [String: DynamoDBClientTypes.AttributeValue] = [:]
        var oldKey: [String: DynamoDBClientTypes.AttributeValue] = [:]
        var values: [String: DynamoDBClientTypes.AttributeValue] = [:]
        var remove: [String] = []

        table.keySchema?.forEach { keySchema in
            let valueIndex = newTableModel.tableConfig.firstIndex(where: { $0.label == keySchema.attributeName })
            let valueItem = newLine.items[valueIndex!]
            let originalValue = originalLine.items[valueIndex!]

            if (valueItem.value! as? AnyHashable)?.hashValue != (originalValue.value! as? AnyHashable)?.hashValue {
                changes = true
            }
            key[keySchema.attributeName!] = dynamoTableValueToValue(value: valueItem)
            oldKey[keySchema.attributeName!] = dynamoTableValueToValue(value: originalValue)
        }

        newTableModel.tableConfig.enumerated().forEach { index, config in
            if key[config.label] == nil {
                let valueItem = newLine.items[index]
                if valueItem.value != nil {
                    values[config.label] = dynamoTableValueToValue(value: valueItem)
                } else {
                    remove.append(config.label)
                }
            }
        }

        do {
            if !changes {
                if values.isEmpty && remove.isEmpty {
                    return nil
                }
                _ = try await updateDynamoItem(client: dynamoClient, table: table, key: key, values: values, remove: remove)
            } else {
                var merged: [String: DynamoDBClientTypes.AttributeValue] = key
                merged.merge(values) { (_, new) in new }
                _ = try await createDynamoItem(client: dynamoClient, table: table, values: merged)
                _ = try await deleteDynamoItem(client: dynamoClient, table: table, key: oldKey)
            }
        } catch {
            return "Error while updating item"
        }
        return nil
    }

    private func createLineCallback(newLine: TableLine, newTableModel: TableModel, originalLine: TableLine, originalTableModel: TableModel) async -> String? {
        var values: [String: DynamoDBClientTypes.AttributeValue] = [:]
        newTableModel.tableConfig.enumerated().forEach { index, config in
            let valueItem = newLine.items[index]
            if valueItem.value != nil {
                values[config.label] = dynamoTableValueToValue(value: valueItem)
            }
        }

        do {
            _ = try await createDynamoItem(client: dynamoClient, table: table, values: values)
            originalTableModel.items.insert(newLine, at: 0)
        } catch {
            return "Error while creating item"
        }

        return nil
    }

    private func initDefaultLine() -> TableLine {
        let out: TableLine = TableLine()

        table.attributeDefinitions?.forEach { attribute in
            var type: FieldTypes = .string
            switch attribute.attributeType {
            case .n:
                type = .number
            case .s:
                type = .string
            case .b:
                type = .binary
            default:
                type = .string

            }
            out.items.append(TableItem(type: type, value: defaultFieldsValue(type)))
        }
        return out
    }

    var body: some View {
        Table(tableModel: tableItems, sideBarItems: sideBarItems)
            .onAppear {
                tableItems.loadContentFunction = { _ in
                    Task {
                        do {
                            let tableContent = try await scanDynamoTable(client: dynamoClient, tableName: table.tableName!)
                            let tableConfigItem = wrapDynamoScan(scanOutput: tableContent, table: table)
                            tableItems.tableConfig = tableConfigItem.0
                            tableItems.items = tableConfigItem.1
                        } catch {
                            print(error)
                        }
                    }
                }
            }
            .sheet(isPresented: $isEditItemOpen) {
                TableLineViewer(isOpen: $isEditItemOpen, line: tableItems.items.first(where: { $0.isSelected })!, tableModel: tableItems, confirmFunction: updateLineCallback, allowedTypes: [.string, .number, .boolean, .binary, .null, .string_set, .number_set, .binary_set, .list, .map])
            }
            .sheet(isPresented: $isAddItemOpen) {
                TableLineViewer(isOpen: $isAddItemOpen, line: initDefaultLine(), tableModel: tableItems, confirmFunction: createLineCallback, allowedTypes: [.string, .number, .boolean, .binary, .null, .string_set, .number_set, .binary_set, .list, .map])
            }

    }
}
