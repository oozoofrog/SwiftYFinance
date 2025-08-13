import Foundation

/// 옵션 체인 데이터
public struct YFOptionsChain {
    public let ticker: YFTicker
    public let expirationDates: [Date]
    private let chains: [Date: OptionsChain]
    
    public init(ticker: YFTicker, expirationDates: [Date], chains: [Date: OptionsChain] = [:]) {
        self.ticker = ticker
        self.expirationDates = expirationDates.sorted()
        self.chains = chains
    }
    
    /// 특정 만기일의 옵션 체인 조회
    public func getChain(for expiry: Date) -> OptionsChain {
        return chains[expiry] ?? OptionsChain(expirationDate: expiry, calls: [], puts: [])
    }
}

/// 특정 만기일의 옵션 체인
public struct OptionsChain {
    public let expirationDate: Date
    public let calls: [YFOption]
    public let puts: [YFOption]
    
    public init(expirationDate: Date, calls: [YFOption], puts: [YFOption]) {
        self.expirationDate = expirationDate
        self.calls = calls.sorted { $0.strike < $1.strike }
        self.puts = puts.sorted { $0.strike < $1.strike }
    }
}

/// 개별 옵션 계약
public struct YFOption {
    // 기본 정보
    public let contractSymbol: String
    public let strike: Double
    public let expiry: Date
    public let optionType: OptionType
    
    // 가격 정보
    public let lastPrice: Double
    public let bid: Double
    public let ask: Double
    public let change: Double
    public let percentChange: Double
    
    // 거래 정보
    public let volume: Int
    public let openInterest: Int
    public let impliedVolatility: Double
    
    // Greeks (Optional - 일부 옵션만 제공)
    public let delta: Double?
    public let gamma: Double?
    public let theta: Double?
    public let vega: Double?
    public let rho: Double?
    
    // 추가 정보
    public let lastTradeDate: Date?
    public let contractSize: Int
    public let currency: String
    public let inTheMoney: Bool
    
    public init(
        contractSymbol: String,
        strike: Double,
        expiry: Date,
        optionType: OptionType,
        lastPrice: Double,
        bid: Double,
        ask: Double,
        change: Double = 0,
        percentChange: Double = 0,
        volume: Int,
        openInterest: Int,
        impliedVolatility: Double,
        delta: Double? = nil,
        gamma: Double? = nil,
        theta: Double? = nil,
        vega: Double? = nil,
        rho: Double? = nil,
        lastTradeDate: Date? = nil,
        contractSize: Int = 100,
        currency: String = "USD",
        inTheMoney: Bool = false
    ) {
        self.contractSymbol = contractSymbol
        self.strike = strike
        self.expiry = expiry
        self.optionType = optionType
        self.lastPrice = lastPrice
        self.bid = bid
        self.ask = ask
        self.change = change
        self.percentChange = percentChange
        self.volume = volume
        self.openInterest = openInterest
        self.impliedVolatility = impliedVolatility
        self.delta = delta
        self.gamma = gamma
        self.theta = theta
        self.vega = vega
        self.rho = rho
        self.lastTradeDate = lastTradeDate
        self.contractSize = contractSize
        self.currency = currency
        self.inTheMoney = inTheMoney
    }
}

/// 옵션 타입
public enum OptionType: String, Codable {
    case call = "CALL"
    case put = "PUT"
}

/// 옵션 체인 필터
public struct OptionsFilter {
    public let minStrike: Double?
    public let maxStrike: Double?
    public let minVolume: Int?
    public let minOpenInterest: Int?
    public let onlyITM: Bool  // In The Money only
    public let onlyOTM: Bool  // Out of The Money only
    
    public init(
        minStrike: Double? = nil,
        maxStrike: Double? = nil,
        minVolume: Int? = nil,
        minOpenInterest: Int? = nil,
        onlyITM: Bool = false,
        onlyOTM: Bool = false
    ) {
        self.minStrike = minStrike
        self.maxStrike = maxStrike
        self.minVolume = minVolume
        self.minOpenInterest = minOpenInterest
        self.onlyITM = onlyITM
        self.onlyOTM = onlyOTM
    }
}