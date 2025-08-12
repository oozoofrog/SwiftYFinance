import Foundation

public struct YFQuote {
    public let ticker: YFTicker
    public let regularMarketPrice: Double
    public let regularMarketVolume: Int
    public let marketCap: Double
    public let shortName: String
    public let regularMarketTime: Date
    public let regularMarketOpen: Double
    public let regularMarketHigh: Double
    public let regularMarketLow: Double
    public let regularMarketPreviousClose: Double
    public let isRealtime: Bool
    
    // After Hours (Post Market) Data
    public let postMarketPrice: Double?
    public let postMarketTime: Date?
    public let postMarketChangePercent: Double?
    
    // Pre Market Data
    public let preMarketPrice: Double?
    public let preMarketTime: Date?
    public let preMarketChangePercent: Double?
    
    public init(
        ticker: YFTicker,
        regularMarketPrice: Double,
        regularMarketVolume: Int,
        marketCap: Double,
        shortName: String,
        regularMarketTime: Date,
        regularMarketOpen: Double,
        regularMarketHigh: Double,
        regularMarketLow: Double,
        regularMarketPreviousClose: Double,
        isRealtime: Bool = false,
        postMarketPrice: Double? = nil,
        postMarketTime: Date? = nil,
        postMarketChangePercent: Double? = nil,
        preMarketPrice: Double? = nil,
        preMarketTime: Date? = nil,
        preMarketChangePercent: Double? = nil
    ) {
        self.ticker = ticker
        self.regularMarketPrice = regularMarketPrice
        self.regularMarketVolume = regularMarketVolume
        self.marketCap = marketCap
        self.shortName = shortName
        self.regularMarketTime = regularMarketTime
        self.regularMarketOpen = regularMarketOpen
        self.regularMarketHigh = regularMarketHigh
        self.regularMarketLow = regularMarketLow
        self.regularMarketPreviousClose = regularMarketPreviousClose
        self.isRealtime = isRealtime
        self.postMarketPrice = postMarketPrice
        self.postMarketTime = postMarketTime
        self.postMarketChangePercent = postMarketChangePercent
        self.preMarketPrice = preMarketPrice
        self.preMarketTime = preMarketTime
        self.preMarketChangePercent = preMarketChangePercent
    }
}