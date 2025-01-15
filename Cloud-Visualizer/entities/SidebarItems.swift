import SwiftUI

let allSidebarItems = [
    SidebarItem(id: UUID(uuidString: "5C314FF2-180E-4106-9BAC-25D348F5E356")!, title: "S3", destination: AnyView(S3View()) , icon: "S3"),
    SidebarItem(id: UUID(uuidString: "FCAB69C9-DCF8-4263-869D-AC5E9751F46E")!, title: "DynamoDB", destination: AnyView(DynamoView()), icon: "DynamoDB")
]
