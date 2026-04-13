//
//  AuthAction.swift
//  NetCore
//
//  Created by feng qiu on 2026/4/12.
//

import Foundation

public enum AuthAction: Sendable {

    /// 自动刷新 access token
    case refreshAccessToken

    /// 需要重新登录（统一入口）
    case requireLogin

    /// 忽略（ 非关键错误）
    case ignore
}
