import Foundation

// MARK: - Yahoo Finance Screener Models

/// Yahoo Finance Screener API 응답 구조
public struct YFScreenerResponse: Decodable, Sendable {
    public let finance: YFScreenerFinance?
}

/// Finance wrapper
public struct YFScreenerFinance: Decodable, Sendable {
    public let result: [YFScreenerResult]?
    public let error: String?
}

/// Screener result container
public struct YFScreenerResult: Decodable, Sendable {
    public let id: String?
    public let title: String?
    public let description: String?
    public let canonicalName: String?
    public let criteriaMeta: YFScreenerCriteriaMeta?
    public let rawCriteria: String?
    public let start: Int?
    public let count: Int?
    public let total: Int?
    public let quotes: [YFScreenResult]?
}

/// Criteria meta
public struct YFScreenerCriteriaMeta: Decodable, Sendable {
    public let size: Int?
    public let offset: Int?
    public let sortField: String?
    public let sortType: String?
    public let quoteType: String?
    public let topOperator: String?
    public let criteria: [YFScreenerCriteria]?
}

/// Criteria
public struct YFScreenerCriteria: Decodable, Sendable {
    public let field: String?
    public let operators: [String]?
    public let values: [Double]?
    public let labelsSelected: [Int]?
    public let dependentValues: [String]?
}

/// 스크리닝 결과 항목 - 모든 Yahoo Finance 필드 노출
public struct YFScreenResult: Decodable, Sendable {
    public let language: String?
    public let region: String?
    public let quoteType: String?
    public let typeDisp: String?
    public let quoteSourceName: String?
    public let triggerable: Bool?
    public let customPriceAlertConfidence: String?
    public let currency: String?
    public let marketState: String?
    public let regularMarketChangePercent: Double?
    public let regularMarketPrice: Double?
    public let exchange: String?
    public let shortName: String?
    public let longName: String?
    public let messageBoardId: String?
    public let exchangeTimezoneName: String?
    public let exchangeTimezoneShortName: String?
    public let gmtOffSetMilliseconds: Int?
    public let market: String?
    public let esgPopulated: Bool?
    public let regularMarketChange: Double?
    public let regularMarketTime: Int?
    public let regularMarketDayHigh: Double?
    public let regularMarketDayRange: String?
    public let regularMarketDayLow: Double?
    public let regularMarketVolume: Double?
    public let regularMarketPreviousClose: Double?
    public let bid: Double?
    public let ask: Double?
    public let bidSize: Int?
    public let askSize: Int?
    public let fullExchangeName: String?
    public let financialCurrency: String?
    public let regularMarketOpen: Double?
    public let averageDailyVolume3Month: Double?
    public let averageDailyVolume10Day: Double?
    public let fiftyTwoWeekLowChange: Double?
    public let fiftyTwoWeekLowChangePercent: Double?
    public let fiftyTwoWeekRange: String?
    public let fiftyTwoWeekHighChange: Double?
    public let fiftyTwoWeekHighChangePercent: Double?
    public let fiftyTwoWeekLow: Double?
    public let fiftyTwoWeekHigh: Double?
    public let fiftyTwoWeekChangePercent: Double?
    public let dividendDate: Int?
    public let earningsTimestamp: Int?
    public let earningsTimestampStart: Int?
    public let earningsTimestampEnd: Int?
    public let trailingAnnualDividendRate: Double?
    public let dividendYield: Double?
    public let epsTrailingTwelveMonths: Double?
    public let epsForward: Double?
    public let epsCurrentYear: Double?
    public let priceEpsCurrentYear: Double?
    public let sharesOutstanding: Double?
    public let bookValue: Double?
    public let fiftyDayAverage: Double?
    public let fiftyDayAverageChange: Double?
    public let fiftyDayAverageChangePercent: Double?
    public let twoHundredDayAverage: Double?
    public let twoHundredDayAverageChange: Double?
    public let twoHundredDayAverageChangePercent: Double?
    public let marketCap: Double?
    public let forwardPE: Double?
    public let priceToBook: Double?
    public let sourceInterval: Int?
    public let exchangeDataDelayedBy: Int?
    public let pageViewGrowthWeekly: Double?
    public let averageAnalystRating: String?
    public let tradeable: Bool?
    public let cryptoTradeable: Bool?
    public let symbol: String?
    public let sector: String?
    public let industry: String?
    public let beta: Double?
    public let revenueQuarterlyGrowth: Double?
    public let totalCash: Double?
    public let totalCashPerShare: Double?
    public let totalDebt: Double?
    public let quickRatio: Double?
    public let currentRatio: Double?
    public let totalRevenue: Double?
    public let debtToEquity: Double?
    public let revenuePerShare: Double?
    public let returnOnAssets: Double?
    public let returnOnEquity: Double?
    public let grossProfits: Double?
    public let freeCashflow: Double?
    public let operatingCashflow: Double?
    public let earningsGrowth: Double?
    public let revenueGrowth: Double?
    public let grossMargins: Double?
    public let ebitdaMargins: Double?
    public let operatingMargins: Double?
    public let profitMargins: Double?
    public let financialCurrency2: String?
    public let displayName: String?
    public let firstTradeDateMilliseconds: Int?
    public let hasPrePostMarketData: Bool?
    public let corporateActions: [YFCorporateAction]?
    public let dividendRate: Double?
    public let trailingAnnualDividendYield: Double?
    public let trailingPE: Double?
    public let isEarningsDateEstimate: Bool?
    public let earningsCallTimestampStart: Int?
    public let earningsCallTimestampEnd: Int?
    public let lastCloseTevEbitLtm: Double?
    public let lastClosePriceToNNWCPerShare: Double?
    public let prevName: String?
    public let nameChangeDate: String?
}

/// Corporate action
public struct YFCorporateAction: Decodable, Sendable {
    public let message: String?
    public let header: String?
    public let meta: YFCorporateActionMeta?
}

/// Corporate action meta
public struct YFCorporateActionMeta: Decodable, Sendable {
    public let amount: String?
    public let eventType: String?
    public let dateEpochMs: Int?
}

/// 사전 정의된 스크리너
public enum YFPredefinedScreener: String, CaseIterable, Sendable {
    case dayGainers = "day_gainers"
    case dayLosers = "day_losers"
    case mostActives = "most_actives"
    case aggressiveSmallCaps = "aggressive_small_caps"
    case growthTechnologyStocks = "growth_technology_stocks"
    case undervaluedGrowthStocks = "undervalued_growth_stocks"
    case undervaluedLargeCaps = "undervalued_large_caps"
    case smallCapGainers = "small_cap_gainers"
    case mostShortedStocks = "most_shorted_stocks"
    
    /// 스크리너 설명
    public var description: String {
        switch self {
        case .dayGainers: return "일일 상승률 3% 이상, 시가총액 20억 이상"
        case .dayLosers: return "일일 하락률 -2.5% 이하, 시가총액 20억 이상"
        case .mostActives: return "가장 활발한 거래량, 시가총액 20억 이상"
        case .aggressiveSmallCaps: return "공격적인 소형주, EPS 성장률 15% 이하"
        case .growthTechnologyStocks: return "성장하는 기술주, 매출/EPS 성장률 25% 이상"
        case .undervaluedGrowthStocks: return "저평가된 성장주, P/E 20 이하, PEG 1 이하"
        case .undervaluedLargeCaps: return "저평가된 대형주, 시가총액 100억~1000억"
        case .smallCapGainers: return "소형주 상승종목, 시가총액 20억 이하"
        case .mostShortedStocks: return "공매도 비중이 높은 종목"
        }
    }
}