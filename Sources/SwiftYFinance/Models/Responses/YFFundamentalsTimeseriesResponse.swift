import Foundation

// MARK: - Fundamentals Timeseries API Response Models

/// Fundamentals Timeseries API 응답 구조
public struct FundamentalsTimeseriesResponse: Decodable, Sendable {
    public let timeseries: TimeseriesData?
    public let error: String?
}

/// Timeseries 데이터 컨테이너
public struct TimeseriesData: Decodable, Sendable {
    public let result: [TimeseriesResult]?
    public let error: String?
}

/// 개별 Timeseries 결과
public struct TimeseriesResult: Decodable, Sendable {
    public let meta: TimeseriesMeta?
    public let timestamp: [Int]?
    
    // Balance Sheet metrics
    public let annualTotalAssets: [TimeseriesValue]?
    public let quarterlyTotalAssets: [TimeseriesValue]?
    public let annualTotalCurrentAssets: [TimeseriesValue]?
    public let quarterlyTotalCurrentAssets: [TimeseriesValue]?
    public let annualTotalCurrentLiabilities: [TimeseriesValue]?
    public let quarterlyTotalCurrentLiabilities: [TimeseriesValue]?
    public let annualTotalStockholderEquity: [TimeseriesValue]?
    public let quarterlyTotalStockholderEquity: [TimeseriesValue]?
    public let annualRetainedEarnings: [TimeseriesValue]?
    
    // Cash Flow metrics (yfinance-reference 기반)
    public let annualFreeCashFlow: [TimeseriesValue]?
    public let quarterlyFreeCashFlow: [TimeseriesValue]?
    public let annualOperatingCashFlow: [TimeseriesValue]?
    public let quarterlyOperatingCashFlow: [TimeseriesValue]?
    public let annualCapitalExpenditure: [TimeseriesValue]?
    public let quarterlyCapitalExpenditure: [TimeseriesValue]?
    public let annualNetPPEPurchaseAndSale: [TimeseriesValue]?
    public let quarterlyNetPPEPurchaseAndSale: [TimeseriesValue]?
    public let annualFinancingCashFlow: [TimeseriesValue]?
    public let quarterlyFinancingCashFlow: [TimeseriesValue]?
    public let annualInvestingCashFlow: [TimeseriesValue]?
    public let quarterlyInvestingCashFlow: [TimeseriesValue]?
    public let annualChangesInCash: [TimeseriesValue]?
    public let quarterlyChangesInCash: [TimeseriesValue]?
    public let annualBeginningCashPosition: [TimeseriesValue]?
    public let quarterlyBeginningCashPosition: [TimeseriesValue]?
    public let annualEndCashPosition: [TimeseriesValue]?
    public let quarterlyEndCashPosition: [TimeseriesValue]?
    
    // Income Statement metrics (Financials API 용)
    public let annualTotalRevenue: [TimeseriesValue]?
    public let quarterlyTotalRevenue: [TimeseriesValue]?
    public let annualNetIncome: [TimeseriesValue]?
    public let quarterlyNetIncome: [TimeseriesValue]?
    public let annualGrossProfit: [TimeseriesValue]?
    public let quarterlyGrossProfit: [TimeseriesValue]?
    public let annualOperatingIncome: [TimeseriesValue]?
    public let quarterlyOperatingIncome: [TimeseriesValue]?
    public let annualTotalDebt: [TimeseriesValue]?
    public let quarterlyTotalDebt: [TimeseriesValue]?
    public let annualCashAndCashEquivalents: [TimeseriesValue]?
    public let quarterlyCashAndCashEquivalents: [TimeseriesValue]?
    
    // Earnings-specific metrics (Earnings API 용)
    public let annualBasicEPS: [TimeseriesValue]?
    public let quarterlyBasicEPS: [TimeseriesValue]?
    public let annualDilutedEPS: [TimeseriesValue]?
    public let quarterlyDilutedEPS: [TimeseriesValue]?
    public let annualEBITDA: [TimeseriesValue]?
    public let quarterlyEBITDA: [TimeseriesValue]?
}

/// Timeseries 메타데이터
public struct TimeseriesMeta: Decodable, Sendable {
    public let symbol: [String]?
    public let type: [String]?
}

/// Timeseries 값 구조
public struct TimeseriesValue: Decodable, Sendable {
    public let dataId: Int?
    public let asOfDate: String?
    public let periodType: String?
    public let currencyCode: String?
    public let reportedValue: ReportedValue?
}

/// 보고된 값 구조
public struct ReportedValue: Decodable, Sendable {
    public let raw: Double?
    public let fmt: String?
}