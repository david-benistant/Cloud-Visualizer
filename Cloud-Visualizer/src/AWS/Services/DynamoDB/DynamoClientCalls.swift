import AWSDynamoDB
import Foundation

import AWSClientRuntime
import AWSSDKIdentity
import SwiftUI
import ClientRuntime
import Smithy
import SmithyHTTPAPI

func authDynamo(credentials: CredentialItem,
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
        throw DynamoError(message: "An error occured while listing tables", description: error.localizedDescription, client: client)
    }
}

func wrapDynamoTableList(_ tableList: ListTablesOutput,
                         client: DynamoClientWrapper) async throws -> [TableLine] {
    var output: [TableLine] = []
    do {
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
    } catch {
        throw DynamoError(message: "An error occured while describing the table", description: error.localizedDescription, client: client)
    }
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
        return try await client.client.scan(input: input)
    } catch {
        throw DynamoError(message: "An error occured while scanning the table", description: error.localizedDescription, client: client)
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
        throw DynamoError(message: "An error occured while updating item", description: error.localizedDescription, client: client)
    }
}

func createDynamoItem(client: DynamoClientWrapper,
                      table: DynamoDBClientTypes.TableDescription,
                      key: [String: DynamoDBClientTypes.AttributeValue],
                      values: [String: DynamoDBClientTypes.AttributeValue]) async throws -> PutItemOutput {
    do {
        let item = key.merging(values) { (_, new) in new }
        
        var expressionAttributeNames: [String: String] = ["#PK": Array(key.keys)[0]]

        if key.count > 1 {
            expressionAttributeNames["#SK"] = Array(key.keys)[1]
        }
        
        return try await client.client.putItem(input: PutItemInput(
            conditionExpression: "attribute_not_exists(#PK)" +  (key.count > 1 ? "AND attribute_not_exists(#SK)" : ""),
            expressionAttributeNames: expressionAttributeNames,
            item: item,
            tableName: table.tableName!
        ))
    } catch let error as AWSDynamoDB.ConditionalCheckFailedException {
        if error.message == "The conditional request failed" {
            throw DynamoError(message: "Item already exists")
        }
        throw DynamoError(message: "An error occured while creating the item: " + (error.message ?? "Unknown error"), description: error.localizedDescription, client: client)
    } catch {
        throw DynamoError(message: "An error occured while creating the item", description: error.localizedDescription, client: client)
    }
}


func deleteDynamoItem(client: DynamoClientWrapper,
                      table: DynamoDBClientTypes.TableDescription,
                      key: [String: DynamoDBClientTypes.AttributeValue]) async throws -> DeleteItemOutput {
    do {
        return try await client.client.deleteItem(input: DeleteItemInput(key: key, tableName: table.tableName!))
    } catch {
        throw DynamoError(message: "An error occured while deleting item", description: error.localizedDescription, client: client)
    }
   
}

func createDynamoTable(client: DynamoClientWrapper,
                       tableName: String,
                       partitionKey: (String, DynamoDBClientTypes.ScalarAttributeType),
                       sortKey: (String, DynamoDBClientTypes.ScalarAttributeType)?) async throws -> CreateTableOutput {
    
    
    var attributeDefinitions: [DynamoDBClientTypes.AttributeDefinition] = [.init(attributeName: partitionKey.0, attributeType: partitionKey.1)]
    var keySchema: [DynamoDBClientTypes.KeySchemaElement] = [.init(attributeName: partitionKey.0, keyType: .hash)]
    if sortKey != nil {
        attributeDefinitions.append(.init(attributeName: sortKey!.0, attributeType: sortKey!.1))
        keySchema.append(.init(attributeName: sortKey!.0, keyType: .range))
    }
    
    let input = CreateTableInput(
        attributeDefinitions: attributeDefinitions,
        billingMode: .payPerRequest,
        keySchema: keySchema,
        tableName: tableName
    )
    
    do {
        return try await client.client.createTable(input: input)
    } catch let error as AWSDynamoDB.ResourceInUseException {
        throw DynamoError(message: "Table already exists: " + tableName, description: error.localizedDescription, client: client)
    } catch {
        throw DynamoError(message: "An error occured while creating the table", description: error.localizedDescription, client: client)
    }
    
}

func deleteDynamoTable(client: DynamoClientWrapper,
                       tableName: String) async throws -> DeleteTableOutput {
    do {
        return try await client.client.deleteTable(input: DeleteTableInput(tableName: tableName))
    } catch {
        throw DynamoError(message: "An error occured while deleting the table", description: error.localizedDescription, client: client)
    }
}
