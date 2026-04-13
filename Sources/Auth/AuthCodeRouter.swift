//
//  AuthCodeRouter.swift
//  NetCore
//
//  Created by feng qiu on 2026/4/12.
//

import Foundation

/*
     TOKEN_MISSING = 1101
     TOKEN_INVALID = 1102
     TOKEN_EXPIRED = 1103
     TOKEN_REVOKED = 1104
     REFRESH_TOKEN_EXPIRED = 1105
     REFRESH_TOKEN_INVALID = 1106
     SESSION_REVOKED = 1107
 */

public struct AuthCodeRouter {

    public static func route(_ reason: AuthFailureReason) -> AuthAction {

        switch reason {
        case .tokenMissing:
            return .requireLogin
        case .tokenInvalid, .tokenExpired:
            return .refreshAccessToken
        case .tokenRevoked:
            return .requireLogin
        case .refreshTokenExpired:
            return .requireLogin
        case .refreshTokenInvalid:
            return .requireLogin
        case .sessionRevoked:
            return .requireLogin
        }
    }

    public static func reason(_ code: Int) -> AuthFailureReason? {
        AuthFailureReason(rawValue: code)
    }
}
