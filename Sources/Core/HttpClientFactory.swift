//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation
import Alamofire

public enum HttpClientFactory {

    public static func makeSession(
        config: HttpClientConfig
    ) -> Session {

        let configuration = URLSessionConfiguration.default

        configuration.timeoutIntervalForRequest = config.timeout

        return Session(
            configuration: configuration,
            interceptor: config.interceptor,
            eventMonitors: config.eventMonitors
        )

    }

}
