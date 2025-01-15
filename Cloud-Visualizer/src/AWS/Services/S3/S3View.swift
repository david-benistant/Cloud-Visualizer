import SwiftUI

import AWSS3

fileprivate struct S3: View {
    
    @State private var s3Client: S3ClientWrapper? = nil
    
    @State private var isOpen: Bool = true
    @State private var tableItems: [TableItem] = []
    
    var body: some View {
        
        S3Table(s3Client: s3Client)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    AWSHeader(callback: doAuth)
                }
            }
            .onDisappear {
                Task {
                    s3Client = nil
                }
            }
        Section {}
        
    }

    func doAuth(cred: CredentialItem, region: AWSRegionItem) {
        Task {
            if let client = await AuthS3(credentials: cred, region: region.region) {
                s3Client = client
            }
        }
    }
}

struct S3View: View {
    var body: some View {
        Nav(AnyView(S3()), rootLabel: "S3")
    }
}

#Preview {
    S3View()
}
