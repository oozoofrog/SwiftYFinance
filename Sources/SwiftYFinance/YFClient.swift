import Foundation

public enum YFPeriod {
    case oneDay
    case oneWeek
    case oneMonth
    case threeMonths
    case sixMonths
    case oneYear
    case twoYears
    case fiveYears
    case tenYears
    case max
}

public class YFClient {
    private let session: YFSession
    private let requestBuilder: YFRequestBuilder
    private let responseParser: YFResponseParser
    
    public init() {
        self.session = YFSession()
        self.requestBuilder = YFRequestBuilder(session: session)
        self.responseParser = YFResponseParser()
    }
    
    public func fetchHistory(ticker: YFTicker, period: YFPeriod) async throws -> YFHistoricalData {
        // 테스트를 위한 임시 구현 - 실제로는 API 호출
        
        // 잘못된 심볼 체크 (테스트용)
        if ticker.symbol == "INVALID" {
            throw YFError.invalidSymbol
        }
        
        // 빈 결과 처리 (테스트용)
        if ticker.symbol == "EMPTY" {
            return try YFHistoricalData(
                ticker: ticker,
                prices: [],
                startDate: dateFromPeriod(period),
                endDate: Date()
            )
        }
        
        let mockPrice = YFPrice(
            date: dateFromPeriod(period),
            open: 150.0,
            high: 152.0,
            low: 149.0,
            close: 151.0,
            adjClose: 151.0,
            volume: 1000000
        )
        
        return try YFHistoricalData(
            ticker: ticker,
            prices: [mockPrice],
            startDate: dateFromPeriod(period),
            endDate: Date()
        )
    }
    
    public func fetchHistory(ticker: YFTicker, startDate: Date, endDate: Date) async throws -> YFHistoricalData {
        // 테스트를 위한 임시 구현 - 실제로는 API 호출
        
        // 잘못된 심볼 체크 (테스트용)
        if ticker.symbol == "INVALID" {
            throw YFError.invalidSymbol
        }
        
        // 빈 결과 처리 (테스트용)
        if ticker.symbol == "EMPTY" {
            return try YFHistoricalData(
                ticker: ticker,
                prices: [],
                startDate: startDate,
                endDate: endDate
            )
        }
        
        let mockPrice = YFPrice(
            date: startDate,
            open: 200.0,
            high: 205.0,
            low: 198.0,
            close: 203.0,
            adjClose: 203.0,
            volume: 1500000
        )
        
        return try YFHistoricalData(
            ticker: ticker,
            prices: [mockPrice],
            startDate: startDate,
            endDate: endDate
        )
    }
    
    public func fetchQuote(ticker: YFTicker) async throws -> YFQuote {
        // 테스트를 위한 임시 구현 - 실제로는 API 호출
        
        // 잘못된 심볼 체크 (테스트용)
        if ticker.symbol == "INVALID" {
            throw YFError.invalidSymbol
        }
        
        // NVDA의 경우 시간외 거래 데이터 제공
        if ticker.symbol == "NVDA" {
            return YFQuote(
                ticker: ticker,
                regularMarketPrice: 875.25,
                regularMarketVolume: 2500000,
                marketCap: 2100000000000, // 2.1T
                shortName: "NVIDIA Corporation",
                regularMarketTime: Date().addingTimeInterval(-3600), // 1시간 전
                regularMarketOpen: 870.50,
                regularMarketHigh: 880.75,
                regularMarketLow: 865.30,
                regularMarketPreviousClose: 868.90,
                isRealtime: false,
                postMarketPrice: 878.50,
                postMarketTime: Date().addingTimeInterval(-1800), // 30분 전
                postMarketChangePercent: 0.37,
                preMarketPrice: 869.75,
                preMarketTime: Date().addingTimeInterval(-7200), // 2시간 전
                preMarketChangePercent: 0.10
            )
        }
        
        return YFQuote(
            ticker: ticker,
            regularMarketPrice: 150.25,
            regularMarketVolume: 1000000,
            marketCap: 2500000000000, // 2.5T
            shortName: "Apple Inc.",
            regularMarketTime: Date(),
            regularMarketOpen: 149.80,
            regularMarketHigh: 151.50,
            regularMarketLow: 148.90,
            regularMarketPreviousClose: 149.50,
            isRealtime: false
        )
    }
    
    public func fetchQuote(ticker: YFTicker, realtime: Bool) async throws -> YFQuote {
        // 테스트를 위한 임시 구현 - 실제로는 API 호출
        
        // 잘못된 심볼 체크 (테스트용)
        if ticker.symbol == "INVALID" {
            throw YFError.invalidSymbol
        }
        
        // 실시간 데이터는 더 최신 시간으로 설정
        let marketTime = realtime ? Date() : Date().addingTimeInterval(-3600) // 1시간 전
        
        return YFQuote(
            ticker: ticker,
            regularMarketPrice: realtime ? 245.75 : 240.30,
            regularMarketVolume: realtime ? 800000 : 1200000,
            marketCap: 750000000000, // 750B
            shortName: "Tesla Inc.",
            regularMarketTime: marketTime,
            regularMarketOpen: realtime ? 243.50 : 238.90,
            regularMarketHigh: realtime ? 247.20 : 242.10,
            regularMarketLow: realtime ? 242.80 : 237.50,
            regularMarketPreviousClose: 240.30,
            isRealtime: realtime
        )
    }
    
    public func fetchFinancials(ticker: YFTicker) async throws -> YFFinancials {
        // 테스트를 위한 임시 구현 - 실제로는 API 호출
        
        // 잘못된 심볼 체크 (테스트용)
        if ticker.symbol == "INVALID" {
            throw YFError.invalidSymbol
        }
        
        // Mock 재무 데이터 생성
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        let report2023 = YFFinancialReport(
            reportDate: calendar.date(from: DateComponents(year: currentYear - 1, month: 6, day: 30)) ?? Date(),
            totalRevenue: 211915000000, // $211.9B
            netIncome: 72361000000,     // $72.4B
            totalAssets: 411976000000,  // $412.0B
            totalLiabilities: 198298000000, // $198.3B
            grossProfit: 169148000000,  // $169.1B
            operatingIncome: 88523000000, // $88.5B
            totalCash: 29263000000,     // $29.3B
            totalDebt: 47032000000      // $47.0B
        )
        
        let report2022 = YFFinancialReport(
            reportDate: calendar.date(from: DateComponents(year: currentYear - 2, month: 6, day: 30)) ?? Date(),
            totalRevenue: 198270000000, // $198.3B
            netIncome: 65125000000,     // $65.1B
            totalAssets: 364840000000,  // $364.8B
            totalLiabilities: 186167000000, // $186.2B
            grossProfit: 135620000000,  // $135.6B
            operatingIncome: 83383000000, // $83.4B
            totalCash: 13931000000,     // $13.9B
            totalDebt: 47032000000      // $47.0B
        )
        
        return YFFinancials(
            ticker: ticker,
            annualReports: [report2023, report2022]
        )
    }
    
    public func fetchBalanceSheet(ticker: YFTicker) async throws -> YFBalanceSheet {
        // 테스트를 위한 임시 구현 - 실제로는 API 호출
        
        // 잘못된 심볼 체크 (테스트용)
        if ticker.symbol == "INVALID" {
            throw YFError.invalidSymbol
        }
        
        // Mock 대차대조표 데이터 생성
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        let report2023 = YFBalanceSheetReport(
            reportDate: calendar.date(from: DateComponents(year: currentYear - 1, month: 12, day: 31)) ?? Date(),
            totalCurrentAssets: 143566000000,  // $143.6B
            totalCurrentLiabilities: 63710000000,  // $63.7B
            totalStockholderEquity: 267270000000,  // $267.3B
            retainedEarnings: 164726000000,  // $164.7B
            totalAssets: 395916000000,  // $395.9B
            totalLiabilities: 128646000000,  // $128.6B
            cash: 73100000000,  // $73.1B
            shortTermInvestments: 31590000000  // $31.6B
        )
        
        let report2022 = YFBalanceSheetReport(
            reportDate: calendar.date(from: DateComponents(year: currentYear - 2, month: 12, day: 31)) ?? Date(),
            totalCurrentAssets: 135405000000,  // $135.4B
            totalCurrentLiabilities: 60845000000,  // $60.8B
            totalStockholderEquity: 253226000000,  // $253.2B
            retainedEarnings: 154058000000,  // $154.1B
            totalAssets: 381191000000,  // $381.2B
            totalLiabilities: 127965000000,  // $128.0B
            cash: 48844000000,  // $48.8B
            shortTermInvestments: 24658000000  // $24.7B
        )
        
        return YFBalanceSheet(
            ticker: ticker,
            annualReports: [report2023, report2022]
        )
    }
    
    private func periodStart(for period: YFPeriod) -> String {
        let date: Date
        let calendar = Calendar.current
        
        switch period {
        case .oneDay:
            date = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        case .oneWeek:
            date = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        case .oneMonth:
            date = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .threeMonths:
            date = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        case .sixMonths:
            date = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        case .oneYear:
            date = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        case .twoYears:
            date = calendar.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        case .fiveYears:
            date = calendar.date(byAdding: .year, value: -5, to: Date()) ?? Date()
        case .tenYears:
            date = calendar.date(byAdding: .year, value: -10, to: Date()) ?? Date()
        case .max:
            date = Calendar.current.date(from: DateComponents(year: 1970, month: 1, day: 1)) ?? Date()
        }
        
        return String(Int(date.timeIntervalSince1970))
    }
    
    private func periodEnd() -> String {
        return String(Int(Date().timeIntervalSince1970))
    }
    
    private func dateFromPeriod(_ period: YFPeriod) -> Date {
        let calendar = Calendar.current
        
        switch period {
        case .oneDay:
            return calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        case .oneWeek:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        case .oneMonth:
            return calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        case .twoYears:
            return calendar.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        case .fiveYears:
            return calendar.date(byAdding: .year, value: -5, to: Date()) ?? Date()
        case .tenYears:
            return calendar.date(byAdding: .year, value: -10, to: Date()) ?? Date()
        case .max:
            return Calendar.current.date(from: DateComponents(year: 1970, month: 1, day: 1)) ?? Date()
        }
    }
    
    private func convertToPrices(_ result: ChartResult) -> [YFPrice] {
        guard let quote = result.indicators.quote.first,
              let timestamps = result.timestamp else {
            return []
        }
        
        var prices: [YFPrice] = []
        
        for i in 0..<timestamps.count {
            guard i < quote.open.count,
                  i < quote.high.count,
                  i < quote.low.count,
                  i < quote.close.count,
                  i < quote.volume.count else {
                continue
            }
            
            let date = Date(timeIntervalSince1970: TimeInterval(timestamps[i]))
            let adjClose = (i < quote.adjclose.count) ? quote.adjclose[i] : quote.close[i]
            
            let price = YFPrice(
                date: date,
                open: quote.open[i],
                high: quote.high[i],
                low: quote.low[i],
                close: quote.close[i],
                adjClose: adjClose,
                volume: quote.volume[i]
            )
            
            prices.append(price)
        }
        
        return prices.sorted(by: { $0.date < $1.date })
    }
}

struct ChartResponse: Codable {
    let chart: Chart
}

struct Chart: Codable {
    let result: [ChartResult]
}

struct ChartResult: Codable {
    let meta: Meta
    let timestamp: [Int]?
    let indicators: Indicators
}

struct Meta: Codable {
    let symbol: String
    let regularMarketPrice: Double?
    let regularMarketTime: Int?
}

struct Indicators: Codable {
    let quote: [Quote]
}

struct Quote: Codable {
    let open: [Double]
    let high: [Double]
    let low: [Double]
    let close: [Double]
    let volume: [Int]
    let adjclose: [Double]
}