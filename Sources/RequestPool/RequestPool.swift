//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation

actor RequestPool {

    static let shared = RequestPool()

    private var tasks: [String: Any] = [:]

    func get<T>(_ key: String) -> Task<T, Error>? {
        tasks[key] as? Task<T, Error>
    }

    func set<T>(_ key: String, task: Task<T, Error>) {
        tasks[key] = task
    }

    func remove(_ key: String) {
        tasks.removeValue(forKey: key)
    }

    /// 只检查是否存在
    func exists(_ key: String) -> Bool {
        tasks[key] != nil
    }

}
