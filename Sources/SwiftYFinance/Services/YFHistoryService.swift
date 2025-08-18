import Foundation

/// 과거 가격 데이터 조회 서비스
///
/// Yahoo Finance API를 통해 주식의 과거 가격 데이터를 조회하는 기능을 제공합니다.
/// 기간별 조회와 날짜 범위 조회를 지원하며, 다양한 시간 간격으로 데이터를 가져올 수 있습니다.
/// Sendable 프로토콜을 준수하여 concurrent 환경에서 안전하게 사용할 수 있습니다.
public final class YFHistoryService: YFBaseService, @unchecked Sendable {
    
    /// 고해상도 가격 히스토리 데이터를 조회합니다.
    /// - Parameters:
    ///   - ticker: 조회할 주식 심볼
    ///   - period: 조회 기간
    ///   - interval: 시간 간격 (기본값: 1일)
    /// - Returns: 가격 히스토리 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetch(ticker: YFTicker, period: YFPeriod, interval: YFInterval = .oneDay) async throws -> YFHistoricalData {
        let client = try validateClientReference()
        
        // CSRF 인증 시도 (공통 메서드 사용)
        await ensureCSRFAuthentication(client: client)
        
        // Yahoo Finance API 호출
        let requestURL = try await apiBuilder()
            .host(YFHosts.query2)
            .path(YFPaths.chart + "/\(ticker.symbol)")
            .parameter("interval", interval.stringValue)
            .parameter("range", client.dateHelper.periodToRangeString(period))
            .build()
        
        let (data, _) = try await authenticatedURLRequest(url: requestURL)
        
        // API 응답 디버깅 로그
        logAPIResponse(data, serviceName: "History")
        
        // JSON 파싱
        let chartResponse = try parseJSON(data: data, type: ChartResponse.self)
        
        // 에러 응답 처리 (공통 메서드 사용)
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
        let client = try validateClientReference()
        
        // CSRF 인증 시도 (공통 메서드 사용)
        await ensureCSRFAuthentication(client: client)
        
        // Yahoo Finance API 호출
        let startTimestamp = Int(startDate.timeIntervalSince1970)
        let endTimestamp = Int(endDate.timeIntervalSince1970)
        
        let requestURL = try await apiBuilder()
            .host(YFHosts.query2)
            .path(YFPaths.chart + "/\(ticker.symbol)")
            .parameter("period1", String(startTimestamp))
            .parameter("period2", String(endTimestamp))
            .parameter("interval", "1d")
            .build()
        
        let (data, _) = try await authenticatedURLRequest(url: requestURL)
        
        // API 응답 디버깅 로그
        logAPIResponse(data, serviceName: "History")
        
        // JSON 파싱
        let chartResponse = try parseJSON(data: data, type: ChartResponse.self)
        
        // 에러 응답 처리 (공통 메서드 사용)
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
}