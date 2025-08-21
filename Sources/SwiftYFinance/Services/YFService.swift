import Foundation

/// 모든 Yahoo Finance 서비스의 공통 인터페이스
///
/// Protocol-oriented programming과 Swift Concurrency를 위한 설계입니다.
/// 모든 서비스 구현체는 이 프로토콜을 준수하여 일관된 인터페이스를 제공합니다.
/// Sendable 프로토콜을 준수하여 concurrent 환경에서 안전하게 사용할 수 있습니다.
public protocol YFService: Sendable {
    /// YFClient 참조
    var client: YFClient { get }
    
    /// 디버깅 모드 활성화 여부
    var debugEnabled: Bool { get }
}

/// YFService의 기본 구현을 제공하는 확장
///
/// Protocol default implementation을 통해 공통 기능을 제공합니다.
/// 모든 서비스에서 일관된 동작을 보장하며 코드 중복을 제거합니다.
public extension YFService {
    
    /// 클라이언트 참조가 유효한지 확인하고 반환합니다
    ///
    /// 서비스 메서드 시작 시 클라이언트 참조 유효성을 검증합니다.
    /// 각 서비스에서 guard문 중복을 제거할 수 있습니다.
    ///
    /// - Returns: 검증된 YFClient 인스턴스
    /// - Throws: 클라이언트 참조가 유효하지 않은 경우 YFError.apiError
    func validateClient() throws -> YFClient {
        return client // struct이므로 항상 valid
    }
    
    /// API 응답을 디버깅 로그로 출력합니다
    ///
    /// 디버깅 모드가 활성화된 경우에만 로그를 출력합니다.
    /// 모든 서비스에서 일관된 로깅 포맷을 사용합니다.
    ///
    /// - Parameters:
    ///   - data: 응답 데이터
    ///   - serviceName: 서비스 이름 (로그 식별용)
    func logAPIResponse(_ data: Data, serviceName: String) {
        guard debugEnabled else { return }
        
        print("📋 [DEBUG] \(serviceName) API 응답 데이터 크기: \(data.count) bytes")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📋 [DEBUG] \(serviceName) API 응답 내용 (처음 500자): \(responseString.prefix(500))")
        } else {
            print("❌ [DEBUG] \(serviceName) API 응답을 UTF-8로 디코딩 실패")
        }
    }
    
    /// CSRF 인증을 시도합니다
    ///
    /// Yahoo Finance API 요청 시 필요한 CSRF 인증을 처리합니다.
    /// 인증이 실패해도 에러를 던지지 않고 기본 요청으로 진행할 수 있도록 합니다.
    func ensureCSRFAuthentication() async {
        let isAuthenticated = await client.session.isCSRFAuthenticated
        if !isAuthenticated {
            try? await client.session.authenticateCSRF()
        }
    }
    
    /// Yahoo Finance API 응답에서 공통 에러를 처리합니다
    ///
    /// Yahoo Finance API 응답에 포함된 에러 정보를 확인하고 적절한 예외를 던집니다.
    /// 모든 서비스에서 일관된 에러 처리를 보장합니다.
    ///
    /// - Parameter errorDescription: API 응답의 에러 설명
    /// - Throws: 에러가 있는 경우 YFError.apiError
    func handleYahooFinanceError(_ errorDescription: String?) throws {
        if let error = errorDescription {
            throw YFError.apiError(error)
        }
    }
    
    /// 공통 API 호출 및 JSON 파싱을 수행합니다
    ///
    /// 모든 서비스에서 사용하는 표준화된 API 호출 패턴을 제공합니다.
    /// CSRF 인증, URL 요청, 응답 로깅, JSON 파싱을 일괄 처리합니다.
    ///
    /// - Parameters:
    ///   - url: API 요청 URL
    ///   - type: 디코딩할 타입
    ///   - serviceName: 로깅용 서비스 이름
    /// - Returns: 파싱된 객체
    /// - Throws: API 호출 또는 파싱 중 발생하는 에러
    func performFetch<T: Decodable>(url: URL, type: T.Type, serviceName: String) async throws -> T {
        // CSRF 인증 시도
        await ensureCSRFAuthentication()
        
        // 인증된 요청 수행
        let core = YFServiceCore(client: client, debugEnabled: debugEnabled)
        let (data, _) = try await core.authenticatedURLRequest(url: url)
        
        // API 응답 디버깅 로그
        logAPIResponse(data, serviceName: serviceName)
        
        // JSON 파싱
        return try core.parseJSON(data: data, type: type)
    }
    
    /// 공통 API 호출을 수행하고 원본 JSON 데이터를 반환합니다
    ///
    /// Yahoo Finance API에서 반환하는 원본 JSON 응답을 그대로 반환합니다.
    /// Swift 모델로 파싱하지 않고 원시 API 응답을 제공하여 클라이언트에서 직접 처리할 수 있습니다.
    ///
    /// - Parameters:
    ///   - url: API 요청 URL
    ///   - serviceName: 로깅용 서비스 이름
    /// - Returns: 원본 JSON 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    func performFetchRawJSON(url: URL, serviceName: String) async throws -> Data {
        // CSRF 인증 시도
        await ensureCSRFAuthentication()
        
        // 인증된 요청 수행
        let core = YFServiceCore(client: client, debugEnabled: debugEnabled)
        let (data, _) = try await core.authenticatedURLRequest(url: url)
        
        // API 응답 디버깅 로그
        logAPIResponse(data, serviceName: "\(serviceName) (Raw JSON)")
        
        return data
    }
}