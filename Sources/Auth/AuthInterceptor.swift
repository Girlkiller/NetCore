//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation
import Alamofire

public final class AuthInterceptor: RequestInterceptor {

    private let tokenProvider: TokenProvider

    public init(tokenProvider: TokenProvider) {

        self.tokenProvider = tokenProvider

    }

    public func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {

        Task {

            var request = urlRequest

            if let token = await tokenProvider.accessToken() {

                request.headers.add(
                    name: "Authorization",
                    value: "Bearer \(token)"
                )

            }

            completion(.success(request))

        }

    }

}
