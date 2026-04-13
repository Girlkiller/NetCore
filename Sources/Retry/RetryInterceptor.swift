//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation
import Alamofire

public final class RetryInterceptor: RequestInterceptor {

    private let maxRetryCount: Int
    private let retryDelay: TimeInterval

    public init(
        maxRetryCount: Int = 2,
        retryDelay: TimeInterval = 1.0
    ) {
        self.maxRetryCount = maxRetryCount
        self.retryDelay = retryDelay
    }

    public func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {

        // ❌ 已达到重试上限
        guard request.retryCount < maxRetryCount else {
            completion(.doNotRetry)
            return
        }

        // ❌ 不是网络错误 → 不重试
        guard let afError = error.asAFError,
              afError.isSessionTaskError || afError.isResponseSerializationError
        else {
            completion(.doNotRetry)
            return
        }

        // ✔ 网络错误 → 重试
        completion(.retryWithDelay(retryDelay))
    }
}
