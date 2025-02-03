import SwiftUI
import AWSS3

private let tableConfig: [TableConfig] = [
    TableConfig(label: "Name"),
    TableConfig(label: "Region", maxWidth: 100),
    TableConfig(label: "Creation Date", alignment: .trailing)
    ]

struct S3Table: View {
    @EnvironmentObject var navModel: NavModel
    @Binding var s3Client: S3ClientWrapper?
    @StateObject private var tableItems: TableModel = TableModel(tableConfig: tableConfig)

    @State private var isCreateModalOpen: Bool = false
    @State private var isDeleteModalOpen: Bool = false
    @State private var isClearModalOpen: Bool = false

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
                disabled: isOneSelected()
            )
        ]
    }

    private func actionFunction(_ item: TableLine, s3Client: S3ClientWrapper) -> TableLine {
        if let bucket = item.additional as? S3BucketWrapper {
            item.action = { _ in
                navModel.navigate(
                    AnyView(
                        S3Content(s3Client: s3Client, bucket: bucket, path: "")
                    ),
                    label: bucket.bucket.name!
                )
            }
        }
        return item
    }

    private func applyDelete() async {
        do {
            await applyClearContents()
            if let client = s3Client {
                var remainingBuckets = tableItems.items
                for (index, bucket) in tableItems.items.enumerated().reversed() {
                    if bucket.isSelected {
                        if let originBucket = bucket.additional as? S3BucketWrapper, let name = originBucket.bucket.name {
                            try await deleteBucket(using: client, name: name)
                            remainingBuckets.remove(at: index)
                        }
                    }
                }
                tableItems.items = remainingBuckets
            }
        } catch let error as S3Error {
            print(error.message)
        } catch {
            print("An unknown error occurred: \(error)")
        }
    }

    private func applyClearContents() async {
        do {
            if let client = s3Client {
                for bucket in tableItems.items {
                    if bucket.isSelected {
                        if let originBucket = bucket.additional as? S3BucketWrapper {
                            let objects = try await listAllObjects(using: client, bucket: originBucket)
                            if let objects = objects.contents {
                                try await deleteObjects(using: client, bucket: originBucket, keys: objects.map { object in return object.key!})
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

    private func isOneSelected() -> Bool {
        return !tableItems.items.contains { $0.isSelected }
    }

    private func searchFunction(item: TableLine, search: String) -> Bool {
        let bucket = item.additional as? S3BucketWrapper
        if bucket != nil, let name = bucket?.bucket.name {
            return name.contains(search)
        }
        return false
    }

    var body: some View {
        Table(tableModel: tableItems, sideBarItems: sideBarItems, searchBarFunction: searchFunction)
            .onAppear {
                tableItems.loadContentFunction = { _ in
                    guard let client = s3Client else { return }
                    Task {
                        do {
                            let bucketList = try await listBuckets(using: client)
                            tableItems.items = (try await wrapBucketList(bucketList, client: client)).map { item in
                                return actionFunction(item, s3Client: client)
                            }
                            
                        } catch {
                            print(error)
                        }
                        
                    }
                }
            }
            .onChange(of: s3Client) {
                tableItems.items = []
                tableItems.reInit()
            }
            .sheet(isPresented: $isCreateModalOpen) {
                if let client = s3Client {
                    CreateS3Bucket(isOpen: $isCreateModalOpen, s3Client: client, tableItems: $tableItems.items)
                }
            }
            .sheet(isPresented: $isDeleteModalOpen) {
                ConfirmModal(isOpen: $isDeleteModalOpen, onConfirm: applyDelete)
            }
            .sheet(isPresented: $isClearModalOpen) {
                ConfirmModal(isOpen: $isClearModalOpen, onConfirm: applyClearContents)
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
