import SwiftUI
import Foundation
import Cocoa
import AppKit

class SidebarItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let destination: AnyView
    let icon: String

    static func ==(lhs: SidebarItem, rhs: SidebarItem) -> Bool {
        return lhs.id == rhs.id
    }

    init(id: UUID, title: String, destination: AnyView, icon: String) {
        self.id = id
        self.title = title
        self.destination = destination
        self.icon = icon
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(icon)
    }

//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        
//        self.title = try container.decode(String.self, forKey: .title)
//        self.icon = try container.decode(String.self, forKey: .icon)
//        self.id = try container.decode(UUID.self, forKey: .id)
//        self.destination = try container.decode(String.self, forKey: .destination)
//       
//    }
//    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//       
//        try container.encode(id, forKey: .id)
//        try container.encode(title, forKey: .title)
//        try container.encode(icon, forKey: .icon)
//        try container.encode(destination, forKey: .destination)
//        
//
//    }
//    
//    enum CodingKeys: String, CodingKey {
//        case id
//        case title
//        case icon
//        case destination
//    }
}

class SidebarViewModel: ObservableObject {
    var sidebarItems: [SidebarItem] = []
    @Published var displayedItems: [SidebarItem] = []

    init() {
        loadSidebarItems()
    }

    func search(query: String) {
        if query.isEmpty {
            displayedItems = sidebarItems
        } else {
            displayedItems = sidebarItems.filter {item in return item.title.lowercased().contains(query.lowercased())}
        }
    }

    private func loadSidebarItems() {
        if let savedItems = UserDefaults.standard.data(forKey: "sidebarItems"),
           let decodedItems = try? JSONDecoder().decode([UUID].self, from: savedItems) {
            let orderSet = Set(decodedItems)
            let matching: [SidebarItem] = allSidebarItems.filter { orderSet.contains($0.id) }
            let nonMatching: [SidebarItem] = allSidebarItems.filter { !orderSet.contains($0.id) }

            let sortedMatching: [SidebarItem] = matching.sorted {
                guard let index1 = decodedItems.firstIndex(of: $0.id), let index2 = decodedItems.firstIndex(of: $1.id) else {
                    return false
                }
                return index1 < index2
            }
            self.sidebarItems = nonMatching + sortedMatching
            self.displayedItems = nonMatching + sortedMatching
        } else {
            self.sidebarItems = allSidebarItems
            self.displayedItems = allSidebarItems
        }
    }

    func selectItem(selectedItem: SidebarItem) {
        if let index = sidebarItems.firstIndex(where: { $0 == selectedItem }) {
            sidebarItems.remove(at: index)
            sidebarItems.insert(selectedItem, at: 0)
            if let encoded = try? JSONEncoder().encode(sidebarItems.map {item in return item.id}) {
                UserDefaults.standard.set(encoded, forKey: "sidebarItems")
            }
            displayedItems = sidebarItems
        }
    }
}
