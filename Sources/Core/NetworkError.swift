//
//  NetworkError.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation

public enum NetworkError: Error {

    case invalidURL
    case decode(Error)
    case network(Error)
    case cacheNotFound
    case duplicateRequest
    case emptyResponse
    case tokenRefreshFailed

}
