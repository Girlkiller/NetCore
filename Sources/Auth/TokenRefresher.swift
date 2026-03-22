//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation

public protocol TokenRefresher: Sendable {

    func refreshToken() async throws -> AuthToken

}
