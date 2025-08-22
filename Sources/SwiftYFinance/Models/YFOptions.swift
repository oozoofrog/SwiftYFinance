import Foundation

// MARK: - Yahoo Finance Options Models

/// Yahoo Finance 옵션체인 API 응답 구조
public struct YFOptionsChainResponse: Decodable, Sendable {
    public let optionChain: YFOptionChain?
}

/// Option chain wrapper
public struct YFOptionChain: Decodable, Sendable {
    public let result: [YFOptionsChainResult]?
    public let error: String?
}

/// Options chain result - 모든 Yahoo Finance 필드 노출
public struct YFOptionsChainResult: Decodable, Sendable {
    public let underlyingSymbol: String?
    public let expirationDates: [Int]?
    public let strikes: [Double]?
    public let hasMiniOptions: Bool?
    public let quote: YFOptionsQuote?
    public let options: [YFOptionData]?
}

/// Option data container
public struct YFOptionData: Decodable, Sendable {
    public let expirationDate: Int?
    public let hasMiniOptions: Bool?
    public let calls: [YFOption]?
    public let puts: [YFOption]?
}

/// Options quote - 모든 Yahoo Finance 필드 노출
public struct YFOptionsQuote: Decodable, Sendable {
    public let earningsTimestampEnd: Int?
    public let longName: String?
    public let forwardPE: Double?
    public let regularMarketDayHigh: Double?
    public let dividendRate: Double?
    public let dividendYield: Double?
    public let regularMarketPreviousClose: Double?
    public let fiftyTwoWeekLow: Double?
    public let isEarningsDateEstimate: Bool?
    public let exchangeTimezoneName: String?
    public let customPriceAlertConfidence: String?
    public let trailingPE: Double?
    public let priceEpsCurrentYear: Double?
    public let askSize: Int?
    public let trailingAnnualDividendYield: Double?
    public let exchangeTimezoneShortName: String?
    public let regularMarketVolume: Int?
    public let sharesOutstanding: Int?
    public let earningsTimestampStart: Int?
    public let priceToBook: Double?
    public let currency: String?
    public let regularMarketChangePercent: Double?
    public let priceHint: Int?
    public let fiftyTwoWeekHighChange: Double?
    public let averageDailyVolume3Month: Int?
    public let earningsCallTimestampEnd: Int?
    public let twoHundredDayAverage: Double?
    public let fiftyTwoWeekLowChangePercent: Double?
    public let trailingAnnualDividendRate: Double?
    public let fiftyDayAverageChange: Double?
    public let bidSize: Int?
    public let fiftyTwoWeekHigh: Double?
    public let exchange: String?
    public let fullExchangeName: String?
    public let bookValue: Double?
    public let quoteType: String?
    public let fiftyDayAverage: Double?
    public let twoHundredDayAverageChangePercent: Double?
    public let region: String?
    public let earningsCallTimestampStart: Int?
    public let averageAnalystRating: String?
    public let regularMarketDayLow: Double?
    public let twoHundredDayAverageChange: Double?
    public let marketCap: Double?
    public let regularMarketPrice: Double?
    public let quoteSourceName: String?
    public let tradeable: Bool?
    public let financialCurrency: String?
    public let epsForward: Double?
    public let ask: Double?
    public let regularMarketDayRange: String?
    public let bid: Double?
    public let regularMarketOpen: Double?
    public let epsCurrentYear: Double?
    public let symbol: String?
    public let fiftyTwoWeekChangePercent: Double?
    public let averageDailyVolume10Day: Int?
    public let marketState: String?
    public let fiftyTwoWeekLowChange: Double?
    public let displayName: String?
    public let market: String?
    public let earningsTimestamp: Int?
    public let corporateActions: [String]?  // Simplified - usually empty array
    public let dividendDate: Int?
    public let exchangeDataDelayedBy: Int?
    public let regularMarketTime: Int?
    public let fiftyTwoWeekHighChangePercent: Double?
    public let shortName: String?
    public let hasPrePostMarketData: Bool?
    public let epsTrailingTwelveMonths: Double?
    public let firstTradeDateMilliseconds: Int?
    public let messageBoardId: String?
    public let language: String?
    public let typeDisp: String?
    public let triggerable: Bool?
    public let fiftyTwoWeekRange: String?
    public let fiftyDayAverageChangePercent: Double?
    public let cryptoTradeable: Bool?
    public let regularMarketChange: Double?
    public let gmtOffSetMilliseconds: Int?
    public let esgPopulated: Bool?
    public let sourceInterval: Int?
}

/// Individual option contract - 모든 Yahoo Finance 필드 노출
public struct YFOption: Decodable, Sendable {
    public let contractSymbol: String?
    public let strike: Double?
    public let currency: String?
    public let lastPrice: Double?
    public let change: Double?
    public let percentChange: Double?
    public let volume: Int?
    public let openInterest: Int?
    public let bid: Double?
    public let ask: Double?
    public let contractSize: String?
    public let expiration: Int?
    public let lastTradeDate: Int?
    public let impliedVolatility: Double?
    public let inTheMoney: Bool?
}