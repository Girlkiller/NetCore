//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation
import Alamofire

final class NetworkLogger: EventMonitor {

    let queue = DispatchQueue(label: "netcore.logger")

    func requestDidResume(_ request: Request) {

        print("➡️ \(request)")
    }

    func request(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Data?,AFError>
    ) {

        print("⬅️ \(response.debugDescription)")
    }
}
