import SwiftUI
import AWSDynamoDB

class DynamoClientWrapper: Equatable {
    @Published var client: DynamoDBClient
    @Published var region: AWSRegionItem

    init(client: DynamoDBClient, region: AWSRegionItem) {
        self.client = client
        self.region = region
    }

    static func == (lhs: DynamoClientWrapper, rhs: DynamoClientWrapper) -> Bool {
        return lhs.client === rhs.client
    }
}
