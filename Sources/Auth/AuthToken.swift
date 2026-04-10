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

    private enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case access_token
        case refresh_token
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.accessToken =
        try container.decodeIfPresent(String.self, forKey: .accessToken)
        ?? container.decode(String.self, forKey: .access_token)

        self.refreshToken =
        try container.decodeIfPresent(String.self, forKey: .refreshToken)
        ?? container.decode(String.self, forKey: .refresh_token)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // 👉 统一编码为 snake_case（推荐）
        try container.encode(accessToken, forKey: .access_token)
        try container.encode(refreshToken, forKey: .refresh_token)
    }
}
