import Foundation

// MARK: - Fundamentals Timeseries API Response Models

/// Fundamentals Timeseries API 응답 구조
struct FundamentalsTimeseriesResponse: Codable {
    let timeseries: TimeseriesData?
    let error: String?
}

/// Timeseries 데이터 컨테이너
struct TimeseriesData: Codable {
    let result: [TimeseriesResult]?
    let error: String?
}

/// 개별 Timeseries 결과
struct TimeseriesResult: Codable {
    let meta: TimeseriesMeta?
    let timestamp: [Int]?
    // 실제 응답에서는 각 metric이 직접 배열로 포함됨
    let annualTotalAssets: [TimeseriesValue]?
    let quarterlyTotalAssets: [TimeseriesValue]?
    let annualTotalCurrentAssets: [TimeseriesValue]?
    let quarterlyTotalCurrentAssets: [TimeseriesValue]?
    let annualTotalCurrentLiabilities: [TimeseriesValue]?
    let quarterlyTotalCurrentLiabilities: [TimeseriesValue]?
    let annualTotalStockholderEquity: [TimeseriesValue]?
    let quarterlyTotalStockholderEquity: [TimeseriesValue]?
    let annualRetainedEarnings: [TimeseriesValue]?
}

/// Timeseries 메타데이터
struct TimeseriesMeta: Codable {
    let symbol: [String]?
    let type: [String]?
}

/// Timeseries 값 구조
struct TimeseriesValue: Codable {
    let dataId: Int?
    let asOfDate: String?
    let periodType: String?
    let currencyCode: String?
    let reportedValue: ReportedValue?
}

/// 보고된 값 구조
struct ReportedValue: Codable {
    let raw: Double?
    let fmt: String?
}