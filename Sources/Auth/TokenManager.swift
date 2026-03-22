//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation

public actor TokenManager {

    private let refresher: TokenRefresher

    private var refreshTask: Task<AuthToken, Error>?

    private var refreshAttempts = 0

    private let maxRefreshAttempts: Int

    private let logoutHandler: (() -> Void)?

    public init(
        refresher: TokenRefresher,
        maxRefreshAttempts: Int = 1,
        logoutHandler: (() -> Void)? = nil
    ) {

        self.refresher = refresher
        self.maxRefreshAttempts = maxRefreshAttempts
        self.logoutHandler = logoutHandler

    }
}

extension TokenManager {

    public func refreshIfNeeded() async throws -> AuthToken {

        /// 如果已经在刷新，直接等待
        if let task = refreshTask {

            return try await task.value

        }

        /// 限制刷新次数
        guard refreshAttempts < maxRefreshAttempts else {

            logoutHandler?()

            throw NetworkError.tokenRefreshFailed

        }

        refreshAttempts += 1

        let task = Task<AuthToken, Error> {

            defer { refreshTask = nil }

            do {

                let token = try await refresher.refreshToken()

                refreshAttempts = 0

                return token

            } catch {

                logoutHandler?()

                throw error

            }

        }

        refreshTask = task

        return try await task.value

    }

}
