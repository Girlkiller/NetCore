//
//  AuthEventHandler.swift
//  NetCore
//
//  Created by feng qiu on 2026/4/13.
//

public protocol AuthEventHandler: Sendable {

    func requireLogin(event: AuthEvent)
}
