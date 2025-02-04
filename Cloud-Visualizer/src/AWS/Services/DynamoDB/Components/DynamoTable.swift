import SwiftUI
import AWSDynamoDB

private let tableConfig: [TableConfig] = [
    TableConfig(label: "Name"),
    TableConfig(label: "Status"),
    TableConfig(label: "Size", maxWidth: 100, alignment: .trailing)
    ]

struct DynamoTable: View {
    @Binding var dynamoClient: DynamoClientWrapper?
    @EnvironmentObject var navModel: NavModel
    @StateObject private var tableItems: TableModel = TableModel(tableConfig: tableConfig)
    @State private var isCreateTableOpen = false
    @State private var isDeleteModalOpen = false
    
    private var sideBarItems: [TableSideBarItem] {
        [
            TableSideBarItem(
                name: "Add",
                icon: "plus",
                action: { self.isCreateTableOpen = true }
            ),
            TableSideBarItem(
                name: "Delete",
                icon: "trash",
                action: { self.isDeleteModalOpen = true },
                disabled: isOneSelected()
            ),
        ]
    }
    
    private func isOneSelected() -> Bool {
        return !tableItems.items.contains { $0.isSelected }
    }

    private func searchFunction(item: TableLine, search: String) -> Bool {
        if let tableInfos = item.additional as? DynamoDBClientTypes.TableDescription {
            if let name = tableInfos.tableName {
                if name.lowercased().contains(search.lowercased()) {
                    return true
                }
            }
        }
        return false
    }

    private func actionFunction(_ item: TableLine) -> TableLine {
        if let tableInfos = item.additional as? DynamoDBClientTypes.TableDescription {
            item.action = { _ in
                navModel.navigate(
                    AnyView(
                        DynamoContent(dynamoClient: dynamoClient!, table: tableInfos)
                    ),
                    label: tableInfos.tableName!
                )
            }
        }
        return item
    }

    private func deleteItem() async {
        guard let dynamoClient = dynamoClient else { return }
        var remainingItems = tableItems.items
        for (index, item) in tableItems.items.enumerated().reversed() {
            if item.isSelected {
                do {
                    _ = try await deleteDynamoTable(client: dynamoClient, tableName: item.items[0].value as! String)
                    remainingItems.remove(at: index)
                } catch {
                    print(error)
                }
            }
        }
        tableItems.items = remainingItems
    }

    var body: some View {
        Table(tableModel: tableItems, sideBarItems: sideBarItems ,searchBarFunction: searchFunction)
            .onAppear {
                tableItems.loadContentFunction = {_ in
                    guard let client = dynamoClient else { return }
                    Task {
                        do {
                            let tables = try await listDynamoTables(client: client)
                            tableItems.items = try await wrapDynamoTableList(tables, client: client).map(actionFunction)

                            if tables.lastEvaluatedTableName != nil {
                                tableItems.nbPages += 1
                            }
                        } catch {
                            print(error)
                        }
                    }
                }
            }
            .onChange(of: dynamoClient) {
                tableItems.items = []
                tableItems.reInit()
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        tableItems.reload()
                    }) {
                        Image(systemName: "arrow.trianglehead.clockwise")
                    }
                }
            }
            .sheet(isPresented: $isCreateTableOpen) {
                if let client = dynamoClient {
                    DynamoCreateTable(isOpen: $isCreateTableOpen, tableItems: tableItems, dynamoClient: client)
                }
            }
            .sheet(isPresented: $isDeleteModalOpen) {
                ConfirmModal(isOpen: $isDeleteModalOpen, onConfirm: deleteItem)
            }
    }
}
