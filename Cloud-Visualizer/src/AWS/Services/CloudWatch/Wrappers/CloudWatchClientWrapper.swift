import AWSCloudWatchLogs
import SwiftUI

class CloudWatchClientWrapper: Equatable {
    var logsClient: CloudWatchLogsClient
    var region: AWSRegionItem
    
    init(client: CloudWatchLogsClient, region: AWSRegionItem) {
        self.logsClient = client
        self.region = region
    }
    
    static func == (lhs: CloudWatchClientWrapper, rhs: CloudWatchClientWrapper) -> Bool {
        return lhs.logsClient === rhs.logsClient
    }
}
