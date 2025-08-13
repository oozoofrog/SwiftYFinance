import Foundation

/// Yahoo Finance 종목 스크리닝을 위한 빌더 클래스
/// 
/// 다양한 필터 조건을 조합하여 원하는 종목을 검색할 수 있는 스크리너를 구성합니다.
/// Python yfinance의 screener API를 참조하여 구현되었습니다.
///
/// ## 사용 예시
/// ```swift
/// let screener = YFScreener.equity()
///     .marketCap(min: 1_000_000_000)
///     .peRatio(max: 25)
///     .sector(.technology)
///     .sortBy(.marketCap, ascending: false)
///     .limit(50)
/// 
/// let results = try await client.screen(screener)
/// ```
public class YFScreener {
    internal var quoteType: YFQuoteType
    internal var filters: [YFScreenFilter] = []
    internal var sortField: YFScreenSortField = .ticker
    internal var sortAscending: Bool = true
    internal var limitCount: Int = 100
    internal var offsetValue: Int = 0
    
    private init(quoteType: YFQuoteType) {
        self.quoteType = quoteType
    }
    
    /// 주식(Equity) 스크리너 생성
    public static func equity() -> YFScreener {
        return YFScreener(quoteType: .equity)
    }
    
    /// 뮤추얼 펀드 스크리너 생성
    public static func mutualFund() -> YFScreener {
        return YFScreener(quoteType: .mutualFund)
    }
}

// MARK: - Market Cap Filters
public extension YFScreener {
    /// 시가총액 필터 (최소값)
    func marketCap(min: Double) -> YFScreener {
        filters.append(.marketCap(.greaterThanOrEqual(min)))
        return self
    }
    
    /// 시가총액 필터 (최대값)
    func marketCap(max: Double) -> YFScreener {
        filters.append(.marketCap(.lessThanOrEqual(max)))
        return self
    }
    
    /// 시가총액 필터 (범위)
    func marketCap(min: Double, max: Double) -> YFScreener {
        filters.append(.marketCap(.between(min, max)))
        return self
    }
}

// MARK: - Price Filters
public extension YFScreener {
    /// 주가 필터 (최소값)
    func minPrice(_ price: Double) -> YFScreener {
        filters.append(.price(.greaterThanOrEqual(price)))
        return self
    }
    
    /// 주가 필터 (최대값)
    func maxPrice(_ price: Double) -> YFScreener {
        filters.append(.price(.lessThanOrEqual(price)))
        return self
    }
    
    /// 주가 필터 (범위)
    func priceRange(min: Double, max: Double) -> YFScreener {
        filters.append(.price(.between(min, max)))
        return self
    }
}

// MARK: - Financial Ratio Filters
public extension YFScreener {
    /// P/E 비율 필터
    func peRatio(min: Double? = nil, max: Double? = nil) -> YFScreener {
        if let min = min {
            filters.append(.peRatio(.greaterThanOrEqual(min)))
        }
        if let max = max {
            filters.append(.peRatio(.lessThanOrEqual(max)))
        }
        return self
    }
    
    /// ROE (자기자본이익률) 필터
    func returnOnEquity(min: Double) -> YFScreener {
        filters.append(.returnOnEquity(.greaterThanOrEqual(min)))
        return self
    }
    
    /// 매출 성장률 필터
    func revenueGrowth(min: Double) -> YFScreener {
        filters.append(.revenueGrowth(.greaterThanOrEqual(min)))
        return self
    }
    
    /// 부채비율 필터
    func debtToEquity(max: Double) -> YFScreener {
        filters.append(.debtToEquity(.lessThanOrEqual(max)))
        return self
    }
}

// MARK: - Sector and Industry Filters
public extension YFScreener {
    /// 섹터 필터
    func sector(_ sector: YFSector) -> YFScreener {
        filters.append(.sector(.equals(sector.rawValue)))
        return self
    }
    
    /// 지역 필터
    func region(_ region: YFRegion) -> YFScreener {
        filters.append(.region(.equals(region.rawValue)))
        return self
    }
    
    /// 거래소 필터
    func exchange(_ exchange: YFExchange) -> YFScreener {
        filters.append(.exchange(.isIn([exchange.rawValue])))
        return self
    }
}

// MARK: - Volume and Activity Filters
public extension YFScreener {
    /// 일일 거래량 필터
    func dayVolume(min: Int) -> YFScreener {
        filters.append(.dayVolume(.greaterThan(Double(min))))
        return self
    }
    
    /// 일일 변동률 필터
    func percentChange(min: Double) -> YFScreener {
        filters.append(.percentChange(.greaterThan(min)))
        return self
    }
}

// MARK: - Sorting and Pagination
public extension YFScreener {
    /// 정렬 기준 설정
    func sortBy(_ field: YFScreenSortField, ascending: Bool = true) -> YFScreener {
        self.sortField = field
        self.sortAscending = ascending
        return self
    }
    
    /// 결과 개수 제한
    func limit(_ count: Int) -> YFScreener {
        self.limitCount = min(count, 250) // Yahoo 제한
        return self
    }
    
    /// 오프셋 (페이지네이션)
    func offset(_ offset: Int) -> YFScreener {
        self.offsetValue = offset
        return self
    }
}

// MARK: - Supporting Types

/// 스크리닝 대상 유형
public enum YFQuoteType: String {
    case equity = "EQUITY"
    case mutualFund = "MUTUALFUND"
}

/// 스크리닝 필터 조건
public enum YFScreenFilter {
    case marketCap(YFFilterOperator)
    case price(YFFilterOperator)
    case peRatio(YFFilterOperator)
    case returnOnEquity(YFFilterOperator)
    case revenueGrowth(YFFilterOperator)
    case debtToEquity(YFFilterOperator)
    case sector(YFFilterOperator)
    case region(YFFilterOperator)
    case exchange(YFFilterOperator)
    case dayVolume(YFFilterOperator)
    case percentChange(YFFilterOperator)
    
    /// 필터 필드명 반환
    var fieldName: String {
        switch self {
        case .marketCap: return "intradaymarketcap"
        case .price: return "intradayprice"
        case .peRatio: return "peratio.lasttwelvemonths"
        case .returnOnEquity: return "roe.lasttwelvemonths"
        case .revenueGrowth: return "quarterlyrevenuegrowth.quarterly"
        case .debtToEquity: return "debttoeq.lasttwelvemonths"
        case .sector: return "sector"
        case .region: return "region"
        case .exchange: return "exchange"
        case .dayVolume: return "dayvolume"
        case .percentChange: return "percentchange"
        }
    }
    
    /// 필터 연산자 반환
    var filterOperator: YFFilterOperator {
        switch self {
        case .marketCap(let op): return op
        case .price(let op): return op
        case .peRatio(let op): return op
        case .returnOnEquity(let op): return op
        case .revenueGrowth(let op): return op
        case .debtToEquity(let op): return op
        case .sector(let op): return op
        case .region(let op): return op
        case .exchange(let op): return op
        case .dayVolume(let op): return op
        case .percentChange(let op): return op
        }
    }
}

/// 스크리닝 필터 연산자
public enum YFFilterOperator {
    case equals(String)
    case greaterThan(Double)
    case lessThan(Double)
    case greaterThanOrEqual(Double)
    case lessThanOrEqual(Double)
    case between(Double, Double)
    case isIn([String])
    
    /// Yahoo API용 연산자 문자열
    var operatorString: String {
        switch self {
        case .equals: return "eq"
        case .greaterThan: return "gt"
        case .lessThan: return "lt"
        case .greaterThanOrEqual: return "gte"
        case .lessThanOrEqual: return "lte"
        case .between: return "btwn"
        case .isIn: return "is-in"
        }
    }
    
    /// 연산자 값 배열
    var values: [Any] {
        switch self {
        case .equals(let value): return [value]
        case .greaterThan(let value): return [value]
        case .lessThan(let value): return [value]
        case .greaterThanOrEqual(let value): return [value]
        case .lessThanOrEqual(let value): return [value]
        case .between(let min, let max): return [min, max]
        case .isIn(let values): return values
        }
    }
}

/// 정렬 필드
public enum YFScreenSortField: String {
    case ticker = "ticker"
    case marketCap = "intradaymarketcap"
    case price = "intradayprice"
    case percentChange = "percentchange"
    case dayVolume = "dayvolume"
    case peRatio = "peratio.lasttwelvemonths"
    case revenueGrowth = "quarterlyrevenuegrowth.quarterly"
}

/// 섹터 
public enum YFSector: String, CaseIterable {
    case technology = "Technology"
    case healthcare = "Healthcare"
    case financialServices = "Financial Services"
    case consumerCyclical = "Consumer Cyclical"
    case communicationServices = "Communication Services"
    case industrials = "Industrials"
    case consumerDefensive = "Consumer Defensive"
    case energy = "Energy"
    case utilities = "Utilities"
    case realEstate = "Real Estate"
    case basicMaterials = "Basic Materials"
}

/// 지역
public enum YFRegion: String {
    case us = "us"
    case europe = "europe"
    case asia = "asia"
}

/// 거래소
public enum YFExchange: String {
    case nyse = "NYQ"  // NYSE
    case nasdaq = "NMS"  // NASDAQ
    case amex = "ASE"   // AMEX
}

/// 스크리닝 결과 항목
public struct YFScreenResult {
    public let ticker: YFTicker
    public let companyName: String
    public let price: Double
    public let marketCap: Double
    public let percentChange: Double
    public let dayVolume: Int
    public let sector: String
    public let industry: String?
    public let region: String
    public let exchange: String
    
    // 재무 지표 (선택적)
    public let peRatio: Double?
    public let returnOnEquity: Double?
    public let revenueGrowth: Double?
    public let debtToEquity: Double?
    
    public init(
        ticker: YFTicker,
        companyName: String,
        price: Double,
        marketCap: Double,
        percentChange: Double,
        dayVolume: Int,
        sector: String,
        industry: String? = nil,
        region: String,
        exchange: String,
        peRatio: Double? = nil,
        returnOnEquity: Double? = nil,
        revenueGrowth: Double? = nil,
        debtToEquity: Double? = nil
    ) {
        self.ticker = ticker
        self.companyName = companyName
        self.price = price
        self.marketCap = marketCap
        self.percentChange = percentChange
        self.dayVolume = dayVolume
        self.sector = sector
        self.industry = industry
        self.region = region
        self.exchange = exchange
        self.peRatio = peRatio
        self.returnOnEquity = returnOnEquity
        self.revenueGrowth = revenueGrowth
        self.debtToEquity = debtToEquity
    }
}

/// 사전 정의된 스크리너
public enum YFPredefinedScreener: String, CaseIterable {
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