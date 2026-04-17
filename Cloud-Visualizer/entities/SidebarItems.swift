import SwiftUI

let allSidebarItems = [
    SidebarItem(id: UUID(uuidString: "5C314FF2-180E-4106-9BAC-25D348F5E356")!, title: "S3", destination: AnyView(S3View()), icon: "S3"),
    SidebarItem(id: UUID(uuidString: "FCAB69C9-DCF8-4263-869D-AC5E9751F46E")!, title: "DynamoDB", destination: AnyView(DynamoView()), icon: "DynamoDB"),
    SidebarItem(id: UUID(uuidString: "AA208A98-0F34-408A-A653-CDA888D8D1F9")!, title: "CloudWatch", destination: AnyView(CloudWatchView()), icon: "CloudWatch")
]
