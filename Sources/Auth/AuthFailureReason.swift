//
//  AuthAction.swift
//  NetCore
//
//  Created by feng qiu on 2026/4/13.
//

import Foundation

public enum AuthFailureReason: Int, Sendable {
    case tokenMissing = 1101
    case tokenInvalid = 1102
    case tokenExpired = 1103
    case tokenRevoked = 1104
    case refreshTokenExpired = 1105
    case refreshTokenInvalid = 1106
    case sessionRevoked = 1107
}
