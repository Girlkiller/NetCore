//
//  Endpoint.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Alamofire
import Foundation

public protocol Endpoint {

    var baseURL: String { get }
    var path: String { get }

    var method: HTTPMethod { get }

    var parameters: Parameters? { get }

    var headers: HTTPHeaders? { get }

    var encoding: ParameterEncoding { get }

    var cachePolicy: CachePolicy { get }

    var cacheTTL: TimeInterval? { get }

    var decoder: ResponseDecoder? { get }

    var requestKey: String { get }

    var deduplicationPolicy: RequestDeduplicationPolicy { get }

}

public extension Endpoint {

    var parameters: Parameters? { nil }

    var headers: HTTPHeaders? {
        ["Content-Type": "application/json"]
    }

    var encoding: ParameterEncoding { URLEncoding.default }

    var cachePolicy: CachePolicy { .networkOnly }

    var cacheTTL: TimeInterval? { nil }

    var decoder: ResponseDecoder? { nil }

    var requestKey: String { path }

    var deduplicationPolicy: RequestDeduplicationPolicy { .coalesce }

}
