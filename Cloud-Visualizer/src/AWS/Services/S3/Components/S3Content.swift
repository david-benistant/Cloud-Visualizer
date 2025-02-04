import SwiftUI
import AWSS3
import UniformTypeIdentifiers

private let tableConfig: [TableConfig] = [
    TableConfig(label: "Key"),
    TableConfig(label: "Size", maxWidth: 100),
    TableConfig(label: "Storage class"),
    TableConfig(label: "Last modified", alignment: .trailing)
]

struct S3Content: View {

    let s3Client: S3ClientWrapper
    let bucket: S3BucketWrapper
    let path: String

    @EnvironmentObject var navModel: NavModel
    @StateObject private var tableItems: TableModel = TableModel(tableConfig: tableConfig)
    @State private var isCreateModalOpen: Bool = false
    @State private var isDeleteModalOpen: Bool = false
    @State private var isClearModalOpen: Bool = false

    @State private var isSelectViewerOpen: Bool = false

    @State private var droppedFiles: [URL] = []
    @State private var isHighlighted: Bool = false

    @State private var viewerData: (Data, String)?

    private var sideBarItems: [TableSideBarItem] {
        [
            TableSideBarItem(
                name: "Add",
                icon: "plus",
                action: { self.isCreateModalOpen = true }
            ),
            TableSideBarItem(
                name: "Delete",
                icon: "trash",
                action: { self.isDeleteModalOpen = true },
                disabled: isOneSelected()
            ),
            TableSideBarItem(
                name: "Empty",
                icon: "clear",
                action: { self.isClearModalOpen = true },
                disabled: isOneFolderSelected()
            ),
            TableSideBarItem(
                name: "Download",
                icon: "square.and.arrow.down",
                action: { Task {
                    await applyDownload()
                } },
                disabled: isOneObjectSelected()
            )
        ]
    }

    private func isOneSelected() -> Bool {
        return !tableItems.items.contains { $0.isSelected }
    }

    private func isOneFolderSelected() -> Bool {
        return !tableItems.items.contains { $0.isSelected && $0.additional as AnyObject is S3ClientTypes.CommonPrefix }
    }

    private func isOneObjectSelected() -> Bool {
        return !tableItems.items.contains { $0.isSelected && $0.additional as AnyObject is S3ClientTypes.Object }
    }

    // --Sidebar buttons actions--//

    private func applyDelete() async {
        do {
            await applyClearContents()
            var remainingObjects = tableItems.items
            for (index, item) in tableItems.items.enumerated().reversed() {
                if item.isSelected {
                    if let folder = item.additional as? S3ClientTypes.CommonPrefix {
                        if let prefix = folder.prefix {
                            try await deleteObjects(using: s3Client, bucket: bucket, keys: [prefix])
                            remainingObjects.remove(at: index)
                        }
                    } else if let object = item.additional as? S3ClientTypes.Object {
                        if let key = object.key {
                            try await deleteObjects(using: s3Client, bucket: bucket, keys: [key])
                            remainingObjects.remove(at: index)
                        }
                    }
                }
            }
            tableItems.items = remainingObjects
        } catch let error as S3Error {
            print(error.message)
        } catch {
            print("An unknown error occurred: \(error)")
        }
    }

    private func applyDownload() async {
        do {
            for item in tableItems.items {
                if item.isSelected {
                    if let object = item.additional as? S3ClientTypes.Object {
                        let key = object.key!
                        let objectContent = try await getObject(using: s3Client, bucket: bucket, key: key)
                        try await downloadObject(object: objectContent, filePath: key)
                    }
                }
            }
        } catch let error as S3Error {
            print(error.message)
        } catch {
            print("An unknown error occurred: \(error)")
        }
    }

    private func applyClearContents() async {
        do {
            for item in tableItems.items {
                if item.isSelected {
                    if let folder = item.additional as? S3ClientTypes.CommonPrefix {
                        if let prefix = folder.prefix {
                            let objects = try await listAllObjects(using: s3Client, bucket: bucket, path: prefix)
                            if let content = objects.contents {
                                try await deleteObjects(
                                    using: s3Client,
                                    bucket: bucket,
                                    keys: content.compactMap { obj in
                                        if let key = obj.key, key != prefix {
                                            return key
                                        } else {
                                            return nil
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
            }
        } catch let error as S3Error {
            print(error.message)
        } catch {
            print("An unknown error occurred: \(error)")
        }
    }

    private func searchFunction(item: TableLine, search: String) -> Bool {
        if let folder = item.additional as? S3ClientTypes.CommonPrefix {
            if let prefix = folder.prefix {
                return prefix.contains(search)
            }
        } else if let obj = item.additional as? S3ClientTypes.Object {
            if let key = obj.key {
                return key.contains(search)
            }
        }
        return false
    }

    // -- items actions --//

    private func selectViewerCallback(_ viewer: Viewer) {
        if let data = viewerData {

            switch viewer {
            case .image:
                let image = ImageViewer(imageData: data.0)
                image.open(title: data.1)
            case .pdf:
                let pdf = PDFViewer(pdfData: data.0)
                pdf.open(title: data.1)
            case .text:
                let textView = TextViewer(textData: data.0)
                textView.open(title: data.1)
            case .html:
                let htmlView = HtmlViewer(htmlData: data.0)
                htmlView.open(title: data.1)
            }
        }
    }

    private func actionFunction(_ item: TableLine) -> TableLine {
        if let folder = item.additional as? S3ClientTypes.CommonPrefix {
            if let prefix = folder.prefix {
                let label = String(prefix.dropFirst(path.count))
                item.action = { _ in
                    navModel.navigate(AnyView(S3Content(s3Client: s3Client, bucket: bucket, path: prefix)), label: label)
                }
            }
        }
        if let object = item.additional as? S3ClientTypes.Object {
            if let key = object.key {
                item.action = { _ in
                    Task {
                        do {
                            let object = try await getObject(using: s3Client, bucket: bucket, key: key)
                            let label = String(key.dropFirst(path.count))
                            if let body = object.body {

                                if let data = try await body.readData() {
                                    let type = getDataMimeType(from: data)
                                    switch type {
                                    case .pdf:
                                        let pdf = PDFViewer(pdfData: data)
                                        pdf.open(title: label)
                                    case .png:
                                        let image = ImageViewer(imageData: data)
                                        image.open(title: label)
                                    case .jpg:
                                        let image = ImageViewer(imageData: data)
                                        image.open(title: label)
                                    case .gif:
                                        let image = ImageViewer(imageData: data)
                                        image.open(title: label)
                                    case .svg:
                                        let image = ImageViewer(imageData: data)
                                        image.open(title: label)
                                    case .webp:
                                        let image = ImageViewer(imageData: data)
                                        image.open(title: label)
                                    case .html:
                                        let htmlView = HtmlViewer(htmlData: data)
                                        htmlView.open(title: label)
                                    case .txt:
                                        let textView = TextViewer(textData: data)
                                        textView.open(title: label)

                                    default:
                                        viewerData = (data, label)
                                        isSelectViewerOpen = true
                                        print("unable to open this file:", type)
                                    }
                                }

                            }
                        } catch {
                            print("error while displaying content :", error)
                        }

                    }

                }
            }
        }
        return item
    }

    // -- files drop functions --//

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, _) in
                    DispatchQueue.main.async {
                        if let data = item as? Data,
                           let url = URL(dataRepresentation: data, relativeTo: nil) {
                            let urls = explore(url: url)
                            uploadFiles(urls: urls)
                        }
                    }
                }
            }
        }
        return true
    }

    private func explore(url: URL) -> [URL] {
        var out: [URL] = []
        out.append(url)
        if url.hasDirectoryPath {
            let fileManager = FileManager.default
            if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {
                for case let fileURL as URL in enumerator {
                    out.append(fileURL)
                }
            }
        }
        return out
    }

    private func uploadFiles(urls: [URL]) {
        Task {
            if let originUrl = urls.first {
                if originUrl.hasDirectoryPath {
                    await createDroppedFolder(key: originUrl.lastPathComponent, relativePath: "")
                } else {
                    await createDroppedFile(key: originUrl.lastPathComponent, relativePath: "", fileUrl: originUrl)
                }

                var remainsUrls = urls
                remainsUrls.removeFirst()

                for url in remainsUrls {
                    let relativePath = String(url.path.replacingOccurrences(of: originUrl.path + "/", with: "").dropLast(url.lastPathComponent.count))
                    if url.hasDirectoryPath {
                        await createDroppedFolder(key: url.lastPathComponent, relativePath: originUrl.lastPathComponent + "/" + relativePath)
                    } else {
                        await createDroppedFile(key: url.lastPathComponent, relativePath: originUrl.lastPathComponent + "/" + relativePath, fileUrl: url)
                    }
                }
            }
        }
    }

    private func createDroppedFolder(key: String, relativePath: String) async {
        do {
            var sanitized = key
            if sanitized.hasSuffix("/") {
                sanitized.removeLast()
            }

            if sanitized.contains("/") {
                throw S3Error(message: "folders cannot contain \"/\"")
            }

            sanitized = sanitized + "/"
            try await createFolder(using: s3Client, bucket: bucket, key: path + relativePath + sanitized)

            if relativePath.isEmpty {
                tableItems.items.append(TableLine(
                    items: [
                        TableItem(type: .string, value: sanitized)
                    ],
                    action: { _ in navModel.navigate(AnyView(S3Content(s3Client: s3Client, bucket: bucket, path: path + relativePath + sanitized)), label: sanitized) },
                    additional: S3ClientTypes.CommonPrefix(prefix: sanitized)
                ))
            }
        } catch let error as S3Error {
            print(error.message)
        } catch _ {
            print("an error occured while creating folder")
        }
    }

    private func createDroppedFile(key: String, relativePath: String, fileUrl: URL) async {
        do {
            try await uploadFile(using: s3Client, bucket: bucket, path: path + relativePath, fileUrl: fileUrl)

            if relativePath.isEmpty {
                let item = TableLine(
                    items: [TableItem(type: .string, value: key)],
                    additional: S3ClientTypes.Object(key: path + key))
                tableItems.items.append(actionFunction(item))
            }
        } catch let error as S3Error {
            print(error.message)
        } catch _ {
            print("an error occured while creating file")
        }
    }

    // -- body --//

    var body: some View {
        Table(tableModel: tableItems, sideBarItems: sideBarItems, searchBarFunction: searchFunction)
            .border(isHighlighted ? .white : .clear)
            .onAppear {
                tableItems.loadContentFunction = { _ in
                    Task {
                        do {
                            let objectList = try await listObjects(using: s3Client, bucket: bucket, path: path)
                            tableItems.items =  wrapObjectsList(objectList, path: path).map { item in
                                return actionFunction(item)
                            }
                        } catch {
                            print("error while fetching objects")
                        }
                    }
                }
            }
            .onChange(of: path) {
                tableItems.loadContentFunction = { _ in
                    Task {
                        do {
                            let objectList = try await listObjects(using: s3Client, bucket: bucket, path: path)
                            tableItems.items =  wrapObjectsList(objectList, path: path).map { item in
                                return actionFunction(item)
                            }
                        } catch {
                            print("error while fetching objects")
                        }
                    }
                }
                tableItems.reInit()
            }
            .onDrop(of: [UTType.fileURL], isTargeted: $isHighlighted) { providers in
                handleDrop(providers: providers)
            }
            .sheet(isPresented: $isCreateModalOpen) {
                CreateS3Content(isOpen: $isCreateModalOpen, s3Client: s3Client, bucket: bucket, path: path, uploadFilesFunction: uploadFiles, tableItems: $tableItems.items)
            }
            .sheet(isPresented: $isDeleteModalOpen) {
                ConfirmModal(isOpen: $isDeleteModalOpen, onConfirm: applyDelete)
            }
            .sheet(isPresented: $isClearModalOpen) {
                ConfirmModal(isOpen: $isClearModalOpen, onConfirm: applyClearContents)
            }
            .sheet(isPresented: $isSelectViewerOpen) {
                SelectViewer(isOpen: $isSelectViewerOpen, callback: selectViewerCallback)
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        tableItems.reload()
                    }) {
                        Image(systemName: "arrow.trianglehead.clockwise")
                    }
                }
            }
    }
}
