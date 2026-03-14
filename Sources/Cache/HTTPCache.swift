//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation

public final class HTTPCache {

    public static let shared = HTTPCache()

    private let maxSize: UInt64 = 100 * 1024 * 1024

    private let cacheDir: URL

    private init() {

        cacheDir = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("NetCoreCache")

        try? FileManager.default.createDirectory(
            at: cacheDir,
            withIntermediateDirectories: true
        )

    }

}

extension HTTPCache {
    public func save(
        _ data: Data,
        key: String
    ) {

        let url = fileURL(for: key)

        try? data.write(to: url)

        cleanIfNeeded()

    }

    public func load(key: String) -> Data? {

        let url = fileURL(for: key)

        return try? Data(contentsOf: url)

    }

    public func isExpired(
        key: String,
        ttl: TimeInterval
    ) -> Bool {

        let url = fileURL(for: key)

        guard
            let attr = try? FileManager.default.attributesOfItem(
                atPath: url.path
            ),
            let date = attr[.modificationDate] as? Date
        else {
            return true
        }

        return Date().timeIntervalSince(date) > ttl

    }

    func fileURL(for key: String) -> URL {

        let name = key.addingPercentEncoding(
            withAllowedCharacters: .urlHostAllowed
        ) ?? key

        return cacheDir.appendingPathComponent(name)

    }

    private func cleanIfNeeded() {

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDir,
            includingPropertiesForKeys: [
                .contentModificationDateKey,
                .fileSizeKey
            ]
        ) else { return }

        var total: UInt64 = 0

        var fileInfos: [(URL, Date, UInt64)] = []

        for url in files {

            let values = try? url.resourceValues(
                forKeys: [
                    .contentModificationDateKey,
                    .fileSizeKey
                ]
            )

            let size = UInt64(values?.fileSize ?? 0)

            let date = values?.contentModificationDate ?? Date()

            total += size

            fileInfos.append((url, date, size))

        }

        if total < maxSize { return }

        let sorted = fileInfos.sorted { $0.1 < $1.1 }

        var current = total

        for file in sorted {

            try? FileManager.default.removeItem(at: file.0)

            current -= file.2

            if current < maxSize { break }

        }

    }

}
