import Foundation

// MARK: - Yahoo Finance Screener API Response Models

/// Yahoo Finance Screener API 응답 구조
struct YFScreenerResponse: Codable {
    let finance: YFScreenerFinance?
}

/// Finance wrapper
struct YFScreenerFinance: Codable {
    let result: [YFScreenerResult]?
    let error: String?
}

/// Screener result
struct YFScreenerResult: Codable {
    let id: String?
    let title: String?
    let description: String?
    let canonicalName: String?
    let criteriaMeta: YFScreenerCriteriaMeta?
    let rawCriteria: String?
    let start: Int?
    let count: Int?
    let total: Int?
    let quotes: [YFScreenerQuote]?
}

/// Criteria meta
struct YFScreenerCriteriaMeta: Codable {
    let size: Int?
    let offset: Int?
    let sortField: String?
    let sortType: String?
    let quoteType: String?
    let topOperator: String?
    let criteria: [YFScreenerCriteria]?
}

/// Criteria
struct YFScreenerCriteria: Codable {
    let field: String?
    let operators: [String]?
    let values: [Double]?
    let labelsSelected: [Int]?
    let dependentValues: [String]?
}

/// Screener quote
struct YFScreenerQuote: Codable {
    let language: String?
    let region: String?
    let quoteType: String?
    let typeDisp: String?
    let quoteSourceName: String?
    let triggerable: Bool?
    let customPriceAlertConfidence: String?
    let currency: String?
    let marketState: String?
    let regularMarketChangePercent: Double?
    let regularMarketPrice: Double?
    let exchange: String?
    let shortName: String?
    let longName: String?
    let messageBoardId: String?
    let exchangeTimezoneName: String?
    let exchangeTimezoneShortName: String?
    let gmtOffSetMilliseconds: Int?
    let market: String?
    let esgPopulated: Bool?
    let regularMarketChange: Double?
    let regularMarketTime: Int?
    let regularMarketDayHigh: Double?
    let regularMarketDayRange: String?
    let regularMarketDayLow: Double?
    let regularMarketVolume: Double?
    let regularMarketPreviousClose: Double?
    let bid: Double?
    let ask: Double?
    let bidSize: Int?
    let askSize: Int?
    let fullExchangeName: String?
    let financialCurrency: String?
    let regularMarketOpen: Double?
    let averageDailyVolume3Month: Double?
    let averageDailyVolume10Day: Double?
    let fiftyTwoWeekLowChange: Double?
    let fiftyTwoWeekLowChangePercent: Double?
    let fiftyTwoWeekRange: String?
    let fiftyTwoWeekHighChange: Double?
    let fiftyTwoWeekHighChangePercent: Double?
    let fiftyTwoWeekLow: Double?
    let fiftyTwoWeekHigh: Double?
    let fiftyTwoWeekChangePercent: Double?
    let dividendDate: Int?
    let earningsTimestamp: Int?
    let earningsTimestampStart: Int?
    let earningsTimestampEnd: Int?
    let trailingAnnualDividendRate: Double?
    let dividendYield: Double?
    let epsTrailingTwelveMonths: Double?
    let epsForward: Double?
    let epsCurrentYear: Double?
    let priceEpsCurrentYear: Double?
    let sharesOutstanding: Double?
    let bookValue: Double?
    let fiftyDayAverage: Double?
    let fiftyDayAverageChange: Double?
    let fiftyDayAverageChangePercent: Double?
    let twoHundredDayAverage: Double?
    let twoHundredDayAverageChange: Double?
    let twoHundredDayAverageChangePercent: Double?
    let marketCap: Double?
    let forwardPE: Double?
    let priceToBook: Double?
    let sourceInterval: Int?
    let exchangeDataDelayedBy: Int?
    let pageViewGrowthWeekly: Double?
    let averageAnalystRating: String?
    let tradeable: Bool?
    let cryptoTradeable: Bool?
    let symbol: String?
    let sector: String?
    let industry: String?
    let beta: Double?
    let revenueQuarterlyGrowth: Double?
    let totalCash: Double?
    let totalCashPerShare: Double?
    let totalDebt: Double?
    let quickRatio: Double?
    let currentRatio: Double?
    let totalRevenue: Double?
    let debtToEquity: Double?
    let revenuePerShare: Double?
    let returnOnAssets: Double?
    let returnOnEquity: Double?
    let grossProfits: Double?
    let freeCashflow: Double?
    let operatingCashflow: Double?
    let earningsGrowth: Double?
    let revenueGrowth: Double?
    let grossMargins: Double?
    let ebitdaMargins: Double?
    let operatingMargins: Double?
    let profitMargins: Double?
    let financialCurrency2: String?
}