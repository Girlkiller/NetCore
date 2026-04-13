//
//  AuthEvent.swift
//  NetCore
//
//  Created by feng qiu on 2026/4/13.
//

import Foundation

public struct AuthEvent: Sendable {

    public let reason: AuthFailureReason
    public let code: Int?
}
