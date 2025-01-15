
import SwiftUI
import AWSS3

struct CreateS3Bucket: View {
    @EnvironmentObject var navModel: NavModel
    @Binding var isOpen: Bool
    let s3Client: S3ClientWrapper
    @State var name: String = ""
    @State var errorMessage: String?
    @Binding var tableItems: [TableItem]

    var body: some View {
        VStack {
            ModalHeader(title: "Add Bucket", errorMessage: $errorMessage)
            
            Spacer()
            TextInput(label: "Bucket Name", disabled: false ,field: $name)
            
            Spacer()
            HStack {
                Button(action: {
                    isOpen = false
                }) {
                    Text("Cancel")
                }
                Button(action: {
                    Task {
                        do {
                            try await createBucket(using: s3Client, name : name)
                            
                            isOpen = false
                            let region = s3Client.region.region
                            let bucket = S3BucketWrapper(bucket: S3ClientTypes.Bucket(name: name), region: s3Client.region)
                            tableItems.append(TableItem(
                                fields: [ TableFieldItem(value: name), TableFieldItem(value: region), TableFieldItem(value: Date())],
                                action: { _ in navModel.navigate(AnyView(S3Content(s3Client: s3Client, bucket: bucket, path: "")), label: name) },
                                additional: bucket
                            ))
                        } catch let error as S3Error {
                            errorMessage = error.message
                        }
                    }
                }) {
                    Text("Create")
                }
                .disabled(name.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(width: 300, height: 150)
        .padding()
    }
}
