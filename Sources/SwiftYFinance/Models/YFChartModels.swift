import Foundation

// MARK: - Yahoo Finance Chart API Response Models

struct ChartResponse: Codable {
    let chart: Chart
}

struct Chart: Codable {
    let result: [ChartResult]?
    let error: ChartError?
}

struct ChartError: Codable {
    let code: String
    let description: String
}

struct ChartResult: Codable {
    let meta: ChartMeta
    let timestamp: [Int]?
    let indicators: ChartIndicators
}

struct ChartMeta: Codable {
    let currency: String?
    let symbol: String
    let exchangeName: String?
    let fullExchangeName: String?
    let instrumentType: String?
    let firstTradeDate: Int?
    let regularMarketTime: Int?
    let hasPrePostMarketData: Bool?
    let gmtoffset: Int?
    let timezone: String?
    let exchangeTimezoneName: String?
    let regularMarketPrice: Double?
    let fiftyTwoWeekHigh: Double?
    let fiftyTwoWeekLow: Double?
    let regularMarketDayHigh: Double?
    let regularMarketDayLow: Double?
    let regularMarketVolume: Int?
    let longName: String?
    let shortName: String?
    let priceHint: Int?
    let validRanges: [String]?
}

struct ChartIndicators: Codable {
    let quote: [ChartQuote]
    let adjclose: [ChartAdjClose]?
}

struct ChartQuote: Codable {
    let open: [Double]
    let high: [Double]
    let low: [Double]
    let close: [Double]
    let volume: [Int]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // null 값을 -1.0으로 처리
        let openOptional = try container.decode([Double?].self, forKey: .open)
        self.open = openOptional.map { $0 ?? -1.0 }
        
        let highOptional = try container.decode([Double?].self, forKey: .high)
        self.high = highOptional.map { $0 ?? -1.0 }
        
        let lowOptional = try container.decode([Double?].self, forKey: .low)
        self.low = lowOptional.map { $0 ?? -1.0 }
        
        let closeOptional = try container.decode([Double?].self, forKey: .close)
        self.close = closeOptional.map { $0 ?? -1.0 }
        
        let volumeOptional = try container.decode([Int?].self, forKey: .volume)
        self.volume = volumeOptional.map { $0 ?? -1 }
    }
}

struct ChartAdjClose: Codable {
    let adjclose: [Double]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // null 값을 -1.0으로 처리
        let adjcloseOptional = try container.decode([Double?].self, forKey: .adjclose)
        self.adjclose = adjcloseOptional.map { $0 ?? -1.0 }
    }
}