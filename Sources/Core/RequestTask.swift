//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/4/6.
//

import Foundation
import Alamofire

public enum RequestTask {

    /// 无参数
    case plain

    /// URL query（GET）
    case query([URLQueryItem])

    /// JSON body
    case json(Encodable)

    /// 表单
    case form([String: Any])

    /// 上传
    case multipart((MultipartFormData) -> Void)

    /// 原始数据（protobuf / 二进制）
    case raw(Data, contentType: String)
}
