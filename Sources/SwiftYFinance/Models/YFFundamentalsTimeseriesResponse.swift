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
    
    // Balance Sheet metrics
    let annualTotalAssets: [TimeseriesValue]?
    let quarterlyTotalAssets: [TimeseriesValue]?
    let annualTotalCurrentAssets: [TimeseriesValue]?
    let quarterlyTotalCurrentAssets: [TimeseriesValue]?
    let annualTotalCurrentLiabilities: [TimeseriesValue]?
    let quarterlyTotalCurrentLiabilities: [TimeseriesValue]?
    let annualTotalStockholderEquity: [TimeseriesValue]?
    let quarterlyTotalStockholderEquity: [TimeseriesValue]?
    let annualRetainedEarnings: [TimeseriesValue]?
    
    // Cash Flow metrics (yfinance-reference 기반)
    let annualFreeCashFlow: [TimeseriesValue]?
    let quarterlyFreeCashFlow: [TimeseriesValue]?
    let annualOperatingCashFlow: [TimeseriesValue]?
    let quarterlyOperatingCashFlow: [TimeseriesValue]?
    let annualCapitalExpenditure: [TimeseriesValue]?
    let quarterlyCapitalExpenditure: [TimeseriesValue]?
    let annualNetPPEPurchaseAndSale: [TimeseriesValue]?
    let quarterlyNetPPEPurchaseAndSale: [TimeseriesValue]?
    let annualFinancingCashFlow: [TimeseriesValue]?
    let quarterlyFinancingCashFlow: [TimeseriesValue]?
    let annualInvestingCashFlow: [TimeseriesValue]?
    let quarterlyInvestingCashFlow: [TimeseriesValue]?
    let annualChangesInCash: [TimeseriesValue]?
    let quarterlyChangesInCash: [TimeseriesValue]?
    let annualBeginningCashPosition: [TimeseriesValue]?
    let quarterlyBeginningCashPosition: [TimeseriesValue]?
    let annualEndCashPosition: [TimeseriesValue]?
    let quarterlyEndCashPosition: [TimeseriesValue]?
    
    // Income Statement metrics (Financials API 용)
    let annualTotalRevenue: [TimeseriesValue]?
    let quarterlyTotalRevenue: [TimeseriesValue]?
    let annualNetIncome: [TimeseriesValue]?
    let quarterlyNetIncome: [TimeseriesValue]?
    let annualGrossProfit: [TimeseriesValue]?
    let quarterlyGrossProfit: [TimeseriesValue]?
    let annualOperatingIncome: [TimeseriesValue]?
    let quarterlyOperatingIncome: [TimeseriesValue]?
    let annualTotalDebt: [TimeseriesValue]?
    let quarterlyTotalDebt: [TimeseriesValue]?
    let annualCashAndCashEquivalents: [TimeseriesValue]?
    let quarterlyCashAndCashEquivalents: [TimeseriesValue]?
    
    // Earnings-specific metrics (Earnings API 용)
    let annualBasicEPS: [TimeseriesValue]?
    let quarterlyBasicEPS: [TimeseriesValue]?
    let annualDilutedEPS: [TimeseriesValue]?
    let quarterlyDilutedEPS: [TimeseriesValue]?
    let annualEBITDA: [TimeseriesValue]?
    let quarterlyEBITDA: [TimeseriesValue]?
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