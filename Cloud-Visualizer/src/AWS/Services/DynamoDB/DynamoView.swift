import SwiftUI

private struct Dynamo: View {
    @State private var dynamoClient: DynamoClientWrapper?

    var body: some View {
        
        DynamoTable(dynamoClient: $dynamoClient)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    AWSHeader(callback: doAuth)
                }
            }
            .onDisappear {
                Task {
                    dynamoClient = nil
                }
            }
    }

    func doAuth(cred: CredentialItem, region: AWSRegionItem) {
        Task {
            if let client = await authDynamo(credentials: cred, region: region.region) {
                dynamoClient = client
            }
        }
    }
}

struct DynamoView: View {
    var body: some View {
        Nav(AnyView(Dynamo()), rootLabel: "DynamoDB")
    }
}
