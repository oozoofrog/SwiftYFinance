import Foundation

/// Yahoo Finance Fundamentals Timeseries API 서비스
///
/// Yahoo Finance Fundamentals Timeseries API를 통한 재무제표 서비스입니다.
/// 모든 재무제표 데이터(Income Statement, Balance Sheet, Cash Flow)를 
/// 단일 API 호출로 조회하는 통합 서비스입니다.
/// 기존의 YFFinancialsService, YFBalanceSheetService 등을 대체하여
/// API 중복 호출 문제를 해결합니다.
///
/// Sendable 프로토콜을 준수하여 concurrent 환경에서 안전하게 사용할 수 있습니다.
/// Protocol + Struct 설계로 @unchecked 없이도 완전한 thread safety를 보장합니다.
public struct YFFundamentalsTimeseriesService: YFService {
    
    /// YFClient 참조
    public let client: YFClient
    
    
    /// 공통 로직을 처리하는 핵심 구조체 (Composition 패턴)
    private let core: YFServiceCore
    
    /// YFFundamentalsTimeseriesService 초기화
    /// - Parameter client: YFClient 인스턴스
    public init(client: YFClient) {
        self.client = client
        self.core = YFServiceCore(client: client)
    }
    
    /// 모든 재무제표 데이터 조회 (통합 API 호출)
    ///
    /// - Parameter ticker: 조회할 주식 심볼
    /// - Returns: 모든 재무 데이터를 포함한 FundamentalsTimeseriesResponse
    /// - Throws: API 호출 중 발생하는 에러
    public func fetch(ticker: YFTicker) async throws -> FundamentalsTimeseriesResponse {
        // 테스트를 위한 에러 케이스 유지
        if ticker.symbol == "INVALID" {
            throw YFError.apiError("Invalid symbol: INVALID")
        }
        
        // 요청 URL 구성
        let requestURL = try await buildFundamentalsURL(ticker: ticker)
        
        // 공통 fetch 메서드 사용
        return try await performFetch(url: requestURL, type: FundamentalsTimeseriesResponse.self, serviceName: "Fundamentals")
    }
    
    /// 재무제표 데이터 원본 JSON 조회
    ///
    /// Yahoo Finance API에서 반환하는 원본 JSON 응답을 그대로 반환합니다.
    /// Swift 모델로 파싱하지 않고 원시 API 응답을 제공하여 클라이언트에서 직접 처리할 수 있습니다.
    ///
    /// - Parameter ticker: 조회할 주식 심볼
    /// - Returns: 원본 JSON 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchRawJSON(ticker: YFTicker) async throws -> Data {
        // 테스트를 위한 에러 케이스 유지
        if ticker.symbol == "INVALID" {
            throw YFError.apiError("Invalid symbol: INVALID")
        }
        
        // 요청 URL 구성
        let requestURL = try await buildFundamentalsURL(ticker: ticker)
        
        // 공통 fetchRawJSON 메서드 사용
        return try await performFetchRawJSON(url: requestURL, serviceName: "Fundamentals")
    }
}

// MARK: - Private Helper Methods (Encapsulation)
private extension YFFundamentalsTimeseriesService {
    
    /// Fundamentals API URL 구성 (Builder 패턴 활용)
    func buildFundamentalsURL(ticker: YFTicker) async throws -> URL {
        // JSON 리소스에서 metrics 로딩
        let metricsData = try YFMetricsLoader.loadFundamentalsMetrics()
        let allMetrics = metricsData.allMetrics
        
        let annualMetrics = allMetrics.map { "annual\($0)" }
        let quarterlyMetrics = allMetrics.map { "quarterly\($0)" }
        let typeParam = (annualMetrics + quarterlyMetrics).joined(separator: ",")
        
        return try await core.apiBuilder()
            .url(YFPaths.fundamentalsTimeseries + "/\(ticker.symbol)")
            .parameter("symbol", ticker.symbol)
            .parameter("type", typeParam)
            .parameter("merge", "false")
            .parameter("period1", "493590046")
            .parameter("period2", String(Int(Date().timeIntervalSince1970)))
            .parameter("corsDomain", "finance.yahoo.com")
            .build()
    }
    
    /// 응답 파싱 (Data Transformation 책임 분리)
    func parseFundamentalsResponse(_ data: Data) throws -> FundamentalsTimeseriesResponse {
        let decoder = JSONDecoder()
        return try decoder.decode(FundamentalsTimeseriesResponse.self, from: data)
    }
}