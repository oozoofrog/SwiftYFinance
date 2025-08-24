import Foundation

/// Yahoo Finance Custom Screener API 서비스
///
/// Yahoo Finance Custom Screener API를 통한 맞춤형 종목 스크리닝 서비스입니다.
/// Protocol + Struct 아키텍처를 따르는 Custom Screener API 전용 서비스입니다.
/// YFServiceCore를 통한 composition 패턴을 사용하여 공통 기능을 활용합니다.
/// Sendable 프로토콜을 준수하여 완전한 thread-safety를 보장합니다.
public struct YFCustomScreenerService: YFService {
    
    /// YFClient 참조
    public let client: YFClient
    
    /// 공통 기능을 제공하는 서비스 코어
    private let core: YFServiceCore
    
    /// YFCustomScreenerService 초기화
    /// - Parameter client: YFClient 인스턴스
    public init(client: YFClient) {
        self.client = client
        self.core = YFServiceCore(client: client)
    }
    
    // MARK: - Public Methods
    
    /// Raw JSON 맞춤형 스크리너 데이터 조회
    ///
    /// CLI나 raw 데이터가 필요한 경우 사용합니다.
    ///
    /// - Parameters:
    ///   - query: 스크리닝 쿼리
    ///   - limit: 결과 개수 제한 (기본값: 25)
    /// - Returns: Raw JSON 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchRawJSON(query: YFScreenerQuery, limit: Int = 25) async throws -> Data {
        let builder = try await buildCustomScreenerBuilder(query: query, limit: limit)
        return try await performCustomScreenerRawJSON(builder: builder)
    }
    
    /// 시가총액 기준 맞춤형 스크리닝
    ///
    /// 지정된 시가총액 범위 내의 종목들을 검색합니다.
    ///
    /// - Parameters:
    ///   - minMarketCap: 최소 시가총액 (단위: 억원, 기본값: 1000억)
    ///   - maxMarketCap: 최대 시가총액 (단위: 억원, 기본값: 10조)
    ///   - limit: 결과 개수 제한 (기본값: 25)
    /// - Returns: 검색 결과 배열
    /// - Throws: `YFError.invalidRequest` 등 API 오류
    public func screenByMarketCap(
        minMarketCap: Double = 100_000_000_000, // 1000억
        maxMarketCap: Double = 10_000_000_000_000, // 10조
        limit: Int = 25
    ) async throws -> [YFCustomScreenerResult] {
        let query = YFScreenerQuery.marketCapRange(min: minMarketCap, max: maxMarketCap)
        return try await performCustomScreening(query: query, limit: limit)
    }
    
    /// P/E 비율 기준 맞춤형 스크리닝
    ///
    /// 지정된 P/E 비율 범위 내의 종목들을 검색합니다.
    ///
    /// - Parameters:
    ///   - minPE: 최소 P/E 비율 (기본값: 5)
    ///   - maxPE: 최대 P/E 비율 (기본값: 25)
    ///   - limit: 결과 개수 제한 (기본값: 25)
    /// - Returns: 검색 결과 배열
    /// - Throws: `YFError.invalidRequest` 등 API 오류
    public func screenByPERatio(
        minPE: Double = 5,
        maxPE: Double = 25,
        limit: Int = 25
    ) async throws -> [YFCustomScreenerResult] {
        let query = YFScreenerQuery.peRatioRange(min: minPE, max: maxPE)
        return try await performCustomScreening(query: query, limit: limit)
    }
    
    /// 수익률 기준 맞춤형 스크리닝
    ///
    /// 지정된 수익률 범위 내의 종목들을 검색합니다.
    ///
    /// - Parameters:
    ///   - minReturn: 최소 수익률 (%, 기본값: -10)
    ///   - maxReturn: 최대 수익률 (%, 기본값: 50)
    ///   - limit: 결과 개수 제한 (기본값: 25)
    /// - Returns: 검색 결과 배열
    /// - Throws: `YFError.invalidRequest` 등 API 오류
    public func screenByReturn(
        minReturn: Double = -10,
        maxReturn: Double = 50,
        limit: Int = 25
    ) async throws -> [YFCustomScreenerResult] {
        let query = YFScreenerQuery.returnRange(min: minReturn, max: maxReturn)
        return try await performCustomScreening(query: query, limit: limit)
    }
    
    /// 복합 조건 맞춤형 스크리닝
    ///
    /// 여러 조건을 조합한 복합 스크리닝을 수행합니다.
    ///
    /// - Parameters:
    ///   - conditions: 스크리닝 조건 배열
    ///   - limit: 결과 개수 제한 (기본값: 25)
    /// - Returns: 검색 결과 배열
    /// - Throws: `YFError.invalidRequest` 등 API 오류
    public func screenWithConditions(
        _ conditions: [YFScreenerCondition],
        limit: Int = 25
    ) async throws -> [YFCustomScreenerResult] {
        let query = YFScreenerQuery.multipleConditions(conditions)
        return try await performCustomScreening(query: query, limit: limit)
    }
    
    // MARK: - Private Helper Methods
    
    /// 실제 Yahoo Finance Custom Screener API 호출
    private func performCustomScreening(query: YFScreenerQuery, limit: Int) async throws -> [YFCustomScreenerResult] {
        let builder = try await buildCustomScreenerBuilder(query: query, limit: limit)
        let screenerResponse = try await performCustomScreenerRequest(builder: builder, type: YFCustomScreenerResponse.self)
        
        // 커스텀 스크리너 응답에서 결과 추출
        return screenerResponse.finance?.result?.compactMap { result in
            result.quotes
        }.flatMap { $0 } ?? []
    }
    
    /// 커스텀 스크리너 빌더 생성
    private func buildCustomScreenerBuilder(query: YFScreenerQuery, limit: Int) async throws -> YFAPIURLBuilder.CustomScreenerBuilder {
        return YFAPIURLBuilder.customScreener(session: client.session)
            .query(query)
            .count(limit)
            .parameter("formatted", false)
            .parameter("corsDomain", "finance.yahoo.com")
    }
    
    /// 커스텀 스크리너 Raw JSON 요청
    private func performCustomScreenerRawJSON(builder: YFAPIURLBuilder.CustomScreenerBuilder) async throws -> Data {
        let url = try await builder.build()
        let requestBody = try builder.getRequestBody()
        
        // YFService 공통 POST 메서드 사용 (인증 필요)
        return try await performPostFetchRawJSON(url: url, requestBody: requestBody, serviceName: "Custom Screener")
    }
    
    /// 커스텀 스크리너 타입 요청
    private func performCustomScreenerRequest<T: Decodable>(
        builder: YFAPIURLBuilder.CustomScreenerBuilder,
        type: T.Type
    ) async throws -> T {
        let url = try await builder.build()
        let requestBody = try builder.getRequestBody()
        
        // YFService 공통 POST 메서드 사용 (인증 필요)
        return try await performPostFetch(url: url, requestBody: requestBody, type: type, serviceName: "Custom Screener")
    }
    
}