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

    var body: some View {
        Table(tableModel: tableItems, searchBarFunction: searchFunction)
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
    }
}
