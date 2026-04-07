//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation
import Alamofire

public struct HttpClientConfig {

    public var timeout: TimeInterval

    public var interceptor: RequestInterceptor?

    public var eventMonitors: [EventMonitor]

    public let commonHeaders: HTTPHeaders?

    public var mockProvider: MockProvider?

    public var decoder: ResponseDecoder?

    public init(
        timeout: TimeInterval = 30,
        interceptor: RequestInterceptor? = nil,
        commonHeaders: HTTPHeaders? = nil,
        eventMonitors: [EventMonitor] = [],
        mockProvider: MockProvider? = nil,
        decoder: ResponseDecoder? = nil
    ) {

        self.timeout = timeout
        self.interceptor = interceptor
        self.commonHeaders = commonHeaders
        self.eventMonitors = eventMonitors
        self.mockProvider = mockProvider
        self.decoder = decoder

    }

}
