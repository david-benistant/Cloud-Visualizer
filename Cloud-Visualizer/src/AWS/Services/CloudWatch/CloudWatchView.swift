//
//  CloudWatchView.swift
//  Cloud-Visualizer
//
//  Created by Alan Cunin on 04/11/2025.
//

import SwiftUI
import AWSCloudWatchLogs

private struct CloudWatch: View {
    @State private var cloudWatchClient: CloudWatchClientWrapper?
    
    var body: some View {
        CloudWatchTable(cloudwatchClient: $cloudWatchClient)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    AWSHeader(callback: doAuth)
                }
            }
    }
    
    func doAuth(cred: CredentialItem, region: AWSRegionItem) {
        Task {
            if let client = await authCloudWatch(credentials: cred, region: region) {
                cloudWatchClient = client
            }
        }
    }
}

struct CloudWatchView: View {
    var body: some View {
        Nav(AnyView(CloudWatch()), rootLabel: "CloudWatch")
    }
}
