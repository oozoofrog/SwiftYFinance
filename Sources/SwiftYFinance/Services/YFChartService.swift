import Foundation

/// Yahoo Finance Chart API 서비스
///
/// Yahoo Finance Chart API(/v8/finance/chart)를 통해 과거 가격 데이터를 조회하는 기능을 제공합니다.
/// 기간별 조회와 날짜 범위 조회를 지원하며, 다양한 시간 간격으로 데이터를 가져올 수 있습니다.
/// Sendable 프로토콜을 준수하여 concurrent 환경에서 안전하게 사용할 수 있습니다.
/// Protocol + Struct 설계로 @unchecked 없이도 완전한 thread safety를 보장합니다.
public struct YFChartService: YFService {
    
    /// YFClient 참조
    public let client: YFClient
    
    
    /// 공통 로직을 처리하는 핵심 구조체
    private let core: YFServiceCore
    
    /// YFChartService 초기화
    /// - Parameter client: YFClient 인스턴스
    public init(client: YFClient) {
        self.client = client
        self.core = YFServiceCore(client: client)
    }
    
    /// 고해상도 가격 히스토리 데이터를 조회합니다.
    /// - Parameters:
    ///   - ticker: 조회할 주식 심볼
    ///   - period: 조회 기간
    ///   - interval: 시간 간격 (기본값: 1일)
    /// - Returns: 가격 히스토리 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetch(ticker: YFTicker, period: YFPeriod, interval: YFInterval = .oneDay) async throws -> YFHistoricalData {
        // 요청 URL 구성
        let requestURL = try await buildHistoryURL(ticker: ticker, period: period, interval: interval)
        
        // 공통 fetch 메서드 사용
        let chartResponse = try await performFetch(url: requestURL, type: ChartResponse.self, serviceName: "History")
        
        // 에러 응답 처리
        try handleYahooFinanceError(chartResponse.chart.error?.description)
        
        // 결과 데이터 처리
        guard let results = chartResponse.chart.result,
              let result = results.first else {
            return try YFHistoricalData(
                ticker: ticker,
                prices: [],
                startDate: client.dateHelper.dateFromPeriod(period),
                endDate: Date()
            )
        }
        
        // 가격 데이터 변환
        let prices = client.chartConverter.convertToPrices(result)
        
        return try YFHistoricalData(
            ticker: ticker,
            prices: prices,
            startDate: client.dateHelper.dateFromPeriod(period),
            endDate: Date()
        )
    }
    
    /// 기간 기반 가격 히스토리 데이터 조회 (기본 1일 간격)
    public func fetch(ticker: YFTicker, period: YFPeriod) async throws -> YFHistoricalData {
        return try await fetch(ticker: ticker, period: period, interval: .oneDay)
    }
    
    /// 날짜 범위 기반 가격 히스토리 데이터 조회
    public func fetch(ticker: YFTicker, from startDate: Date, to endDate: Date) async throws -> YFHistoricalData {
        // 요청 URL 구성
        let requestURL = try await buildHistoryURL(ticker: ticker, startDate: startDate, endDate: endDate)
        
        // 공통 fetch 메서드 사용
        let chartResponse = try await performFetch(url: requestURL, type: ChartResponse.self, serviceName: "History")
        
        // 에러 응답 처리
        try handleYahooFinanceError(chartResponse.chart.error?.description)
        
        // 결과 데이터 처리
        guard let results = chartResponse.chart.result,
              let result = results.first else {
            return try YFHistoricalData(
                ticker: ticker,
                prices: [],
                startDate: startDate,
                endDate: endDate
            )
        }
        
        // 가격 데이터 변환
        let prices = client.chartConverter.convertToPrices(result)
        
        return try YFHistoricalData(
            ticker: ticker,
            prices: prices,
            startDate: startDate,
            endDate: endDate
        )
    }
    
    /// 과거 가격 데이터 원본 JSON 조회 (기간 기반)
    ///
    /// Yahoo Finance API에서 반환하는 원본 JSON 응답을 그대로 반환합니다.
    ///
    /// - Parameters:
    ///   - ticker: 조회할 주식 심볼
    ///   - period: 조회 기간
    ///   - interval: 시간 간격 (기본값: 1일)
    /// - Returns: 원본 JSON 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchRawJSON(ticker: YFTicker, period: YFPeriod, interval: YFInterval = .oneDay) async throws -> Data {
        // 요청 URL 구성
        let requestURL = try await buildHistoryURL(ticker: ticker, period: period, interval: interval)
        
        // 공통 fetchRawJSON 메서드 사용
        return try await performFetchRawJSON(url: requestURL, serviceName: "History")
    }
    
    /// 과거 가격 데이터 원본 JSON 조회 (날짜 범위 기반)
    ///
    /// Yahoo Finance API에서 반환하는 원본 JSON 응답을 그대로 반환합니다.
    ///
    /// - Parameters:
    ///   - ticker: 조회할 주식 심볼
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    /// - Returns: 원본 JSON 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchRawJSON(ticker: YFTicker, from startDate: Date, to endDate: Date) async throws -> Data {
        // 요청 URL 구성
        let requestURL = try await buildHistoryURL(ticker: ticker, startDate: startDate, endDate: endDate)
        
        // 공통 fetchRawJSON 메서드 사용
        return try await performFetchRawJSON(url: requestURL, serviceName: "History")
    }
    
    /// History API 요청 URL을 구성합니다 (기간 기반)
    ///
    /// - Parameters:
    ///   - ticker: 조회할 주식 심볼
    ///   - period: 조회 기간
    ///   - interval: 시간 간격
    /// - Returns: 구성된 API 요청 URL
    /// - Throws: URL 구성 중 발생하는 에러
    private func buildHistoryURL(ticker: YFTicker, period: YFPeriod, interval: YFInterval) async throws -> URL {
        return try await YFAPIURLBuilder.chart(session: client.session)
            .symbol(ticker.symbol)
            .period(period)
            .interval(interval)
            .build()
    }
    
    /// History API 요청 URL을 구성합니다 (날짜 범위 기반)
    ///
    /// - Parameters:
    ///   - ticker: 조회할 주식 심볼
    ///   - startDate: 시작 날짜
    ///   - endDate: 종료 날짜
    /// - Returns: 구성된 API 요청 URL
    /// - Throws: URL 구성 중 발생하는 에러
    private func buildHistoryURL(ticker: YFTicker, startDate: Date, endDate: Date) async throws -> URL {
        return try await YFAPIURLBuilder.chart(session: client.session)
            .symbol(ticker.symbol)
            .dateRange(from: startDate, to: endDate)
            .interval(.oneDay)
            .build()
    }
}