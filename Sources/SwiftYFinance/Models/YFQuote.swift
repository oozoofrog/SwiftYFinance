import Foundation

// MARK: - Yahoo Finance Quote Models

/// Yahoo Finance quoteSummary API 응답 구조
public struct YFQuoteResponse: Decodable, Sendable {
    public let quoteSummary: YFQuoteSummary?
}

/// Quote summary wrapper
public struct YFQuoteSummary: Decodable, Sendable {
    public let result: [YFQuoteResult]?
    public let error: String?
}

/// Quote result container
public struct YFQuoteResult: Decodable, Sendable {
    public let price: YFQuote?
    public let summaryDetail: YFQuoteSummaryDetail?
}

/// Quote summary detail section - 모든 Yahoo Finance 필드 노출
public struct YFQuoteSummaryDetail: Decodable, Sendable {
    public let bidSize: Int?
    public let coinMarketCapLink: String?
    public let currency: String?
    public let lastMarket: String?
    public let previousClose: Double?
    public let regularMarketPreviousClose: Double?
    public let dividendRate: Double?
    public let dayHigh: Double?
    public let averageVolume10days: Int?
    public let payoutRatio: Double?
    public let bid: Double?
    public let priceToSalesTrailing12Months: Double?
    public let maxAge: Int?
    public let trailingPE: Double?
    public let volume: Int?
    public let regularMarketDayLow: Double?
    public let fromCurrency: String?
    public let regularMarketVolume: Int?
    public let fiftyTwoWeekLow: Double?
    public let beta: Double?
    public let algorithm: String?
    public let averageDailyVolume10Day: Int?
    public let dayLow: Double?
    public let regularMarketOpen: Double?
    public let fiveYearAvgDividendYield: Double?
    public let ask: Double?
    public let trailingAnnualDividendRate: Double?
    public let dividendYield: Double?
    public let toCurrency: String?
    public let exDividendDate: Int?
    public let trailingAnnualDividendYield: Double?
    public let forwardPE: Double?
    public let tradeable: Bool?
    public let averageVolume: Int?
    public let open: Double?
    public let fiftyDayAverage: Double?
    public let askSize: Int?
    public let priceHint: Int?
    public let twoHundredDayAverage: Double?
    public let marketCap: Double?
    public let fiftyTwoWeekHigh: Double?
    public let regularMarketDayHigh: Double?
}

/// 실시간 주식 시세 정보 - 모든 Yahoo Finance 필드 노출
public struct YFQuote: Decodable, Sendable {
    public let symbol: String?
    public let currency: String?
    public let lastMarket: String?
    public let preMarketSource: String?
    public let regularMarketPreviousClose: Double?
    public let regularMarketPrice: Double?
    public let averageDailyVolume3Month: Int?
    public let preMarketTime: Int?
    public let exchangeDataDelayedBy: Int?
    public let currencySymbol: String?
    public let maxAge: Int?
    public let regularMarketTime: Int?
    public let preMarketChangePercent: Double?
    public let regularMarketDayLow: Double?
    public let fromCurrency: String?
    public let regularMarketVolume: Int?
    public let averageDailyVolume10Day: Int?
    public let regularMarketOpen: Double?
    public let toCurrency: String?
    public let exchange: String?
    public let marketState: String?
    public let longName: String?
    public let preMarketChange: Double?
    public let underlyingSymbol: String?
    public let regularMarketChangePercent: Double?
    public let quoteSourceName: String?
    public let regularMarketChange: Double?
    public let exchangeName: String?
    public let preMarketPrice: Double?
    public let shortName: String?
    public let regularMarketSource: String?
    public let priceHint: Int?
    public let quoteType: String?
    public let marketCap: Double?
    public let regularMarketDayHigh: Double?
    public let postMarketPrice: Double?
    public let postMarketTime: Int?
    public let postMarketChange: Double?
    public let postMarketChangePercent: Double?
    public let postMarketSource: String?
}


