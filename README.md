# NetCore SDK

NetCore 是一个 **Swift 网络 SDK**，基于 `Alamofire`，支持现代 iOS 开发模式（async/await、actor、Task、Swift Concurrency），提供：

- 高度可配置的 `HttpClient`
- 请求去重、合并（Coalescing）
- HTTP 缓存策略（cacheFirst, cacheOnly, networkElseCache）
- 上传 / 下载进度
- Token 自动刷新 & 登录失效处理
- Mock 数据支持
- 自定义 JSON Decoder 支持
- 可插拔 Interceptor / EventMonitor
- 离线队列支持（OfflineQueue，可扩展）

---

## 安装

使用 Swift Package Manager：

```swift
dependencies: [
    .package(url: "https://github.com/Girlkiller/NetCore.git", from: "1.0.0")
]
