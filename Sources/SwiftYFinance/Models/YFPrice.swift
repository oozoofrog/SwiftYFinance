import Foundation

public struct YFPrice: Equatable, Comparable, Codable {
    public let date: Date
    public let open: Double
    public let high: Double
    public let low: Double
    public let close: Double
    public let adjClose: Double
    public let volume: Int
    
    public init(
        date: Date,
        open: Double,
        high: Double,
        low: Double,
        close: Double,
        adjClose: Double,
        volume: Int
    ) {
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.adjClose = adjClose
        self.volume = volume
    }
    
    public static func < (lhs: YFPrice, rhs: YFPrice) -> Bool {
        lhs.date < rhs.date
    }
}