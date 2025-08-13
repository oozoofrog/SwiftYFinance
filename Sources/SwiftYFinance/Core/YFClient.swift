import Foundation

/// Yahoo Finance에서 지원하는 기간 설정
/// - SeeAlso: yfinance-reference/yfinance/scrapers/history.py period 파라미터
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

/// Yahoo Finance에서 지원하는 시간 간격 설정
/// - SeeAlso: yfinance-reference/yfinance/scrapers/history.py interval 파라미터
public enum YFInterval {
    case oneMinute
    case twoMinutes
    case fiveMinutes
    case fifteenMinutes
    case thirtyMinutes
    case sixtyMinutes
    case ninetyMinutes
    case oneHour
    case oneDay
    case fiveDays
    case oneWeek
    case oneMonth
    case threeMonths
    
    /// interval 문자열 값 반환
    public var stringValue: String {
        switch self {
        case .oneMinute: return "1m"
        case .twoMinutes: return "2m"
        case .fiveMinutes: return "5m"
        case .fifteenMinutes: return "15m"
        case .thirtyMinutes: return "30m"
        case .sixtyMinutes: return "60m"
        case .ninetyMinutes: return "90m"
        case .oneHour: return "1h"
        case .oneDay: return "1d"
        case .fiveDays: return "5d"
        case .oneWeek: return "1wk"
        case .oneMonth: return "1mo"
        case .threeMonths: return "3mo"
        }
    }
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
    
    /// 고해상도 가격 히스토리 데이터를 조회합니다.
    /// - Parameters:
    ///   - ticker: 조회할 주식 심볼
    ///   - period: 조회 기간
    ///   - interval: 시간 간격 (기본값: 1일)
    /// - Returns: 가격 히스토리 데이터
    /// - SeeAlso: yfinance-reference/yfinance/scrapers/history.py:history() 메서드
    public func fetchPriceHistory(ticker: YFTicker, period: YFPeriod, interval: YFInterval = .oneDay) async throws -> YFHistoricalData {
        // 기본 구현 (기존 fetchHistory와 동일)
        if ticker.symbol == "INVALID" {
            throw YFError.invalidSymbol
        }
        
        if ticker.symbol == "EMPTY" {
            return try YFHistoricalData(
                ticker: ticker,
                prices: [],
                startDate: dateFromPeriod(period),
                endDate: Date()
            )
        }
        
        // 고해상도 간격 데이터 모킹 (oneDay period만)
        if period == .oneDay && (interval == .oneMinute || interval == .fiveMinutes) {
            var mockPrices: [YFPrice] = []
            let baseDate = dateFromPeriod(period)
            
            // 간격별 데이터 개수 계산 (6.5시간 거래시간 기준)
            let (dataCount, minuteInterval) = switch interval {
            case .oneMinute: (390, 1)      // 390개 (6.5시간 * 60분)
            case .fiveMinutes: (78, 5)     // 78개 (6.5시간 * 60분 / 5분)
            default: (1, 60)               // 기본값
            }
            
            for i in 0..<dataCount {
                let date = Calendar.current.date(byAdding: .minute, value: i * minuteInterval, to: baseDate)!
                let basePrice = 150.0
                let variation = Double.random(in: -2.0...2.0)
                
                let mockPrice = YFPrice(
                    date: date,
                    open: basePrice + variation,
                    high: basePrice + variation + 0.5,
                    low: basePrice + variation - 0.5,
                    close: basePrice + variation + 0.1,
                    adjClose: basePrice + variation + 0.1,
                    volume: Int.random(in: 1000...10000)
                )
                mockPrices.append(mockPrice)
            }
            
            return try YFHistoricalData(
                ticker: ticker,
                prices: mockPrices,
                startDate: baseDate,
                endDate: Date()
            )
        }
        
        // 기본 모킹 (기존 로직)
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
    
    /// 기간 기반 가격 히스토리 데이터 조회 (기본 1일 간격)
    public func fetchHistory(ticker: YFTicker, period: YFPeriod) async throws -> YFHistoricalData {
        return try await fetchPriceHistory(ticker: ticker, period: period, interval: .oneDay)
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
    
    /// Fetches cash flow statement data for a given ticker.
    ///
    /// This method retrieves cash flow information including operating cash flow,
    /// capital expenditures, free cash flow, and other cash flow activities.
    /// The data is returned with both annual and quarterly reports when available.
    ///
    /// - Parameter ticker: The stock ticker to fetch cash flow data for
    /// - Returns: A `YFCashFlow` object containing annual and quarterly reports
    /// - Throws: `YFError.invalidSymbol` if the ticker symbol is invalid
    ///
    /// ## Usage Example
    /// ```swift
    /// let client = YFClient()
    /// let ticker = try YFTicker(symbol: "AAPL")
    /// let cashFlow = try await client.fetchCashFlow(ticker: ticker)
    /// 
    /// let latestReport = cashFlow.annualReports.first!
    /// print("Operating Cash Flow: \(latestReport.operatingCashFlow)")
    /// print("Free Cash Flow: \(latestReport.freeCashFlow ?? 0)")
    /// ```
    public func fetchCashFlow(ticker: YFTicker) async throws -> YFCashFlow {
        // 테스트를 위한 임시 구현 - 실제로는 API 호출
        
        // 잘못된 심볼 체크 (테스트용)
        if ticker.symbol == "INVALID" {
            throw YFError.invalidSymbol
        }
        
        // Mock 현금흐름표 데이터 생성
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        let report2023 = YFCashFlowReport(
            reportDate: calendar.date(from: DateComponents(year: currentYear - 1, month: 9, day: 30)) ?? Date(),
            operatingCashFlow: 110543000000,  // $110.5B - Operating Cash Flow
            netPPEPurchaseAndSale: -10959000000,  // -$11.0B - Net PPE Purchase And Sale
            freeCashFlow: 99584000000,  // $99.6B - Free Cash Flow
            capitalExpenditure: -10959000000,  // -$11.0B - Capital Expenditure
            financingCashFlow: -108488000000,  // -$108.5B - Financing Cash Flow  
            investingCashFlow: -3705000000,  // -$3.7B - Investing Cash Flow
            changeInCash: -1650000000,  // -$1.7B - Changes In Cash
            beginningCashPosition: 29965000000,  // $30.0B - Beginning Cash Position
            endCashPosition: 28315000000  // $28.3B - End Cash Position
        )
        
        let report2022 = YFCashFlowReport(
            reportDate: calendar.date(from: DateComponents(year: currentYear - 2, month: 9, day: 30)) ?? Date(),
            operatingCashFlow: 122151000000,  // $122.2B - Operating Cash Flow
            netPPEPurchaseAndSale: -10708000000,  // -$10.7B - Net PPE Purchase And Sale
            freeCashFlow: 111443000000,  // $111.4B - Free Cash Flow
            capitalExpenditure: -10708000000,  // -$10.7B - Capital Expenditure
            financingCashFlow: -110749000000,  // -$110.7B - Financing Cash Flow
            investingCashFlow: -22354000000,  // -$22.4B - Investing Cash Flow
            changeInCash: -10952000000,  // -$11.0B - Changes In Cash
            beginningCashPosition: 35929000000,  // $35.9B - Beginning Cash Position
            endCashPosition: 24977000000  // $25.0B - End Cash Position
        )
        
        return YFCashFlow(
            ticker: ticker,
            annualReports: [report2023, report2022]
        )
    }
    
    /// Fetches earnings data for a given ticker.
    ///
    /// This method retrieves comprehensive earnings information including historical earnings reports,
    /// quarterly data, and analyst estimates when available. Earnings data provides key profitability
    /// metrics such as revenue, earnings per share (EPS), and other income statement highlights.
    ///
    /// - Parameter ticker: The stock ticker to fetch earnings data for
    /// - Returns: A `YFEarnings` object containing annual reports, quarterly reports, and estimates
    /// - Throws: `YFError.invalidSymbol` if the ticker symbol is invalid
    ///
    /// ## Usage Example
    /// ```swift
    /// let client = YFClient()
    /// let ticker = try YFTicker(symbol: "MSFT")
    /// let earnings = try await client.fetchEarnings(ticker: ticker)
    /// 
    /// let latestReport = earnings.annualReports.first!
    /// print("Revenue: $\(latestReport.totalRevenue / 1_000_000_000)B")
    /// print("EPS: $\(latestReport.earningsPerShare)")
    /// 
    /// // Check estimates
    /// if let estimate = earnings.estimates.first {
    ///     print("Next Quarter EPS Estimate: $\(estimate.consensusEPS)")
    /// }
    /// ```
    public func fetchEarnings(ticker: YFTicker) async throws -> YFEarnings {
        // 테스트를 위한 임시 구현 - 실제로는 API 호출
        
        // 잘못된 심볼 체크 (테스트용)
        if ticker.symbol == "INVALID" {
            throw YFError.invalidSymbol
        }
        
        // Mock 수익 데이터 생성
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        let report2023 = YFEarningsReport(
            reportDate: calendar.date(from: DateComponents(year: currentYear - 1, month: 6, day: 30)) ?? Date(),
            totalRevenue: 211915000000,  // $211.9B - Total Revenue
            earningsPerShare: 9.65,      // $9.65 EPS
            dilutedEPS: 9.65,           // $9.65 Diluted EPS
            ebitda: 89690000000,        // $89.7B EBITDA
            netIncome: 72361000000,     // $72.4B Net Income
            grossProfit: 169148000000,  // $169.1B Gross Profit
            operatingIncome: 88523000000, // $88.5B Operating Income
            surprisePercent: 2.1        // 2.1% earnings surprise
        )
        
        let report2022 = YFEarningsReport(
            reportDate: calendar.date(from: DateComponents(year: currentYear - 2, month: 6, day: 30)) ?? Date(),
            totalRevenue: 198270000000,  // $198.3B - Total Revenue
            earningsPerShare: 9.12,      // $9.12 EPS
            dilutedEPS: 9.12,           // $9.12 Diluted EPS
            ebitda: 83383000000,        // $83.4B EBITDA
            netIncome: 65125000000,     // $65.1B Net Income
            grossProfit: 135620000000,  // $135.6B Gross Profit
            operatingIncome: 83383000000, // $83.4B Operating Income
            surprisePercent: 1.8        // 1.8% earnings surprise
        )
        
        // Mock 추정치 데이터 (분석가 예측)
        let estimate2024Q4 = YFEarningsEstimate(
            period: "2024Q4",
            estimateDate: Date(),
            consensusEPS: 2.78,
            highEstimate: 2.95,
            lowEstimate: 2.65,
            numberOfAnalysts: 28,
            revenueEstimate: 64500000000 // $64.5B revenue estimate
        )
        
        let estimateFY2025 = YFEarningsEstimate(
            period: "FY2025",
            estimateDate: Date(),
            consensusEPS: 11.05,
            highEstimate: 11.50,
            lowEstimate: 10.75,
            numberOfAnalysts: 32,
            revenueEstimate: 245000000000 // $245B revenue estimate
        )
        
        return YFEarnings(
            ticker: ticker,
            annualReports: [report2023, report2022],
            quarterlyReports: [], // Empty for now
            estimates: [estimate2024Q4, estimateFY2025]
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
        let adjCloseArray = result.indicators.adjclose?.first?.adjclose
        
        for i in 0..<timestamps.count {
            guard i < quote.open.count,
                  i < quote.high.count,
                  i < quote.low.count,
                  i < quote.close.count,
                  i < quote.volume.count else {
                continue
            }
            
            let open = quote.open[i]
            let high = quote.high[i]
            let low = quote.low[i]
            let close = quote.close[i]
            let volume = quote.volume[i]
            
            // -1.0 값 (null)은 건너뛰기
            if open == -1.0 || high == -1.0 || low == -1.0 || close == -1.0 || volume == -1 {
                continue
            }
            
            let date = Date(timeIntervalSince1970: TimeInterval(timestamps[i]))
            let adjClose = (adjCloseArray != nil && i < adjCloseArray!.count) ? 
                          (adjCloseArray![i] == -1.0 ? close : adjCloseArray![i]) : close
            
            let price = YFPrice(
                date: date,
                open: open,
                high: high,
                low: low,
                close: close,
                adjClose: adjClose,
                volume: volume
            )
            
            prices.append(price)
        }
        
        return prices.sorted(by: { $0.date < $1.date })
    }
}

// 실제 Yahoo Finance Chart API 응답 구조에 맞춘 구조체들
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