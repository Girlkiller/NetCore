//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation

public enum CachePolicy {

    /// 不使用缓存
    case none

    /// 先读缓存，没有再请求网络
    case cacheFirst

    /// 只读缓存，不走网络
    case cacheOnly

    /// 只请求网络，不读缓存
    case networkOnly

    /// 先返回缓存，再刷新网络
    case cacheThenNetwork

    /// 先请求网络，失败再用缓存
    case networkElseCache

}
