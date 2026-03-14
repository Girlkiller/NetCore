//
//  TokenStore.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation

public protocol TokenStore {

    var accessToken: String? { get set }

    var refreshToken: String? { get set }

}

public final class MemoryTokenStore: TokenStore {

    public var accessToken: String?

    public var refreshToken: String?

}
