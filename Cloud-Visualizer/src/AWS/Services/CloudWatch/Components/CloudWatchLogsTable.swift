//
//  CloudWatchLogsTable.swift
//  Cloud-Visualizer
//
//  Created by Alan Cunin on 04/11/2025.
//

import SwiftUI
import AWSCloudWatchLogs

private let tableConfig: [TableConfig] = [
    TableConfig(label: "Log Group Name"),
    TableConfig(label: "ARN"),
]

struct CloudWatchGroupDetail: View {
    let logGroupName: String
    let client: CloudWatchClientWrapper
    
    @State private var logStreams: [CloudWatchLogsClientTypes.LogStream] = []
    @State private var selectedStreamName: String?
    @State private var logEvents: [CloudWatchLogsClientTypes.OutputLogEvent] = []
    @State private var isLoadingEvents = false
    @State private var eventsError: String?

    @State private var retentionInDays: Int?
    @State private var creationTime: Date?
    @State private var arn: String?

    var body: some View {
        HStack(spacing: 0) {
            // Left sidebar - Log Streams
            VStack(alignment: .leading, spacing: 10) {
                Text("Log Streams")
                    .font(.headline)
                    .padding(.top)
                
                List(logStreams, id: \.logStreamName) { stream in
                    let streamName = stream.logStreamName ?? "Stream Inconnu"
                    
                    Button(action: {
                        selectedStreamName = streamName
                        Task {
                            await loadLogEvents(for: streamName)
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(streamName)
                                .foregroundColor(selectedStreamName == streamName ? .accentColor : .primary)
                                .lineLimit(1)
                            
                            if let lastEvent = stream.lastEventTimestamp {
                                Text(formatTimestamp(lastEvent))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.sidebar)
                .frame(width: 300)
            }
            .background(Color.secondary.opacity(0.1))
            
            Divider()
            
            // Right side - Log Events
            VStack(spacing: 0) {
                if let selectedStream = selectedStreamName {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedStream)
                            .font(.headline)
                        
                        if isLoadingEvents {
                            ProgressView()
                                .progressViewStyle(.linear)
                        }
                        
                        if let error = eventsError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.05))
                    
                    Divider()
                    
                    // Log Events List
                    if logEvents.isEmpty && !isLoadingEvents {
                        VStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No log events found")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(logEvents.enumerated()), id: \.offset) { index, event in
                                    LogEventRow(event: event)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                } else {
                    // No stream selected
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Select a Log Stream")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Choose a log stream from the list to view its events")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task {
            await loadDetails()
            await loadLogStreams()
        }
        .navigationTitle(logGroupName)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    Task {
                        await loadLogStreams()
                        if let selected = selectedStreamName {
                            await loadLogEvents(for: selected)
                        }
                    }
                }) {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
            }
        }
    }

    private func formatTimestamp(_ millis: Int) -> String {
        let date = Date(timeIntervalSince1970: Double(millis) / 1000.0)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func loadDetails() async {
        do {
            let input = DescribeLogGroupsInput(logGroupNamePrefix: logGroupName)
            let output = try await client.logsClient.describeLogGroups(input: input)
            if let group = output.logGroups?.first(where: { $0.logGroupName == logGroupName }) {
                await MainActor.run {
                    arn = group.logGroupArn
                    retentionInDays = group.retentionInDays
                    if let timeMillis = group.creationTime {
                        creationTime = Date(timeIntervalSince1970: Double(timeMillis) / 1000.0)
                    }
                }
            }
        } catch {
            print("Failed loading log group details: \(error)")
        }
    }
    
    private func loadLogStreams() async {
        do {
            let input = DescribeLogStreamsInput(
                logGroupName: logGroupName
            )
            
            let paginator = client.logsClient.describeLogStreamsPaginated(input: input)
            var allStreams: [CloudWatchLogsClientTypes.LogStream] = []
            
            for try await page in paginator {
                allStreams.append(contentsOf: page.logStreams ?? [])
            }
            
            let sorted = allStreams.sorted {
                ($0.lastEventTimestamp ?? 0) > ($1.lastEventTimestamp ?? 0)
            }
            
            await MainActor.run {
                self.logStreams = sorted
                if self.selectedStreamName == nil {
                    self.selectedStreamName = sorted.first?.logStreamName
                    if let firstStream = sorted.first?.logStreamName {
                        Task {
                            await loadLogEvents(for: firstStream)
                        }
                    }
                }
            }
           
        } catch {
            print("Failed loading log streams for \(logGroupName): \(error)")
            await MainActor.run {
                self.logStreams = []
            }
        }
    }
    
    private func loadLogEvents(for streamName: String) async {
        await MainActor.run {
            isLoadingEvents = true
            eventsError = nil
        }
        
        do {
            let input = GetLogEventsInput(
                limit: 100,
                logGroupName: logGroupName,
                logStreamName: streamName,
                startFromHead: true
            )

            let output = try await client.logsClient.getLogEvents(input: input)
            let events = output.events ?? []

            await MainActor.run {
                self.logEvents = events
                self.isLoadingEvents = false
            }
            
        } catch {
            print("Failed loading log events: \(error)")
            await MainActor.run {
                self.eventsError = "Failed to load events: \(error.localizedDescription)"
                self.logEvents = []
                self.isLoadingEvents = false
            }
        }
    }
}

struct LogEventRow: View {
    let event: CloudWatchLogsClientTypes.OutputLogEvent
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                if let timestamp = event.timestamp {
                    Text(formatFullTimestamp(timestamp))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(width: 180, alignment: .leading)
                }
                
                if let message = event.message {
                    Text(message)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .lineLimit(isExpanded ? nil : 3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(4)
    }
    
    private func formatFullTimestamp(_ millis: Int) -> String {
        let date = Date(timeIntervalSince1970: Double(millis) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}

struct CloudWatchTable: View {
    @Binding var cloudwatchClient: CloudWatchClientWrapper?
    @EnvironmentObject var navModel: NavModel
    @StateObject private var tableItems: TableModel = TableModel(tableConfig: tableConfig)
    @State private var isDeleteModalOpen = false

    private var sideBarItems: [TableSideBarItem] {
        [
            TableSideBarItem(
                name: "Delete",
                icon: "trash",
                action: { self.isDeleteModalOpen = true },
                disabled: isOneSelected()
            ),
        ]
    }

    private func isOneSelected() -> Bool {
        return !tableItems.items.contains { $0.isSelected }
    }

    private func searchFunction(item: TableLine, search: String) -> Bool {
        if let group = item.additional as? CloudWatchLogsClientTypes.LogGroup {
            if let name = group.logGroupName {
                return name.lowercased().contains(search.lowercased())
            }
        }
        return false
    }

    private func actionFunction(_ item: TableLine) -> TableLine {
        if let group = item.additional as? CloudWatchLogsClientTypes.LogGroup,
           let name  = group.logGroupName,
           let client = cloudwatchClient {
            item.action = { _ in
                navModel.navigate(
                    AnyView(
                        CloudWatchGroupDetail(logGroupName: name, client: client)
                    ),
                    label: name
                )
            }
        }
        return item
    }
    
    // TODO: Implement log group deletion
    private func deleteItem() async {
    }

    var body: some View {
        Table(tableModel: tableItems, sideBarItems: sideBarItems, searchBarFunction: searchFunction)
            .onAppear {
                tableItems.loadContentFunction = { _ in
                    guard let client = cloudwatchClient else { return }
                    Task {
                        do {
                            let groups = try await listCloudWatchGroups(client: client)
                            await MainActor.run {
                                tableItems.items = groups.map(actionFunction)
                            }
                        } catch {
                            print("Error loading log groups: \(error)")
                        }
                    }
                }
            }
            .onChange(of: cloudwatchClient) { _, _ in
                tableItems.items = []
                tableItems.reInit()
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: { tableItems.reload() }) {
                        Image(systemName: "arrow.trianglehead.clockwise")
                    }
                }
            }
            .sheet(isPresented: $isDeleteModalOpen) {
                ConfirmModal(isOpen: $isDeleteModalOpen, onConfirm: deleteItem)
            }
    }
}
