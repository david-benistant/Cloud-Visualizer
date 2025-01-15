import SwiftUI

class AWSAuthItem: ObservableObject, Equatable {
    @Published var credential: CredentialItem
    @Published var region: AWSRegionItem

    init() {
        self.credential = CredentialItem(type: "None", name: "")
        self.region = AWSRegionItem(region: "None")
    }

    static func == (lhs: AWSAuthItem, rhs: AWSAuthItem) -> Bool {
        return lhs.credential == rhs.credential && lhs.region == rhs.region
    }
}
