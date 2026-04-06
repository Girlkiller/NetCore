//
//  File.swift
//  NetCore
//
//  Created by feng qiu on 2026/3/14.
//

import Foundation
import Alamofire

public final class HttpClient {

    private let session: Session

    private let config: HttpClientConfig

    public init(config: HttpClientConfig) {

        self.config = config
        self.session = HttpClientFactory.makeSession(config: config)

    }
}

public extension HttpClient {

    static func `default`(
        tokenProvider: TokenProvider? = nil,
        mockProvider: MockProvider? = nil
    ) -> HttpClient {

        let interceptor: RequestInterceptor? = tokenProvider.map {
            AuthInterceptor(tokenProvider: $0)
        }

        let config = HttpClientConfig(
            interceptor: interceptor,
            eventMonitors: [NetworkLogger()],
            mockProvider: mockProvider
        )

        return HttpClient(config: config)

    }

}

extension HttpClient {

    /// 选择 Decoder
    private func decoder(for endpoint: Endpoint) -> ResponseDecoder {

        if let decoder = endpoint.decoder {
            return decoder
        }

        if let decoder = config.decoder {
            return decoder
        }

        return JSONDecoderAdapter()

    }

}

extension HttpClient {

    /// 生成 cache key
    private func cacheKey(for endpoint: Endpoint) -> String {

        var key = endpoint.baseURL + endpoint.path

        if let params = endpoint.parameters {

            let sorted = params
                .map { "\($0.key)=\($0.value)" }
                .sorted()
                .joined(separator: "&")

            key += "?\(sorted)"
        }

        return key

    }

}


extension HttpClient {

    /// 读取缓存
    private func readCache<T: Decodable>(
        _ endpoint: Endpoint,
        type: T.Type
    ) throws -> T? {

        let key = cacheKey(for: endpoint)

        guard let data = HTTPCache.shared.load(key: key)
        else { return nil }

        if let ttl = endpoint.cacheTTL {

            if HTTPCache.shared.isExpired(key: key, ttl: ttl) {
                return nil
            }

        }

        let decoder = decoder(for: endpoint)

        return try decoder.decode(T.self, from: data)

    }

}

// MARK: - request

public extension HttpClient {

    func request<T: Decodable>(
        _ endpoint: Endpoint,
        type: T.Type
    ) async throws -> T {

        /// Mock
        if let mock = config.mockProvider?.mockData(for: endpoint) {

            return try decoder(for: endpoint)
                .decode(T.self, from: mock)

        }

        /// cacheOnly
        if endpoint.cachePolicy == .cacheOnly {

            if let cache: T = try readCache(endpoint, type: T.self) {
                return cache
            }

            throw NetworkError.cacheNotFound
        }

        /// cacheFirst
        if endpoint.cachePolicy == .cacheFirst {

            if let cache: T = try readCache(endpoint, type: T.self) {
                return cache
            }

        }

        let requestKey = endpoint.requestKey

        switch endpoint.deduplicationPolicy {

        case .coalesce:

            if let existing: Task<T, Error> =
                await RequestPool.shared.get(requestKey) {

                return try await existing.value
            }

        case .rejectDuplicate:

            if await RequestPool.shared.exists(requestKey) {
                throw NetworkError.duplicateRequest
            }

        case .allowDuplicate:
            break

        }

        let task = Task<T, Error> {

            defer {

                Task {
                    await RequestPool.shared.remove(requestKey)
                }

            }

            return try await performRequest(endpoint)

        }

        if endpoint.deduplicationPolicy != .allowDuplicate {

            await RequestPool.shared.set(requestKey, task: task)

        }

        return try await task.value

    }

}

private extension HttpClient {

    func performRequest<T: Decodable>(
        _ endpoint: Endpoint
    ) async throws -> T {

        let key = cacheKey(for: endpoint)

        let urlString = endpoint.baseURL + endpoint.path

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        let response = await session.request(
            url,
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: endpoint.encoding,
            headers: endpoint.headers
        )
            .serializingData()
            .response

        /// ✅ 1. 先拿 HTTP 状态码
        let statusCode = response.response?.statusCode

        switch response.result {

        case .success(let data):

            /// ✅ 2. 判断 HTTP code
            guard let code = statusCode else {
                throw NetworkError.emptyResponse
            }

            /// ✅ 3. 成功范围（200~299）
            if (200..<300).contains(code) {

                if endpoint.cachePolicy != .none {
                    HTTPCache.shared.save(data, key: key)
                }

                return try decoder(for: endpoint)
                    .decode(T.self, from: data)
            }

            /// ❗ 4. 非 2xx：解析 error body
            let apiError = try? decoder(for: endpoint)
                .decode(APIErrorResponse.self, from: data)

            throw NetworkError.server(
                code: code,
                message: apiError?.message ?? "Unknown error",
                response: apiError,
                raw: data
            )

        case .failure(let error):

            /// networkElseCache
            if endpoint.cachePolicy == .networkElseCache {
                if let cache: T = try readCache(endpoint, type: T.self) {
                    return cache
                }
            }

            throw NetworkError.network(error)
        }
    }
}

public extension HttpClient {

    func upload<T: Decodable>(
        _ endpoint: Endpoint,
        data: Data,
        progress: ((Double) -> Void)? = nil,
        type: T.Type
    ) async throws -> T {

        let urlString = endpoint.baseURL + endpoint.path

        guard let url = URL(string: urlString)
        else { throw NetworkError.invalidURL }

        let request = session.upload(
            data,
            to: url,
            method: endpoint.method,
            headers: endpoint.headers
        )

        request.uploadProgress { prog in
            progress?(prog.fractionCompleted)
        }

        let response = await request.serializingData().response

        switch response.result {

        case .success(let data):

            let decoder = decoder(for: endpoint)

            return try decoder.decode(T.self, from: data)

        case .failure(let error):

            throw NetworkError.network(error)

        }

    }

}

public extension HttpClient {

    func download(
        url: String,
        progress: ((Double) -> Void)? = nil
    ) async throws -> URL {

        guard let url = URL(string: url) else {
            throw NetworkError.invalidURL
        }

        let request = session.download(url)

        request.downloadProgress { prog in
            progress?(prog.fractionCompleted)
        }

        let response = await request
            .serializingDownloadedFileURL()
            .response

        switch response.result {

        case .success(let fileURL):

            return fileURL

        case .failure(let error):

            throw NetworkError.network(error)

        }

    }

}
