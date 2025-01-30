import AWSDynamoDB
import SwiftUI

func dynamoValueToTableValue(value: DynamoDBClientTypes.AttributeValue) -> (Any?, FieldTypes) {
    switch value {
    case .s(let stringValue):
        return (stringValue, .string)
    case .n(let numberValue):
        return (Int(numberValue), .number)
    case .bool(let boolValue):
        return (boolValue, .boolean)
    case .b(let binaryValue):
        return (binaryValue, .binary)
    case .null:
        return (0, .null)
    case .bs(let binarySetValue):
        return ( binarySetValue.map { return TableItem(type: .binary, value: $0) }, .binary_set)
    case .ns(let numberSetValue):
        return (numberSetValue.map { return TableItem(type: .number, value: Int($0) )}, .number_set)
    case .ss(let stringSetValue):
        return (stringSetValue.map { return TableItem(type: .string, value: $0) }, .string_set)
    case .l(let listValue):
        return (listValue.map { value in
            let item = dynamoValueToTableValue(value: value)
            return TableItem(type: item.1, value: item.0)
        }, .list)
    case .m(let mapValue):

        return (mapValue.map { key, value in
            let item = dynamoValueToTableValue(value: value)
            return (key, TableItem(type: item.1, value: item.0))
        }, .map)
    default:
        return (nil, .string)
    }
}

func dynamoTableValueToValue(value: TableItem) -> DynamoDBClientTypes.AttributeValue {
    switch value.type {
    case .string:
        return .s(value.value as! String)
    case .number:
        return .n(String(describing: value.value as! Int))
    case .boolean:
        return .bool(value.value as! Bool)
    case .binary:
        return .b(value.value as! Data)
    case .null:
        return .null(true)
    case .binary_set:
        let item = value.value as!  [TableItem]
        return .bs(item.map { return $0.value as! Data })
    case .string_set:
        let item = value.value as!  [TableItem]
        return .ss(item.map { return $0.value as! String })
    case .number_set:
        let item = value.value as!  [TableItem]
        return .ns(item.map { return String($0.value as! Int) })
    case .list:
        let item = value.value as!  [TableItem]
        return .l(item.map { dynamoTableValueToValue(value: $0) })
    case .map:
        let item = value.value as! [(key: String, value: TableItem)]
        return .m(Dictionary(uniqueKeysWithValues: item.map { key, v in return (key, dynamoTableValueToValue(value: v)) }))
    default:
        return .null(true)
    }
}
