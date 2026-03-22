//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/22.
//

import Foundation

public struct AuthToken: Sendable, Codable {

    public let accessToken: String
    public let refreshToken: String

    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
