//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation
import Alamofire

public final class RetryInterceptor: RequestInterceptor {

    let tokenManager: TokenManager

    public init(tokenManager: TokenManager) {

        self.tokenManager = tokenManager

    }

    public func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {

        guard
            let response = request.task?.response as? HTTPURLResponse,
            response.statusCode == 401
        else {

            completion(.doNotRetry)
            return

        }

        /// 避免单请求无限 retry
        if request.retryCount >= 1 {

            completion(.doNotRetry)

            return

        }

        Task {

            do {

                _ = try await tokenManager.refreshIfNeeded()

                completion(.retry)

            } catch {

                completion(.doNotRetry)

            }

        }

    }

}
