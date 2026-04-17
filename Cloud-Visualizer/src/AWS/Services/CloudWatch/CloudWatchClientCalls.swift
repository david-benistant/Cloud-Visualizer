//
//  CloudWatchClientCalls.swift
//  Cloud-Visualizer
//
//  Created by Alan Cunin on 04/11/2025.
//

import AWSCloudWatchLogs

import AWSSDKIdentity
import AWSClientRuntime

func authCloudWatch(credentials: CredentialItem, region: AWSRegionItem) async -> CloudWatchClientWrapper? {
    do {
        let awsCredentials = AWSCredentialIdentity(accessKey: credentials.AWSKeyId, secret: credentials.AWSSecretAccessKey)
        let identityResolver = try StaticAWSCredentialIdentityResolver(awsCredentials)
        let configuration = try await CloudWatchLogsClient.CloudWatchLogsClientConfiguration(
            awsCredentialIdentityResolver: identityResolver,
            region: region.region,
            clientLogMode: .responseWithBody
        )
        
        if !credentials.endpoint.isEmpty {
            configuration.endpoint = credentials.endpoint
        }
        
        let client = CloudWatchLogsClient(config: configuration)
        
        return CloudWatchClientWrapper(client: client, region: region)
    } catch {
        print("Failed to configure CloudWatch Client: \(error.localizedDescription)")
        return nil
    }
}

func listCloudWatchGroups(client: CloudWatchClientWrapper) async throws -> [TableLine] {
    let input = DescribeLogGroupsInput()
    let paginator = client.logsClient.describeLogGroupsPaginated(input: input)
    var allGroups: [CloudWatchLogsClientTypes.LogGroup] = []

    for try await page in paginator {
        allGroups.append(contentsOf: page.logGroups ?? [])
    }

    let sorted = allGroups.sorted { ($0.logGroupName ?? "") < ($1.logGroupName ?? "") }
    return try await wrapCloudWatchGroupList(groupList: sorted, client: client)
}

func wrapCloudWatchGroupList(groupList: [CloudWatchLogsClientTypes.LogGroup],
                             client: CloudWatchClientWrapper) async throws -> [TableLine] {
    var output: [TableLine] = []
    
    for group in groupList {
        let name = group.logGroupName ?? "N/A"
        let arn = group.arn ?? "N/A"
        let item = TableLine(items: [
            TableItem(type: .string, value: name),
            TableItem(type: .string, value: arn)
        ], additional: group)
        
        output.append(item)
    }
    return output
}
