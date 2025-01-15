import SwiftUI
import AWSS3

class S3ClientWrapper: Equatable {
    @Published var client: S3Client
    @Published var region: AWSRegionItem
    
    init(client: S3Client, region: AWSRegionItem) {
        self.client = client
        self.region = region
    }

    static func == (lhs: S3ClientWrapper, rhs: S3ClientWrapper) -> Bool {
        return lhs.client === rhs.client
    }
}
