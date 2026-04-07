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

        guard let url = try? buildURL(from: endpoint) else {
            return UUID().uuidString
        }

        var key = url.absoluteString

        /// ✅ method
        key += "|\(endpoint.method.rawValue)"

        /// ✅ task（核心）
        key += "|task:\(taskCacheKey(endpoint.task))"

        /// ✅ 用户隔离
        if let token = buildHeaders(for: endpoint)?["Authorization"] {
            key += "|auth:\(token)"
        }

        return key
    }

    private func taskCacheKey(_ task: RequestTask) -> String {

        switch task {

        case .plain:
            return "plain"

        case .query(let items):

            let sorted = items
                .sorted { $0.name < $1.name }
                .map { "\($0.name)=\($0.value ?? "")" }
                .joined(separator: "&")

            return "query:\(sorted)"

        case .json(let body):

            return "json:\(encodeEncodable(body))"

        case .form(let params):

            let sorted = params
                .map { "\($0.key)=\(stringify($0.value))" }
                .sorted()
                .joined(separator: "&")

            return "form:\(sorted)"

        case .raw(let data, _):

            return "raw:\(data.hashValue)"

        case .multipart:

            /// ⚠️ multipart 一般不建议缓存
            return "multipart"
        }
    }

    private func encodeEncodable(_ value: Encodable) -> String {

        let encoder = JSONEncoder()

        /// 👉 保证顺序稳定（非常关键！）
        if #available(iOS 13.0, *) {
            encoder.outputFormatting = [.sortedKeys]
        }

        guard let data = try? encoder.encode(AnyEncodable(value)),
              let string = String(data: data, encoding: .utf8) else {
            return "invalid_json"
        }

        return string
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
        let url = try buildURL(from: endpoint)

        let request: DataRequest

        // ✅ 根据 RequestTask 构建请求
        switch endpoint.task {

        case .plain:

            request = session.request(
                url,
                method: endpoint.method,
                headers: buildHeaders(for: endpoint)
            )

        case .query(let items):

            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = items

            guard let finalURL = components?.url else {
                throw NetworkError.invalidURL
            }

            request = session.request(
                finalURL,
                method: endpoint.method,
                headers: buildHeaders(for: endpoint)
            )

        case .json(let body):

            request = session.request(
                url,
                method: endpoint.method,
                parameters: body,
                encoder: JSONParameterEncoder.default,
                headers: buildHeaders(for: endpoint)
            )

        case .form(let params):

            var headers = buildHeaders(for: endpoint) ?? [:]
            headers.add(name: "Content-Type", value: "application/x-www-form-urlencoded")

            request = session.request(
                url,
                method: endpoint.method,
                parameters: params,
                encoding: URLEncoding.httpBody,
                headers: headers
            )

        case .raw(let data, let contentType):

            var urlRequest = try URLRequest(
                url: url,
                method: endpoint.method,
                headers: buildHeaders(for: endpoint)
            )

            urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = data

            request = session.request(urlRequest)

        case .multipart(let builder):

            request = session.upload(
                multipartFormData: builder,
                to: url,
                method: endpoint.method,
                headers: buildHeaders(for: endpoint)
            )
        }

        let response = await request
            .serializingData()
            .response

        let statusCode = response.response?.statusCode

        switch response.result {

        case .success(let data):

            guard let code = statusCode else {
                throw NetworkError.emptyResponse
            }

            /// ✅ 成功
            if (200..<300).contains(code) {

                if endpoint.cachePolicy != .none {
                    HTTPCache.shared.save(data, key: key)
                }

                return try decoder(for: endpoint)
                    .decode(T.self, from: data)
            }

            /// ❗ 失败解析
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

    func buildURL(from endpoint: Endpoint) throws -> URL {

        guard var components = URLComponents(string: endpoint.baseURL) else {
            throw NetworkError.invalidURL
        }

        // 👉 baseURL 原始 path（保留）
        let basePath = components.path

        // 👉 endpoint path（清洗）
        let endpointPath = endpoint.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        // 👉 合并逻辑（关键）
        if endpointPath.isEmpty {
            // 保留 baseURL 原 path
            components.path = basePath.isEmpty ? "/" : basePath
        } else if basePath.isEmpty || basePath == "/" {
            components.path = "/" + endpointPath
        } else {
            // 防止重复拼接（例如 /v1 + /v1/login）
            if endpointPath.hasPrefix(basePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))) {
                components.path = "/" + endpointPath
            } else {
                components.path = basePath + "/" + endpointPath
            }
        }

        // 👉 最终兜底（防止空 path）
        if components.path.isEmpty {
            components.path = "/"
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        return url
    }

    private func buildHeaders(for endpoint: Endpoint) -> HTTPHeaders? {

        let common = config.commonHeaders ?? [:]
        let custom = endpoint.headers ?? [:]

        switch endpoint.headerStrategy {

        case .merge:
            var merged = common

            // endpoint 覆盖 common
            for header in custom {
                merged.update(name: header.name, value: header.value)
            }

            return merged

        case .replace:
            return endpoint.headers
        }
    }

    private func stringify(_ value: Any) -> String {
        switch value {
        case let v as String: return v
        case let v as Int: return String(v)
        case let v as Double: return String(v)
        case let v as Bool: return v ? "true" : "false"
        default: return "\(value)"
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
            headers: buildHeaders(for: endpoint)
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
