//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation

actor OfflineQueue {

    static let shared = OfflineQueue()

    private var queue:[OfflineRequest] = []

}

extension OfflineQueue {

    func enqueue(_ request:OfflineRequest) {

        queue.append(request)

        persist()

    }

}

private extension OfflineQueue {

    func persist() {

        let url = FileManager.default
            .urls(for:.cachesDirectory,in:.userDomainMask)[0]
            .appendingPathComponent("offline_queue")

        if let data = try? JSONEncoder().encode(queue) {

            try? data.write(to:url)

        }

    }

}
