//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation

public protocol MockProvider {

    func mockData(for endpoint: Endpoint) -> Data?

}

public final class DefaultMockProvider: MockProvider {

    private let bundle: Bundle

    public init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    public func mockData(for endpoint: Endpoint) -> Data? {

        let name = endpoint.path
            .replacingOccurrences(of: "/", with: "_")

        guard let url = bundle.url(
            forResource: name,
            withExtension: "json"
        ) else {
            return nil
        }

        return try? Data(contentsOf: url)

    }

}
