import Foundation

/// 네트워크 요청 추상화 프로토콜
///
/// URLSession 의존성을 추상화하여 테스트에서 Mock 구현체를 주입할 수 있도록 합니다.
/// YFSession이 이 프로토콜을 통해 HTTP 요청을 수행하므로, 단위 테스트에서
/// 실제 네트워크 연결 없이 가짜 응답을 주입할 수 있습니다.
///
/// ## 구현 예시 (테스트)
/// ```swift
/// struct MockNetworkProvider: YFNetworkProvider {
///     func data(for request: URLRequest) async throws -> (Data, URLResponse) {
///         let json = """{"result": [{"symbol": "AAPL"}]}"""
///         let data = json.data(using: .utf8)!
///         let response = HTTPURLResponse(url: request.url!, statusCode: 200, ...)!
///         return (data, response)
///     }
/// }
///
/// let session = YFSession(networkProvider: MockNetworkProvider())
/// ```
public protocol YFNetworkProvider: Sendable {

    /// HTTP 요청을 수행하고 응답 데이터와 URLResponse를 반환합니다.
    ///
    /// - Parameter request: 실행할 URLRequest
    /// - Returns: 응답 데이터와 URLResponse 튜플
    /// - Throws: 네트워크 오류 발생 시
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// MARK: - URLSession conformance

/// URLSession을 YFNetworkProvider로 사용하기 위한 기본 구현
extension URLSession: YFNetworkProvider {}
