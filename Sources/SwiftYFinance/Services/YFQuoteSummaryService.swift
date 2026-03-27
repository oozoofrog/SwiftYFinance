import Foundation

/// Yahoo Finance Quote Summary API를 위한 서비스 구조체
///
/// Quote Summary API는 Yahoo Finance의 가장 종합적인 데이터 소스로,
/// 60개의 모듈을 통해 기업의 모든 정보를 제공합니다.
/// 기본 Quote API와 달리 상세한 재무제표, 분석 데이터, ESG 점수 등을 포함합니다.
/// Sendable 프로토콜을 준수하여 concurrent 환경에서 안전하게 사용할 수 있습니다.
/// Protocol + Struct 설계로 @unchecked 없이도 완전한 thread safety를 보장합니다.
/// nonisolated: 순수 데이터 서비스 — actor isolation 불필요, 라이브러리 소비자의 모든 컨텍스트에서 안전
public nonisolated struct YFQuoteSummaryService: YFService {
    
    /// YFClient 참조
    public let client: YFClient

    /// YFQuoteSummaryService 초기화
    /// - Parameter client: YFClient 인스턴스
    public init(client: YFClient) {
        self.client = client
    }
    
    // MARK: - Custom Module Fetch Methods
    
    /// 사용자 지정 모듈로 Quote Summary 데이터 조회
    ///
    /// 원하는 모듈만 선택적으로 조회하여 네트워크 사용량과 응답 시간을 최적화할 수 있습니다.
    ///
    /// - Parameters:
    ///   - ticker: 조회할 주식 심볼
    ///   - modules: 조회할 모듈 배열
    /// - Returns: Quote Summary 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetch(ticker: YFTicker, modules: [YFQuoteSummaryModule]) async throws -> YFQuoteSummary {
        let requestURL = try await buildQuoteSummaryURL(ticker: ticker, modules: modules)
        let response = try await performFetch(url: requestURL, type: YFQuoteSummaryResponse.self, serviceName: "QuoteSummary")

        guard let quoteSummary = response.quoteSummary else {
            throw YFError.invalidResponse
        }

        return quoteSummary
    }
    
    /// 단일 모듈로 Quote Summary 데이터 조회
    ///
    /// 특정 모듈 하나만 조회하는 편의 메서드입니다.
    ///
    /// - Parameters:
    ///   - ticker: 조회할 주식 심볼
    ///   - module: 조회할 단일 모듈
    /// - Returns: Quote Summary 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetch(ticker: YFTicker, module: YFQuoteSummaryModule) async throws -> YFQuoteSummary {
        return try await fetch(ticker: ticker, modules: [module])
    }
    
    // MARK: - Convenience Fetch Methods
    
    /// 필수 정보 모듈들로 조회
    ///
    /// 가장 자주 사용되는 기본 정보를 조회합니다.
    /// 포함 모듈: summaryDetail, financialData, defaultKeyStatistics, price, quoteType
    ///
    /// - Parameter ticker: 조회할 주식 심볼
    /// - Returns: Quote Summary 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchEssential(ticker: YFTicker) async throws -> YFQuoteSummary {
        return try await fetch(ticker: ticker, modules: YFQuoteSummaryModule.essential)
    }
    
    /// 종합 분석용 데이터 조회
    ///
    /// 상당한 양의 데이터를 포함한 종합 분석용 정보를 조회합니다.
    /// 필수 정보 + 회사 정보 + 연간 재무제표 + 실적 데이터 포함
    ///
    /// - Parameter ticker: 조회할 주식 심볼
    /// - Returns: Quote Summary 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchComprehensive(ticker: YFTicker) async throws -> YFQuoteSummary {
        return try await fetch(ticker: ticker, modules: YFQuoteSummaryModule.comprehensive)
    }
    
    /// 회사 기본 정보 조회
    ///
    /// 회사 프로필과 요약 정보를 조회합니다.
    /// 포함 모듈: summaryProfile, assetProfile, summaryDetail
    ///
    /// - Parameter ticker: 조회할 주식 심볼
    /// - Returns: Quote Summary 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchCompanyInfo(ticker: YFTicker) async throws -> YFQuoteSummary {
        return try await fetch(ticker: ticker, modules: YFQuoteSummaryModule.companyInfo)
    }
    
    /// 가격 및 시장 정보 조회
    ///
    /// 실시간 가격과 시장 관련 정보를 조회합니다.
    /// 포함 모듈: price, quoteType, summaryDetail
    ///
    /// - Parameter ticker: 조회할 주식 심볼
    /// - Returns: Quote Summary 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchPriceInfo(ticker: YFTicker) async throws -> YFQuoteSummary {
        return try await fetch(ticker: ticker, modules: YFQuoteSummaryModule.priceInfo)
    }
    
    /// 재무제표 데이터 조회
    ///
    /// 손익계산서, 대차대조표, 현금흐름표를 조회합니다.
    ///
    /// - Parameters:
    ///   - ticker: 조회할 주식 심볼
    ///   - quarterly: 분기별 데이터 포함 여부 (기본값: false, 연간만)
    /// - Returns: Quote Summary 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchFinancials(ticker: YFTicker, quarterly: Bool = false) async throws -> YFQuoteSummary {
        let modules = quarterly ? YFQuoteSummaryModule.allFinancials : YFQuoteSummaryModule.annualFinancials
        return try await fetch(ticker: ticker, modules: modules)
    }
    
    /// 실적 관련 데이터 조회
    ///
    /// 과거 실적, 실적 트렌드, 향후 실적 발표일 등을 조회합니다.
    /// 포함 모듈: earnings, earningsHistory, earningsTrend, calendarEvents
    ///
    /// - Parameter ticker: 조회할 주식 심볼
    /// - Returns: Quote Summary 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchEarnings(ticker: YFTicker) async throws -> YFQuoteSummary {
        return try await fetch(ticker: ticker, modules: YFQuoteSummaryModule.earningsData)
    }
    
    /// 소유권 관련 데이터 조회
    ///
    /// 기관투자자, 펀드, 임원 지분 현황을 조회합니다.
    /// 포함 모듈: 기관/펀드 소유권, 주요 보유자, 임원 거래 내역 등
    ///
    /// - Parameter ticker: 조회할 주식 심볼
    /// - Returns: Quote Summary 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchOwnership(ticker: YFTicker) async throws -> YFQuoteSummary {
        return try await fetch(ticker: ticker, modules: YFQuoteSummaryModule.ownershipData)
    }
    
    /// 애널리스트 분석 데이터 조회
    ///
    /// 애널리스트 추천, 업그레이드/다운그레이드 이력을 조회합니다.
    /// 포함 모듈: upgradeDowngradeHistory, recommendationTrend
    ///
    /// - Parameter ticker: 조회할 주식 심볼
    /// - Returns: Quote Summary 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchAnalystData(ticker: YFTicker) async throws -> YFQuoteSummary {
        return try await fetch(ticker: ticker, modules: YFQuoteSummaryModule.analystData)
    }
    
    // MARK: - Raw JSON Methods
    
    /// Quote Summary 원본 JSON 조회 (사용자 지정 모듈)
    ///
    /// Yahoo Finance API에서 반환하는 원본 JSON 응답을 그대로 반환합니다.
    ///
    /// - Parameters:
    ///   - ticker: 조회할 주식 심볼
    ///   - modules: 조회할 모듈 배열
    /// - Returns: 원본 JSON 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchRawJSON(ticker: YFTicker, modules: [YFQuoteSummaryModule]) async throws -> Data {
        let requestURL = try await buildQuoteSummaryURL(ticker: ticker, modules: modules)
        return try await performFetchRawJSON(url: requestURL, serviceName: "QuoteSummary")
    }
    
    /// Quote Summary 원본 JSON 조회 (필수 정보)
    ///
    /// 필수 정보 모듈들의 원본 JSON을 반환합니다.
    ///
    /// - Parameter ticker: 조회할 주식 심볼
    /// - Returns: 원본 JSON 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchEssentialRawJSON(ticker: YFTicker) async throws -> Data {
        return try await fetchRawJSON(ticker: ticker, modules: YFQuoteSummaryModule.essential)
    }
    
    /// Quote Summary 원본 JSON 조회 (종합 정보)
    ///
    /// 종합 분석용 모듈들의 원본 JSON을 반환합니다.
    ///
    /// - Parameter ticker: 조회할 주식 심볼
    /// - Returns: 원본 JSON 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchComprehensiveRawJSON(ticker: YFTicker) async throws -> Data {
        return try await fetchRawJSON(ticker: ticker, modules: YFQuoteSummaryModule.comprehensive)
    }
    
    // MARK: - Private Helper Methods
    
    /// Quote Summary API 요청 URL을 구성합니다
    ///
    /// - Parameters:
    ///   - ticker: 조회할 주식 심볼
    ///   - modules: 조회할 모듈 배열
    /// - Returns: 구성된 API 요청 URL
    /// - Throws: URL 구성 중 발생하는 에러
    private func buildQuoteSummaryURL(ticker: YFTicker, modules: [YFQuoteSummaryModule]) async throws -> URL {
        return try await YFAPIURLBuilder.quoteSummary(session: client.session)
            .symbol(ticker.symbol)
            .modules(modules)
            .build()
    }
}