import AWSS3

import Foundation

import AWSClientRuntime
import AWSSDKIdentity
import SwiftUI
import ClientRuntime
import Smithy
import SmithyHTTPAPI

func AuthS3(credentials: CredentialItem, region: String) async -> S3ClientWrapper? {
    do {
        let awsCredentials = AWSCredentialIdentity(
            accessKey: credentials.AWSKeyId,
            secret: credentials.AWSSecretAccessKey
        )
        let identityResolver = try StaticAWSCredentialIdentityResolver(awsCredentials)

        let s3Configuration = try await S3Client.S3ClientConfiguration(
            awsCredentialIdentityResolver: identityResolver,
            region: region,
            forcePathStyle: true
        )

        if !credentials.endpoint.isEmpty {
            s3Configuration.endpoint = credentials.endpoint
        }

        let client = S3Client(config: s3Configuration)

        return S3ClientWrapper(client: client, region: AWSRegionItem(region: region))
    } catch {
        print("Failed to configure S3 Client: \(error.localizedDescription)")
        return nil
    }
}

func wrapBucketList(_ bucketList: ListBucketsOutput, client: S3ClientWrapper) async -> [TableLine] {
    do {
        var output: [TableLine] = []
        if let buckets = bucketList.buckets {
            for bucket in buckets {

                let name = bucket.name ?? "Unknown name"
                let creationDate = bucket.creationDate ?? Date()
                let locationInput = GetBucketLocationInput(bucket: name)
                let locationOutput = try await client.client.getBucketLocation(input: locationInput)
                var location = locationOutput.locationConstraint?.rawValue ?? "us-east-1"
                if location.isEmpty {
                    location = "us-east-1"
                }
                let region = AWSRegionItem(region: location)

                output.append( TableLine(
                    items: [ TableItem(type: .string, value: name), TableItem(type: .string, value: location), TableItem(type: .date, value: creationDate)],
                    additional: S3BucketWrapper(bucket: bucket, region: region),
                    disabled: region != client.region)
                )
            }
        }
        return output
    } catch {
        print("Error fetching bucket region: \(error)")
    }
    return []
}

func listBuckets(using client: S3ClientWrapper) async -> ListBucketsOutput? {
    do {
        let listBucketsInput = ListBucketsInput()
        let listBucketsOutput = try await client.client.listBuckets(input: listBucketsInput)

        return listBucketsOutput
    } catch {
        print("Error fetching buckets: \(error)")
    }
    return nil
}

func createBucket(using client: S3ClientWrapper, name: String) async throws {
    var input = CreateBucketInput(
        bucket: name
    )

    input.createBucketConfiguration = S3ClientTypes.CreateBucketConfiguration(locationConstraint: S3ClientTypes.BucketLocationConstraint(rawValue: client.region.region))

    do {
        _ = try await client.client.createBucket(input: input)
    } catch let error as BucketAlreadyOwnedByYou {
        throw S3Error(message: "Bucket already owned by you", description: error.localizedDescription, client: client )
    } catch let error as BucketAlreadyExists {
        throw S3Error(message: "Bucket already exists", description: error.localizedDescription, client: client )
    } catch {
        print("ERROR: ", dump(error, name: "Creating a bucket"))
        throw S3Error(message: "An error occurred while creating the bucket", description: error.localizedDescription, client: client )
    }
}

func deleteBucket(using client: S3ClientWrapper, name: String) async throws {
    do {
        _ = try await client.client.deleteBucket(input: DeleteBucketInput(bucket: name))
    } catch {
        print("ERROR: ", dump(error, name: "Deleting a bucket"))
        throw S3Error(message: "An error occurred while deleting the bucket", description: error.localizedDescription, client: client)
    }
}

func wrapObjectsList(_ objectList: ListObjectsV2Output, path: String) -> [TableLine] {
    var output: [TableLine] = []

    if let folders = objectList.commonPrefixes {
        for folder in folders {
            var key = folder.prefix
            if key != nil {
                if key! == path {
                    continue
                }
                key = String(key!.dropFirst(path.count))
            } else {
                key = "Unnamed folder"
            }

            output.append(TableLine(
                items: [
                    TableItem(type: .string, value: key!),
                    TableItem(type: .size),
                    TableItem(type: .string),
                    TableItem(type: .date)
                ],
                additional: folder
            ))
        }
    }

    if let contents = objectList.contents {
        for obj in contents {
            var key = obj.key
            if key != nil {
                if key! == path {
                    continue
                }
                key = String(key!.dropFirst(path.count))
            } else {
                key = "Unnamed object"
            }
            let storageClass = obj.storageClass?.rawValue ?? "-"

            output.append(TableLine(
                items: [
                    TableItem(type: .string, value: key!),
                    TableItem(type: .size, value: obj.size),
                    TableItem(type: .string, value: storageClass.prefix(1).uppercased() + storageClass.dropFirst().lowercased()),
                    TableItem(type: .date, value: obj.lastModified)
                ],
                additional: obj
            ))
        }
    }
    return output
}

func listObjects(using client: S3ClientWrapper, bucket: S3BucketWrapper, path: String) async throws -> ListObjectsV2Output {
    do {
        let input = ListObjectsV2Input(
            bucket: bucket.bucket.name!,
            delimiter: "/",
            prefix: path
        )

        let listObjectOutput = try await client.client.listObjectsV2(input: input)
        return listObjectOutput
    } catch {
        print("Error fetching bucket content: \(error)")
        throw S3Error(message: "Error fetching bucket content", description: error.localizedDescription, client: client)
    }
}

func listAllObjects(using client: S3ClientWrapper, bucket: S3BucketWrapper, path: String = "") async throws -> ListObjectsV2Output {
    do {
        let input = ListObjectsV2Input(
            bucket: bucket.bucket.name!,
            prefix: path
        )

        let listObjectOutput = try await client.client.listObjectsV2(input: input)
        return listObjectOutput
    } catch {
        print("Error fetching bucket content: \(error)")
        throw S3Error(message: "Error fetching bucket content", description: error.localizedDescription, client: client)
    }
}

func deleteObjects(using client: S3ClientWrapper, bucket: S3BucketWrapper, keys: [String]) async throws {
    if keys.count == 0 {
        return
    }

    let input = DeleteObjectsInput(
        bucket: bucket.bucket.name!,
        delete: S3ClientTypes.Delete(
            objects: keys.map { S3ClientTypes.ObjectIdentifier(key: $0) },
            quiet: true
        )
    )

    do {
        _ = try await client.client.deleteObjects(input: input)
    } catch {
        print("ERROR: deleteObjects:", dump(error))
        throw error
    }
}

func createFolder(using client: S3ClientWrapper, bucket: S3BucketWrapper, key: String) async throws {
    let safeKey = key.replacingOccurrences(of: "/+$", with: "", options: String.CompareOptions.regularExpression) + "//"

    let input = PutObjectInput(body: nil, bucket: bucket.bucket.name!, key: safeKey)

    do {
        _ = try await client.client.putObject(input: input)
    } catch let error {
        throw S3Error(message: "Error while creating folder", description: error.localizedDescription, client: client)
    }
}

func uploadFile(using client: S3ClientWrapper, bucket: S3BucketWrapper, path: String, fileUrl: URL) async throws {

    do {
        let fileData = try Data(contentsOf: fileUrl)
        let dataStream = ByteStream.data(fileData)

        let input = PutObjectInput(
            body: dataStream,
            bucket: bucket.bucket.name!,
            key: path + fileUrl.lastPathComponent
        )

        _ = try await client.client.putObject(input: input)

    } catch {
        print("ERROR: ", dump(error, name: "Putting an object."))
        throw error
    }
}

func getObject(using client: S3ClientWrapper, bucket: S3BucketWrapper, key: String) async throws -> GetObjectOutput {
    do {
        let input = GetObjectInput(
            bucket: bucket.bucket.name!,
            key: key
            )

        let output = try await client.client.getObject(input: input)

        return output
    } catch {
        print("ERROR: ", dump(error, name: "Get an object."))
        throw error
    }
}

func createFileInDownload(fromPath path: String) throws -> URL {
    let baseURL = try FileManager.default.url(
        for: .downloadsDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    )

    let fullPath = baseURL.appendingPathComponent(path)

    let directoryPath = fullPath.deletingLastPathComponent()

    if directoryPath != baseURL {
        try FileManager.default.createDirectory(at: directoryPath, withIntermediateDirectories: true, attributes: nil)
    }
    FileManager.default.createFile(atPath: fullPath.path, contents: nil, attributes: nil)
    return fullPath
}

func downloadObject(object: GetObjectOutput, filePath: String) async throws {
    do {
        let destinationURL = try createFileInDownload(fromPath: filePath)

        let fileHandle = try FileHandle(forWritingTo: destinationURL)

        guard let body = object.body else {
            throw S3Error(message: "No body returned")
        }

        switch body {
        case .data:
            guard let data = try await body.readData() else {
                throw S3Error(message: "No data returned")
            }
            do {
                try data.write(to: destinationURL)
            } catch {
                throw S3Error(message: "Error while writing file")
            }
            case .stream(let stream as ReadableStream):
            while true {
                let chunk = try await stream.readAsync(upToCount: 5 * 1024 * 1024)
                guard let chunk = chunk else {
                    break
                }

                do {
                    try fileHandle.write(contentsOf: chunk)
                } catch {
                    throw S3Error(message: "Error while writing file")
                }
            }
        default:
            throw S3Error(message: "Received data is unknown object type")
        }
    } catch {
        print("Error while downloading object")
        throw error
    }
}
