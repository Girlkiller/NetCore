//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation

public enum RequestDeduplicationPolicy {

    /// 请求合并
    case coalesce

    /// 允许重复
    case allowDuplicate

    /// 拒绝重复
    case rejectDuplicate

}
