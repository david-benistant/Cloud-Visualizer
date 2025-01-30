import SwiftUI
import AWSS3
import UniformTypeIdentifiers
import AppKit

struct CreateS3Content: View {
    @EnvironmentObject var navModel: NavModel
    @Binding var isOpen: Bool
    let s3Client: S3ClientWrapper
    let bucket: S3BucketWrapper
    let path: String

    let uploadFilesFunction: ([URL]) -> Void

    @State var folderName: String = ""
    @State var errorMessage: String?

    @State var selectedOption: String = "folder"
    @Binding var tableItems: [TableLine]

    @State private var files: [FilesModel] = []

    private func isDisabled() -> Bool {

        if selectedOption == "folder" {
            return folderName.isEmpty
        } else {
            return files.isEmpty
        }
    }

    var body: some View {
        VStack {
            ModalHeader(title: "Add object", errorMessage: $errorMessage)
                .padding(.bottom)

            Picker("", selection: $selectedOption) {
                Text("Folder").tag("folder")

                Text("File").tag("file")
            }
            .pickerStyle(.palette)

            Spacer()

            if selectedOption == "folder" {
                TextInput(label: "Folder Name", disabled: false, field: $folderName)
            }

            if selectedOption == "file" {
                VStack {
                    HStack {
                        FileExplorer(files: $files, canChooseFiles: true, canChooseDirectories: true, allowsMultipleSelection: true) {
                            Image(systemName: "plus")
                        }
                    }
                    .frame(width: 290, alignment: .trailing)

                    DropZone(files: $files)
                        .frame(width: 290, height: 150)
                }

            }

            Spacer()

            HStack {
                Button(action: {
                    isOpen = false
                }) {
                    Text("Cancel")
                }
                Button(action: {
                    confirm()
                }) {
                    Text("Confirm")
                }
                .disabled(isDisabled())
                .keyboardShortcut(.defaultAction)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(width: 300, height: 300)
        .padding()
    }

    private func applyCreateFolder() {
        Task {
            do {
                var sanitized = folderName
                if sanitized.hasSuffix("/") {
                    sanitized.removeLast()
                }

                if sanitized.contains("/") {
                    throw S3Error(message: "folders cannot contain \"/\"")
                }
                sanitized = sanitized + "/"
                try await createFolder(using: s3Client, bucket: bucket, key: path + sanitized)
                tableItems.append(TableLine(
                    items: [
                        TableItem(type: .string, value: sanitized)
                    ],
                    action: { _ in navModel.navigate(AnyView(S3Content(s3Client: s3Client, bucket: bucket, path: path + sanitized)), label: sanitized) },
                    additional: S3ClientTypes.CommonPrefix(prefix: sanitized)
                ))
                isOpen = false
            } catch let error as S3Error {
                errorMessage = error.message
            }
        }
    }

    private func confirm () {
        if selectedOption == "folder" {
            applyCreateFolder()
        } else {
            for f in files {
                uploadFilesFunction(f.getFiles())
                isOpen = false
            }
        }
    }
}
