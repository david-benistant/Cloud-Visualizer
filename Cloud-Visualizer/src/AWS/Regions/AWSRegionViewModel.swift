import SwiftUI

class AWSRegionViewModel: ObservableObject {
    func loadRegion() -> AWSRegionItem {
        if let savedItem = UserDefaults.standard.data(forKey: "AWSRegion"),
           let decodedItem = try? JSONDecoder().decode(AWSRegionItem.self, from: savedItem) {
            return decodedItem
        }
        return AWSRegionItem(region: "us-east-1")
    }

    func setCurrent(region: AWSRegionItem) {
        if let encoded = try? JSONEncoder().encode(region) {
            UserDefaults.standard.set(encoded, forKey: "AWSRegion")
        }
    }
}
