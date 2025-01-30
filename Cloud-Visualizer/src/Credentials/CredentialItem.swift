import SwiftUI
import Foundation
import Cocoa
import AppKit

class CredentialItem: Identifiable, Hashable, Codable, ObservableObject {
    private let _id: UUID
    @Published var type: String
    @Published var name: String
    @Published var AWSKeyId: String
    @Published var AWSSecretAccessKey: String
    @Published var endpoint: String
    @Published var current: Bool = false

    var id: UUID {
        return _id
    }

    static func ==(lhs: CredentialItem, rhs: CredentialItem) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(type)
        hasher.combine(name)
        hasher.combine(AWSKeyId)
    }

    init(type: String, name: String, AWSKeyId: String = "", AWSSecretAccessKey: String = "", endpoint: String = "") {
        self._id = UUID()
        self.type = type
        self.name = name
        self.AWSKeyId = AWSKeyId
        self.AWSSecretAccessKey = AWSSecretAccessKey
        self.endpoint = endpoint
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self._id = try container.decode(UUID.self, forKey: .id)
        self.type = try container.decode(String.self, forKey: .type)
        self.name = try container.decode(String.self, forKey: .name)
        self.AWSKeyId = try container.decode(String.self, forKey: .AWSKeyId)
        self.AWSSecretAccessKey = try container.decode(String.self, forKey: .AWSSecretAccessKey)
        self.endpoint = try container.decode(String.self, forKey: .endpoint)
        self.current = try container.decode(Bool.self, forKey: .current)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(_id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(AWSKeyId, forKey: .AWSKeyId)
        try container.encodeIfPresent(AWSSecretAccessKey, forKey: .AWSSecretAccessKey)
        try container.encodeIfPresent(endpoint, forKey: .endpoint)
        try container.encode(current, forKey: .current)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case name
        case AWSKeyId
        case AWSSecretAccessKey
        case endpoint
        case current
    }
}
