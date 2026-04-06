//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/4/6.
//

import Foundation

public struct APIErrorResponse: Decodable {
    public let code: Int?
    public let message: String?
}
