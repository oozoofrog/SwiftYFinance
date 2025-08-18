import Foundation

/// 과거 가격 데이터 조회 서비스
///
/// Yahoo Finance API를 통해 주식의 과거 가격 데이터를 조회하는 기능을 제공합니다.
/// 기간별 조회와 날짜 범위 조회를 지원하며, 다양한 시간 간격으로 데이터를 가져올 수 있습니다.
public final class YFHistoryService: YFBaseService {
    
    /// 고해상도 가격 히스토리 데이터를 조회합니다.
    /// - Parameters:
    ///   - ticker: 조회할 주식 심볼
    ///   - period: 조회 기간
    ///   - interval: 시간 간격 (기본값: 1일)
    /// - Returns: 가격 히스토리 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetch(ticker: YFTicker, period: YFPeriod, interval: YFInterval = .oneDay) async throws -> YFHistoricalData {
        try validateClientReference()
        guard let client = client else { fatalError("Client validated but is nil") }
        
        // Yahoo Finance API 호출
        let request = try client.requestBuilder
            .path("/v8/finance/chart/\(ticker.symbol)")
            .queryParam("interval", interval.stringValue)
            .queryParam("range", client.dateHelper.periodToRangeString(period))
            .build()
        
        let (data, _) = try await authenticatedURLRequest(url: request.url!)
        
        // JSON 파싱
        let chartResponse = try parseJSON(data: data, type: ChartResponse.self)
        
        // 에러 응답 처리
        if let error = chartResponse.chart.error {
            throw YFError.apiError(error.description)
        }
        
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
        try validateClientReference()
        guard let client = client else { fatalError("Client validated but is nil") }
        
        // Yahoo Finance API 호출
        let startTimestamp = Int(startDate.timeIntervalSince1970)
        let endTimestamp = Int(endDate.timeIntervalSince1970)
        
        let request = try client.requestBuilder
            .path("/v8/finance/chart/\(ticker.symbol)")
            .queryParam("period1", String(startTimestamp))
            .queryParam("period2", String(endTimestamp))
            .queryParam("interval", "1d")
            .build()
        
        let (data, _) = try await authenticatedURLRequest(url: request.url!)
        
        // JSON 파싱
        let chartResponse = try parseJSON(data: data, type: ChartResponse.self)
        
        // 에러 응답 처리
        if let error = chartResponse.chart.error {
            throw YFError.apiError(error.description)
        }
        
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