//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation

public protocol ResponseDecoder {

    func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data
    ) throws -> T

}

public struct JSONDecoderAdapter: ResponseDecoder {

    private let decoder: JSONDecoder

    public init(_ decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    public func decode<T>(
        _ type: T.Type,
        from data: Data
    ) throws -> T where T : Decodable {

        try decoder.decode(type, from: data)

    }

}
