//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/4/6.
//

import Foundation

public struct AnyEncodable: Encodable {

    private let encodeFunc: (Encoder) throws -> Void

    public init(_ encodable: Encodable) {
        self.encodeFunc = encodable.encode
    }

    public func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}
