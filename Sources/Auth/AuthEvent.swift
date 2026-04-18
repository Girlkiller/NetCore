//
//  AuthEvent.swift
//  NetCore
//
//  Created by feng qiu on 2026/4/13.
//

import Foundation

public enum AuthEventType {
    case requireLogin
    case tokenRefreshed   // 👈 新增
}

public struct AuthEvent {
    public let type: AuthEventType
    public let reason: AuthFailureReason?
    public let code: Int?
}
