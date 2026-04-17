//
//  CloudWatchError.swift
//  Cloud-Visualizer
//
//  Created by Alan Cunin on 04/11/2025.
//

struct CloudWatchError: Error {
    let message: String
    let detail: String?
    let client: CloudWatchClientWrapper?

    init(message: String, detail: String? = nil, client: CloudWatchClientWrapper? = nil) {
        self.message = message
        self.detail = detail
        self.client = client
    }
}
