import Foundation

/// Yahoo Finance 종목 스크리닝 서비스
///
/// Protocol + Struct 아키텍처를 따르는 스크리닝 전용 서비스입니다.
/// YFServiceCore를 통한 composition 패턴을 사용하여 공통 기능을 활용합니다.
/// Sendable 프로토콜을 준수하여 완전한 thread-safety를 보장합니다.
public struct YFScreeningService: YFService {
    
    /// YFClient 참조
    public let client: YFClient
    
    /// 공통 기능을 제공하는 서비스 코어
    private let core: YFServiceCore
    
    /// YFScreeningService 초기화
    /// - Parameter client: YFClient 인스턴스
    public init(client: YFClient) {
        self.client = client
        self.core = YFServiceCore(client: client)
    }
    
    // MARK: - Public Methods
    
    /// Raw JSON 사전 정의 스크리너 데이터 조회
    ///
    /// CLI나 raw 데이터가 필요한 경우 사용합니다.
    ///
    /// - Parameters:
    ///   - predefined: 사전 정의된 스크리너 유형
    ///   - limit: 결과 개수 제한 (기본값: 25, 최대 250)
    /// - Returns: Raw JSON 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchRawJSON(predefined: YFPredefinedScreener, limit: Int = 25) async throws -> Data {
        let url = try await buildPredefinedScreenerURL(for: predefined, limit: limit)
        return try await performFetchRawJSON(url: url, serviceName: "Screening")
    }
    
    /// 사전 정의된 스크리너로 종목 검색
    ///
    /// Yahoo Finance에서 제공하는 인기 스크리너를 사용합니다.
    ///
    /// - Parameters:
    ///   - predefined: 사전 정의된 스크리너 유형
    ///   - limit: 결과 개수 제한 (기본값: 25)
    /// - Returns: 검색 결과 배열
    /// - Throws: `YFError.invalidRequest` 등 API 오류
    public func screenPredefined(_ predefined: YFPredefinedScreener, limit: Int = 25) async throws -> [YFScreenResult] {
        let actualLimit = min(limit, 250) // Yahoo 제한
        return try await fetchPredefinedResults(for: predefined, limit: actualLimit)
    }
    
    // MARK: - Private Helper Methods
    
    /// 실제 Yahoo Finance 사전 정의된 스크리너 API 호출
    private func fetchPredefinedResults(for predefined: YFPredefinedScreener, limit: Int) async throws -> [YFScreenResult] {
        // 사전 정의된 스크리너 API 요청 수행
        let url = try await buildPredefinedScreenerURL(for: predefined, limit: limit)
        let screenerResponse = try await performFetch(url: url, type: YFScreenerResponse.self, serviceName: "Screening")
        
        // 직접 YFScreenResult 반환
        let results = screenerResponse.finance?.result?.compactMap { result in
            result.quotes
        }.flatMap { $0 } ?? []
        
        return Array(results.prefix(limit))
    }
    
    /// 사전 정의된 스크리너 URL 구성 헬퍼  
    private func buildPredefinedScreenerURL(for predefined: YFPredefinedScreener, limit: Int) async throws -> URL {
        let screenerType = getPredefinedScreenerType(predefined)
        
        return try await core.apiBuilder()
            .host(YFHosts.query1)
            .path("/v1/finance/screener/predefined/saved")
            .parameter("scrIds", screenerType)
            .parameter("count", String(limit))
            .parameter("lang", "en-US")
            .parameter("region", "US")
            .parameter("formatted", "false")
            .parameter("corsDomain", "finance.yahoo.com")
            .build()
    }
    
    /// 사전 정의된 스크리너 타입 매핑
    private func getPredefinedScreenerType(_ predefined: YFPredefinedScreener) -> String {
        switch predefined {
        case .dayGainers:
            return "day_gainers"
        case .dayLosers:
            return "day_losers" 
        case .mostActives:
            return "most_actives"
        case .aggressiveSmallCaps:
            return "aggressive_small_caps"
        case .growthTechnologyStocks:
            return "growth_technology_stocks"
        case .undervaluedGrowthStocks:
            return "undervalued_growth_stocks"
        case .undervaluedLargeCaps:
            return "undervalued_large_caps"
        case .smallCapGainers:
            return "small_cap_gainers"
        case .mostShortedStocks:
            return "most_shorted_stocks"
        }
    }
    
}