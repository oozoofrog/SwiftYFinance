import Foundation

public struct YFHistoricalData {
    public let ticker: YFTicker
    public let prices: [YFPrice]
    public let startDate: Date
    public let endDate: Date
    
    public var isEmpty: Bool {
        prices.isEmpty
    }
    
    public var count: Int {
        prices.count
    }
    
    public init(
        ticker: YFTicker,
        prices: [YFPrice],
        startDate: Date,
        endDate: Date
    ) throws {
        guard startDate <= endDate else {
            throw YFError.invalidDateRange
        }
        
        self.ticker = ticker
        self.prices = prices
        self.startDate = startDate
        self.endDate = endDate
    }
}