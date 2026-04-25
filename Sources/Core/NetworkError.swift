//
//  NetworkError.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation
import Alamofire

// MARK: - NetworkError

public enum NetworkError: Error {
    case invalidConfiguration
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
    case authFailure(AuthFailureReason)

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
        case .invalidConfiguration: return 4003
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
        case .authFailure(let reason): return reason.rawValue

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
        case .invalidConfiguration:
            return "[Config] ❌ HttpClient configuration invalid"

        case .invalidURL:
            return "[Network] ❌ Invalid URL"

        case .decode(let err):
            return "[Decode] ❌ Failed to decode response → \(err)"

        case .network(let err):
            return "[Network] ❌ Request failed → \(err.localizedDescription)"

        case .emptyResponse:
            return "[Network] ⚠️ Empty response from server"

            // MARK: - Cache

        case .cacheNotFound:
            return "[Cache] ⚠️ Cache not found"

        case .cacheExpired:
            return "[Cache] ⚠️ Cache expired"

        case .cacheSaveFailed:
            return "[Cache] ❌ Failed to save cache"

            // MARK: - Deduplication

        case .duplicateRequest:
            return "[Request] ⚠️ Duplicate request detected"

        case .requestCoalesced:
            return "[Request] ℹ️ Request coalesced (merged)"

            // MARK: - Auth

        case .authFailure(let reason):
            switch reason {
            case .tokenMissing:
                return "[Auth] ❌ Token missing (\(reason.rawValue))"
            case .tokenInvalid:
                return "[Auth] ❌ Token invalid (\(reason.rawValue))"
            case .tokenExpired:
                return "[Auth] ❌ Token expired (\(reason.rawValue))"
            case .tokenRevoked:
                return "[Auth] ❌ Token revoked (\(reason.rawValue))"
            case .refreshTokenExpired:
                return "[Auth] ❌ Refresh token expired (\(reason.rawValue))"
            case .refreshTokenInvalid:
                return "[Auth] ❌ Refresh token invalid (\(reason.rawValue))"
            case .sessionRevoked:
                return "[Auth] ❌ Session revoked (\(reason.rawValue))"
            }

            // MARK: - File

        case .fileNotFound:
            return "[File] ❌ File not found"

        case .fileSaveFailed:
            return "[File] ❌ Failed to save file"

        case .uploadFailed:
            return "[Upload] ❌ Upload failed"

            // MARK: - Network State

        case .timeout:
            return "[Network] ⏱ Timeout"

        case .cancelled:
            return "[Network] ⚠️ Request cancelled"

        case .offline:
            return "[Network] ❌ No internet connection"

            // MARK: - Server

        case .server(let code, let message, let response, _):

            let bizCode = response?.code ?? -1

            return """
        [Server] ❌ HTTP \(code)
        businessCode: \(bizCode)
        message: \(message)
        """
        }
    }

    /// App 层本地化 key
    var localizationKey: String {
        switch self {
        case .invalidConfiguration: return "invalid_configuration"
        case .invalidURL: return "invalid_url"
        case .decode: return "decode_error"
        case .network: return "network_error"
        case .emptyResponse: return "empty_response"

        case .cacheNotFound: return "cache_not_found"
        case .cacheExpired: return "cache_expired"
        case .cacheSaveFailed: return "cache_save_failed"

        case .duplicateRequest: return "duplicate_request"
        case .requestCoalesced: return "request_coalesced"

        case .authFailure(let reason): return "auth_failure_\(reason)"

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
        case .decode, .requestCoalesced:
            return false
        default:
            return true
        }
    }
}

extension NetworkError {
    static func from(_ error: Error) -> NetworkError {

        // ✅ 1. 如果已经是 NetworkError，直接返回
        if let networkError = error as? NetworkError {
            return networkError
        }

        // ✅ 2. Alamofire 错误
        if let afError = error.asAFError {
            return mapAFError(afError)
        }

        // ✅ 3. URLSession 原生错误
        if let urlError = error as? URLError {
            return mapURLError(urlError)
        }

        // ✅ 4. 解码错误
        if error is DecodingError {
            return .decode(error)
        }

        // ✅ 5. fallback
        return .network(error)
    }
}

private extension NetworkError {

    static func mapURLError(_ error: URLError) -> NetworkError {
        switch error.code {

        case .timedOut:
            return .timeout

        case .notConnectedToInternet:
            return .offline

        case .networkConnectionLost:
            return .offline

        case .cannotConnectToHost,
                .cannotFindHost,
                .dnsLookupFailed:
            return .network(error)

        case .cancelled:
            return .cancelled

        default:
            return .network(error)
        }
    }
}

private extension NetworkError {

    static func mapAFError(_ error: AFError) -> NetworkError {
        switch error {

        case .sessionTaskFailed(let underlyingError):
            return NetworkError.from(underlyingError)

        case .responseSerializationFailed:
            return .decode(error)

        case .invalidURL:
            return .invalidURL

        case .createURLRequestFailed:
            return .invalidConfiguration

        case .explicitlyCancelled:
            return .cancelled

            // ✅ 关键补充
        case .responseValidationFailed(let reason):
            switch reason {

            case .customValidationFailed(let error):
                if let networkError = error as? NetworkError {
                    return networkError
                }
                return .network(error)

            default:
                return .network(error)
            }

        default:
            return .network(error)
        }
    }
}
