import SwiftUI

import AWSS3

private struct S3: View {

    @State private var s3Client: S3ClientWrapper?

    var body: some View {

        S3Table(s3Client: $s3Client)
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

    }

    func doAuth(cred: CredentialItem, region: AWSRegionItem) {
        Task {
            if let client = await authS3(credentials: cred, region: region.region) {
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
