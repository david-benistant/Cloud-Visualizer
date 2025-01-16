import SwiftUI
import AWSS3



fileprivate let tableConfig: [TableConfigItem] = [
    TableConfigItem(label: "Name", type: .string),
    TableConfigItem(label: "Region", type: .string, maxWidth: 100),
    TableConfigItem(label: "Creation Date", type: .date, alignment: .trailing),
    ]

struct S3Table: View {
    @EnvironmentObject var navModel: NavModel
    let s3Client: S3ClientWrapper?
    @StateObject private var tableItems: TableItemsModel = TableItemsModel(tableConfig: tableConfig)

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
            ),
        ]
    }
    
    private func applyDelete() async ->  Void {
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
    
    private func applyClearContents() async -> Void {
        do {
            if let client = s3Client {
                for bucket in tableItems.items {
                    if bucket.isSelected {
                        if let originBucket = bucket.additional as? S3BucketWrapper {
                            let objects = try await listAllObjects(using: client, bucket: originBucket)
                            if let objects = objects.contents {
                                try await deleteObjects(using: client, bucket: originBucket, keys: objects.map{ object in return object.key!})
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
    
    private func searchFunction(item: TableItem, search: String) -> Bool {
        let bucket = item.additional as? S3BucketWrapper
        if bucket != nil, let name = bucket?.bucket.name {
            return name.contains(search)
        }
        return false
    }
    
    private func actionFunction(_ item: TableItem, s3Client: S3ClientWrapper) -> TableItem {
        if let bucket = item.additional as? S3BucketWrapper {
            item.action = { line in
                navModel.navigate(AnyView(S3Content(s3Client: s3Client, bucket: bucket, path: "")), label: bucket.bucket.name!)
            }
        }
        return item;
    }

    var body: some View {
        Table(tableItems: tableItems, sideBarItems: sideBarItems, searchBarFunction: searchFunction)
        .onAppear() {
            if let client = s3Client {
                Task {
                    if let bucketList = await listBuckets(using: client) {
                        tableItems.items = (await wrapBucketList(bucketList, client: client)).map { item in
                            return actionFunction(item, s3Client: client);
                        }
                    }
                }
            }
        }
        .onChange(of: s3Client) {
            if let client = s3Client {
                Task {
                    if let bucketList = await listBuckets(using: client) {
                        tableItems.items = (await wrapBucketList(bucketList, client: client)).map { item in
                            return actionFunction(item, s3Client: client);
                        }
                    }
                }
            }
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
                    if let client = s3Client {
                        Task {
                            if let bucketList = await listBuckets(using: client) {
                                tableItems.items = (await wrapBucketList(bucketList, client: client)).map { item in
                                    return actionFunction(item, s3Client: client);
                                }
                            }
                        }
                    }
                }) {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
            }
        }
    }
}
