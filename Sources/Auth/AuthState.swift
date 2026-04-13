//
//  AuthState.swift
//  NetCore
//
//  Created by feng qiu on 2026/4/12.
//

import Foundation
import Alamofire

actor AuthState {

    private var isRefreshingAccess = false
    private var isRefreshingRefresh = false

    private var queue: [(RetryResult) -> Void] = []

    func enqueue(_ c: @escaping (RetryResult) -> Void) {
        queue.append(c)
    }

    func takeAll() -> [(RetryResult) -> Void] {
        let q = queue
        queue.removeAll()
        isRefreshingAccess = false
        isRefreshingRefresh = false
        return q
    }

    func beginAccessRefreshIfNeeded() -> Bool {
        guard !isRefreshingAccess else { return false }
        isRefreshingAccess = true
        return true
    }

    func beginRefreshTokenIfNeeded() -> Bool {
        guard !isRefreshingRefresh else { return false }
        isRefreshingRefresh = true
        return true
    }
}
