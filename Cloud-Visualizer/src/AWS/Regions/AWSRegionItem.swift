import SwiftUI

class AWSRegionItem: Identifiable, Hashable, Codable, ObservableObject, Equatable {
    @Published var region: String

    static func ==(lhs: AWSRegionItem, rhs: AWSRegionItem) -> Bool {
        return lhs.region == rhs.region
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(region)
    }

    init(region: String) {
        self.region = region
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.region = try container.decode(String.self, forKey: .region)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(region, forKey: .region)

    }

    enum CodingKeys: String, CodingKey {
        case region
    }
}
