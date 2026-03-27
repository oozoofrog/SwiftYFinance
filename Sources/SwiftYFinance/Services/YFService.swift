import Foundation

/// 모든 Yahoo Finance 서비스의 공통 인터페이스
///
/// 내부 구현 책임은 `YFRequestPipeline`으로 분산됩니다.
/// Sendable 프로토콜을 준수하여 concurrent 환경에서 안전하게 사용할 수 있습니다.
///
/// ## Swift 6.2 Concurrency 설계
/// 이 프로토콜을 준수하는 모든 struct는 `nonisolated`로 선언됩니다.
/// `nonisolated struct`는 Sendable을 자동으로 충족하며,
/// 라이브러리 소비자의 어떤 actor isolation 컨텍스트에서도 안전하게 사용 가능합니다.
/// 프로토콜 자체에는 nonisolated를 적용하지 않으며, 채택 타입 수준에서 명시합니다.
public protocol YFService: Sendable {
    /// YFClient 참조
    var client: YFClient { get }
}

/// YFService의 기본 구현 확장
///
/// 공통 편의 메서드만 제공하며, 실제 구현은 YFRequestPipeline에 위임합니다.
public extension YFService {

    /// Yahoo Finance API 응답에서 공통 에러를 처리합니다
    func handleYahooFinanceError(_ errorDescription: String?) throws {
        if let error = errorDescription { throw YFError.apiError(error) }
    }

    /// 인증된 GET API 호출 및 JSON 파싱
    func performFetch<T: Decodable>(url: URL, type: T.Type, serviceName: String) async throws -> T {
        try await YFRequestPipeline(client: client).fetch(url: url, type: type, serviceName: serviceName)
    }

    /// 인증된 GET API 호출 (Raw JSON 반환)
    func performFetchRawJSON(url: URL, serviceName: String) async throws -> Data {
        try await YFRequestPipeline(client: client).fetchRawJSON(url: url, serviceName: serviceName)
    }

    /// 공개 GET API 호출 및 JSON 파싱 (인증 불필요)
    func performPublicFetch<T: Decodable>(url: URL, type: T.Type, serviceName: String) async throws -> T {
        try await YFRequestPipeline(client: client).fetchPublic(url: url, type: type, serviceName: serviceName)
    }

    /// 공개 GET API 호출 (Raw JSON 반환, 인증 불필요)
    func performPublicFetchRawJSON(url: URL, serviceName: String) async throws -> Data {
        try await YFRequestPipeline(client: client).fetchPublicRawJSON(url: url, serviceName: serviceName)
    }

    /// 인증된 POST API 호출 및 JSON 파싱
    func performPostFetch<T: Decodable>(url: URL, requestBody: Data, type: T.Type, serviceName: String) async throws -> T {
        try await YFRequestPipeline(client: client).post(url: url, requestBody: requestBody, type: type, serviceName: serviceName)
    }

    /// 인증된 POST API 호출 (Raw JSON 반환)
    func performPostFetchRawJSON(url: URL, requestBody: Data, serviceName: String) async throws -> Data {
        try await YFRequestPipeline(client: client).postRawJSON(url: url, requestBody: requestBody, serviceName: serviceName)
    }
}
