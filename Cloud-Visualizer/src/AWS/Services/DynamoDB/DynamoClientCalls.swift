import AWSDynamoDB
import Foundation

import AWSClientRuntime
import AWSSDKIdentity
import SwiftUI
import ClientRuntime
import Smithy
import SmithyHTTPAPI

func AuthDynamo(credentials: CredentialItem,
                region: String) async -> DynamoClientWrapper? {
    do {
        let awsCredentials = AWSCredentialIdentity(
            accessKey: credentials.AWSKeyId,
            secret: credentials.AWSSecretAccessKey
        )
        let identityResolver = try StaticAWSCredentialIdentityResolver(awsCredentials)

        let configuration = try await DynamoDBClient.DynamoDBClientConfiguration(
            awsCredentialIdentityResolver: identityResolver,
            region: region,
            clientLogMode: .responseWithBody
        )

        if !credentials.endpoint.isEmpty {
            configuration.endpoint = credentials.endpoint
        }

        let client = DynamoDBClient(config: configuration)

        return DynamoClientWrapper(client: client, region: AWSRegionItem(region: region))
    } catch {
        print("Failed to configure Dynamo Client: \(error.localizedDescription)")
        return nil
    }
}

func listDynamoTables(client: DynamoClientWrapper) async throws -> ListTablesOutput {
    do {
        let input = ListTablesInput()
        let output = try await client.client.listTables(input: input)
        return output
    } catch {
        throw error
    }
}

func wrapDynamoTableList(_ tableList: ListTablesOutput,
                         client: DynamoClientWrapper) async throws -> [TableLine] {
    var output: [TableLine] = []

    if let tables = tableList.tableNames {
        for table in tables {
            let input = DescribeTableInput(tableName: table)
            let tableInfos = try await client.client.describeTable(input: input)
            let status = tableInfos.table?.tableStatus?.rawValue
            let size = tableInfos.table?.tableSizeBytes

            output.append(
                TableLine(items: [
                    TableItem(type: .string, value: table),
                TableItem(type: .string, value: status),
                TableItem(type: .size, value: size)
            ],
                      additional: tableInfos.table))
        }
    }
    return output
}

func wrapDynamoScan(scanOutput: ScanOutput,
                    table: DynamoDBClientTypes.TableDescription) -> ([TableConfig], [TableLine]) {
    var outputConfig: [(TableConfig, FieldTypes)] = []
    var outputItems: [TableLine] = []

    guard let items = scanOutput.items else { return ([], []) }
    table.keySchema?.forEach { key in
        let attribute = table.attributeDefinitions?.first(where: { $0.attributeName == key.attributeName })
        var type: FieldTypes = .string
        switch attribute!.attributeType {
        case .n:
            type = .number
        case .s:
            type = .string
        case .b:
            type = .binary
        default:
            type = .string
        }
        outputConfig.append((TableConfig(label: attribute!.attributeName!, labelEditable: false, required: true), type))
    }

    items.forEach { item in
        var outItem = (0..<outputConfig.count).map { i in
            return TableItem(type: outputConfig[i].1)
        }

        for (key, value) in item {
            let tableTypeValue = dynamoValueToTableValue(value: value)

            if tableTypeValue.0 != nil {
                if let i = outputConfig.firstIndex(where: { $0.0.label == key }) {
                    outItem[i].value = tableTypeValue.0
                    outItem[i].type = tableTypeValue.1
                } else {
                    outItem.append(TableItem(type: tableTypeValue.1, value: tableTypeValue.0))
                    outputConfig.append((TableConfig(label: key, labelEditable: true), .string))
                }
            }
        }
        outputItems.append(TableLine(
            items: outItem,
            additional: item
        ))
    }
    return (outputConfig.map { $0.0 }, outputItems)
}

func scanDynamoTable(client: DynamoClientWrapper,
                     tableName: String) async throws -> ScanOutput {
    do {
        let input = ScanInput(
            tableName: tableName
        )
        let output = try await client.client.scan(input: input)
        return output
    } catch {
        throw error
    }
}

func updateDynamoItem(client: DynamoClientWrapper,
                      table: DynamoDBClientTypes.TableDescription,
                      key: [String: DynamoDBClientTypes.AttributeValue],
                      values: [String: DynamoDBClientTypes.AttributeValue],
                      remove: [String]) async throws -> UpdateItemOutput {

    let tableName = table.tableName!

    let setExpression = values.keys.map { "#\($0) = :\($0)" }.joined(separator: ", ")

    let removeExpression = remove.map { "#\($0)" }.joined(separator: ", ")

    var updateExpression = ""
    if !setExpression.isEmpty {
        updateExpression += "SET \(setExpression)"
    }
    if !removeExpression.isEmpty {
        updateExpression += (updateExpression.isEmpty ? "" : " ") + "REMOVE \(removeExpression)"
    }

    var expressionAttributeNames = Dictionary(uniqueKeysWithValues: values.keys.map { key in
        ("#\(key)", key)
    })

    remove.forEach { key in
        expressionAttributeNames["#\(key)"] = key
    }

    let expressionAttributeValues = Dictionary(uniqueKeysWithValues: values.map { (key, value) in
        (":\(key)", value)
    })

    let input = UpdateItemInput(
        expressionAttributeNames: expressionAttributeNames,
        expressionAttributeValues: expressionAttributeValues.isEmpty ? nil : expressionAttributeValues,
        key: key,
        tableName: tableName,
        updateExpression: updateExpression
    )

    do {
        let output = try await client.client.updateItem(input: input)
        return output
    } catch {
        print(error)
        throw error
    }
}

func createDynamoItem(client: DynamoClientWrapper,
                      table: DynamoDBClientTypes.TableDescription,
                      values: [String: DynamoDBClientTypes.AttributeValue]) async throws -> PutItemOutput {
    return try await client.client.putItem(input: PutItemInput(item: values, tableName: table.tableName!))
}

func deleteDynamoItem(client: DynamoClientWrapper,
                      table: DynamoDBClientTypes.TableDescription,
                      key: [String: DynamoDBClientTypes.AttributeValue]) async throws -> DeleteItemOutput {
    return try await client.client.deleteItem(input: DeleteItemInput(key: key, tableName: table.tableName!))
}
