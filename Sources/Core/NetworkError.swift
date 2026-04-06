//
//  NetworkError.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation

// MARK: - NetworkError

public enum NetworkError: Error {
    // 核心网络
    case invalidURL
    case network(Error)
    case decode(Error)
    case emptyResponse

    // 缓存相关
    case cacheNotFound
    case cacheExpired
    case cacheSaveFailed

    // 请求去重 / 合并
    case duplicateRequest
    case requestCoalesced

    // Token / Auth
    case tokenRefreshFailed
    case unauthorized
    case forbidden
    case invalidConfiguration

    // 文件上传 / 下载
    case fileNotFound
    case fileSaveFailed
    case uploadFailed

    // 网络状态
    case timeout
    case cancelled
    case offline

    // server相关
    case server(code: Int, message: String, response: APIErrorResponse?, raw: Data?)
}

// MARK: - NetworkError Extension

public extension NetworkError {

    /// 数字 code，用于日志、监控
    var code: Int {
        switch self {
            // 核心网络
        case .invalidURL: return 1000
        case .decode: return 1001
        case .network: return 1002
        case .emptyResponse: return 1003

            // 缓存
        case .cacheNotFound: return 2000
        case .cacheExpired: return 2001
        case .cacheSaveFailed: return 2002

            // 请求去重 / 合并
        case .duplicateRequest: return 3000
        case .requestCoalesced: return 3001

            // Token / Auth
        case .tokenRefreshFailed: return 4000
        case .unauthorized: return 4001
        case .forbidden: return 4002
        case .invalidConfiguration: return 4003

            // 文件上传 / 下载
        case .fileNotFound: return 5000
        case .fileSaveFailed: return 5001
        case .uploadFailed: return 5002

            // 网络状态
        case .timeout: return 6000
        case .cancelled: return 6001
        case .offline: return 6002
        case .server(let code, _, _, _):
            return code
        }
    }

    /// 用于打印 / log 的调试信息
    var debugDescription: String {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .decode(let err): return "Decode error: \(err)"
        case .network(let err): return "Network error: \(err)"
        case .emptyResponse: return "Empty response from server"

        case .cacheNotFound: return "Cache not found"
        case .cacheExpired: return "Cache expired"
        case .cacheSaveFailed: return "Cache save failed"

        case .duplicateRequest: return "Duplicate request detected"
        case .requestCoalesced: return "Request coalesced (merged)"

        case .tokenRefreshFailed: return "Token refresh failed"
        case .unauthorized: return "Unauthorized (401)"
        case .forbidden: return "Forbidden (403)"
        case .invalidConfiguration: return "HttpClient configuration invalid"

        case .fileNotFound: return "File not found for download"
        case .fileSaveFailed: return "Failed to save downloaded file"
        case .uploadFailed: return "Upload failed"

        case .timeout: return "Request timeout"
        case .cancelled: return "Request cancelled"
        case .offline: return "No network connection"
        case .server(let code, let message, _, _):
            return "Server Error, code: \(code), message: \(message)"
        }
    }

    /// App 层本地化 key
    var localizationKey: String {
        switch self {
        case .invalidURL: return "invalid_url"
        case .decode: return "decode_error"
        case .network: return "network_error"
        case .emptyResponse: return "empty_response"

        case .cacheNotFound: return "cache_not_found"
        case .cacheExpired: return "cache_expired"
        case .cacheSaveFailed: return "cache_save_failed"

        case .duplicateRequest: return "duplicate_request"
        case .requestCoalesced: return "request_coalesced"

        case .tokenRefreshFailed: return "token_refresh_failed"
        case .unauthorized: return "unauthorized"
        case .forbidden: return "forbidden"
        case .invalidConfiguration: return "invalid_configuration"

        case .fileNotFound: return "file_not_found"
        case .fileSaveFailed: return "file_save_failed"
        case .uploadFailed: return "upload_failed"

        case .timeout: return "timeout"
        case .cancelled: return "cancelled"
        case .offline: return "offline"
        case .server(let code, _, _, _):
            return "server_error_\(code)"
        }
    }

    /// 底层错误，可用于调试或 log
    var underlyingError: Error? {
        switch self {
        case .decode(let err): return err
        case .network(let err): return err
        default: return nil
        }
    }

    /// 是否适合直接显示给用户
    var shouldShow: Bool {
        switch self {
        case .decode, .invalidConfiguration, .requestCoalesced:
            return false
        default:
            return true
        }
    }
}
