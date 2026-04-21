//
//  AuthInterceptor.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation
import Alamofire

public extension Notification.Name {
    static let tokenExpired = Notification.Name("tokenExpired")
    static let authExpired = Notification.Name("authExpired")
}

public final class AuthInterceptor: RequestInterceptor, @unchecked Sendable {

    private let tokenProvider: TokenProvider
    private let tokenManager: TokenManager?
    private let eventHandler: AuthEventHandler?

    private let state = AuthState()

    public init(
        tokenProvider: TokenProvider,
        tokenManager: TokenManager? = nil,
        eventHandler: AuthEventHandler? = nil
    ) {
        self.tokenProvider = tokenProvider
        self.tokenManager = tokenManager
        self.eventHandler = eventHandler
    }
}

// MARK: - Adapt

public extension AuthInterceptor {

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {

        var request = urlRequest

        Task {
            if let token = await tokenProvider.accessToken() {
                request.headers.update(
                    name: "Authorization",
                    value: "Bearer \(token)"
                )
            }
            completion(.success(request))
        }
    }
}

// MARK: - Retry（仅兜底）

extension AuthInterceptor {
    public func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {

        Task {

            // ✅ 1. 业务 auth error
            if let networkError = error as? NetworkError,
               case .authFailure(let reason) = networkError {

                await handleBusinessRetry(reason: reason, completion: completion)
                return
            }

            // ✅ 2. HTTP 401 fallback
            if let response = request.task?.response as? HTTPURLResponse,
               response.statusCode == 401 {

                await refreshAccessTokenFallback(completion)
                return
            }

            completion(.doNotRetry)
        }
    }
}

// MARK: - 401 fallback refresh

private extension AuthInterceptor {

    func refreshAccessTokenFallback(
        _ completion: @escaping (RetryResult) -> Void
    ) async {
        guard let tokenManager else { return }
        await state.enqueue(completion)

        guard await state.beginRefreshTokenIfNeeded() else { return }

        do {
            let token = try await tokenManager.refreshIfNeeded()

            await tokenProvider.updateAccessToken(token.accessToken)
            await tokenProvider.updateRefreshToken(token.refreshToken)

            emitTokenRefreshed()

            let callbacks = await state.takeAll()
            callbacks.forEach { $0(.retry) }

        } catch {

            let callbacks = await state.takeAll()
            callbacks.forEach { $0(.doNotRetryWithError(error)) }

            emitLogin(reason: .refreshTokenExpired, code: nil)
        }
    }

    private func handleBusinessRetry(
        reason: AuthFailureReason,
        completion: @escaping (RetryResult) -> Void
    ) async {

        guard let tokenManager else {
            completion(.doNotRetry)
            return
        }

        await state.enqueue(completion)

        guard await state.beginRefreshTokenIfNeeded() else { return }

        let action = AuthCodeRouter.route(reason)

        switch action {

        case .refreshAccessToken:

            do {
                let token = try await tokenManager.refreshIfNeeded()

                await tokenProvider.updateAccessToken(token.accessToken)
                await tokenProvider.updateRefreshToken(token.refreshToken)

                emitTokenRefreshed()

                let callbacks = await state.takeAll()
                callbacks.forEach { $0(.retry) }

            } catch {

                let callbacks = await state.takeAll()
                callbacks.forEach { $0(.doNotRetryWithError(error)) }

                emitLogin(reason: .refreshTokenExpired, code: nil)
            }

        case .requireLogin:

            let callbacks = await state.takeAll()
            callbacks.forEach { $0(.doNotRetry) }

            emitLogin(reason: reason, code: reason.rawValue)

        case .ignore:

            let callbacks = await state.takeAll()
            callbacks.forEach { $0(.doNotRetry) }
        }
    }
}

// MARK: - Emit Login

private extension AuthInterceptor {

    func emitLogin(reason: AuthFailureReason, code: Int?) {

        eventHandler?.requireLogin(
            event: AuthEvent(
                type: .requireLogin,
                reason: reason,
                code: code
            )
        )
    }

    func emitTokenRefreshed() {
        eventHandler?.tokenRefreshed(
            event: AuthEvent(
                type: .tokenRefreshed,
                reason: nil,
                code: nil
            )
        )
    }
}
