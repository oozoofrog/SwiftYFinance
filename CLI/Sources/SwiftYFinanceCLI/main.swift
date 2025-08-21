import Foundation
import SwiftYFinance
import ArgumentParser

@main
struct SwiftYFinanceCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftyfinance",
        abstract: "SwiftYFinance - Yahoo Finance API Client for Swift",
        version: "1.0.0",
        subcommands: [
            QuoteCommand.self,
            HistoryCommand.self,
            SearchCommand.self,
            FundamentalsCommand.self
        ],
        defaultSubcommand: QuoteCommand.self
    )
}

// MARK: - Quote Command

struct QuoteCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "quote",
        abstract: "Get real-time stock quote information"
    )
    
    @Argument(help: "Stock ticker symbol (e.g., AAPL, TSLA)")
    var symbol: String
    
    @Flag(name: .shortAndLong, help: "Enable debug output")
    var debug = false
    
    @Flag(name: .shortAndLong, help: "Output raw JSON response")
    var json = false
    
    func run() async throws {
        let client = YFClient(debugEnabled: debug)
        let ticker = YFTicker(symbol: symbol.uppercased())
        
        if debug && !json {
            print("🔍 Debug mode enabled")
            print("📊 Fetching quote for: \(ticker.symbol)")
        }
        
        do {
            if json {
                let rawData = try await client.quote.fetchRawJSON(ticker: ticker)
                print(formatJSONOutput(rawData))
            } else {
                let quote = try await client.quote.fetch(ticker: ticker)
                printQuoteInfo(quote)
            }
        } catch {
            if json {
                printJSONError("Failed to fetch quote", error: error)
            } else {
                printError("Failed to fetch quote", error: error)
            }
            throw ExitCode.failure
        }
    }
    
    private func printQuoteInfo(_ quote: YFQuote) {
        print("📈 \(quote.ticker.symbol) - \(quote.shortName)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Current price with change
        let change = quote.regularMarketPrice - quote.regularMarketPreviousClose
        let changePercent = (change / quote.regularMarketPreviousClose) * 100
        let changeSymbol = change >= 0 ? "🟢" : "🔴"
        let changeSign = change >= 0 ? "+" : ""
        
        print("Current Price:    $\(formatPrice(quote.regularMarketPrice))")
        print("Change:           \(changeSymbol) \(changeSign)$\(formatPrice(change)) (\(changeSign)\(formatPercent(changePercent))%)")
        print("Previous Close:   $\(formatPrice(quote.regularMarketPreviousClose))")
        print("")
        
        // Market data
        print("Open:             $\(formatPrice(quote.regularMarketOpen))")
        print("High:             $\(formatPrice(quote.regularMarketHigh))")
        print("Low:              $\(formatPrice(quote.regularMarketLow))")
        print("Volume:           \(formatVolume(quote.regularMarketVolume))")
        print("Market Cap:       $\(formatLargeNumber(quote.marketCap))")
        
        // After-hours trading if available
        if let postPrice = quote.postMarketPrice,
           let postTime = quote.postMarketTime,
           let postChangePercent = quote.postMarketChangePercent {
            print("")
            print("After Hours Trading:")
            print("Price:            $\(formatPrice(postPrice))")
            print("Change:           \(postChangePercent >= 0 ? "🟢 +" : "🔴 ")\(formatPercent(postChangePercent))%")
            print("Time:             \(formatTime(postTime))")
        }
        
        // Pre-market trading if available
        if let prePrice = quote.preMarketPrice,
           let preTime = quote.preMarketTime,
           let preChangePercent = quote.preMarketChangePercent {
            print("")
            print("Pre-Market Trading:")
            print("Price:            $\(formatPrice(prePrice))")
            print("Change:           \(preChangePercent >= 0 ? "🟢 +" : "🔴 ")\(formatPercent(preChangePercent))%")
            print("Time:             \(formatTime(preTime))")
        }
        
        print("")
        print("Last Updated:     \(formatTime(quote.regularMarketTime))")
    }
}

// MARK: - History Command

struct HistoryCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "history",
        abstract: "Get historical price data"
    )
    
    @Argument(help: "Stock ticker symbol")
    var symbol: String
    
    @Option(name: .shortAndLong, help: "Time period (1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, 10y, ytd, max)")
    var period: String = "1mo"
    
    @Flag(name: .shortAndLong, help: "Enable debug output")
    var debug = false
    
    @Flag(name: .shortAndLong, help: "Output raw JSON response")
    var json = false
    
    func run() async throws {
        let client = YFClient(debugEnabled: debug)
        let ticker = YFTicker(symbol: symbol.uppercased())
        
        guard let yfPeriod = parseYFPeriod(period) else {
            if json {
                printJSONError("Invalid period", error: YFError.invalidParameter("Invalid period: \(period)"))
            } else {
                print("❌ Invalid period: \(period)")
                print("Valid periods: 1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, 10y, ytd, max")
            }
            throw ExitCode.failure
        }
        
        if debug && !json {
            print("🔍 Debug mode enabled")
            print("📊 Fetching \(period) history for: \(ticker.symbol)")
        }
        
        do {
            if json {
                let rawData = try await client.history.fetchRawJSON(ticker: ticker, period: yfPeriod)
                print(formatJSONOutput(rawData))
            } else {
                let history = try await client.history.fetch(ticker: ticker, period: yfPeriod)
                printHistoryInfo(history, period: period)
            }
        } catch {
            if json {
                printJSONError("Failed to fetch history", error: error)
            } else {
                printError("Failed to fetch history", error: error)
            }
            throw ExitCode.failure
        }
    }
    
    private func printHistoryInfo(_ history: YFHistoricalData, period: String) {
        print("📈 \(history.ticker.symbol) - \(period.uppercased()) Historical Data")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Period:           \(formatDate(history.startDate)) to \(formatDate(history.endDate))")
        print("Total Days:       \(history.prices.count)")
        
        if !history.prices.isEmpty {
            let latest = history.prices.last!
            let earliest = history.prices.first!
            let totalReturn = ((latest.adjClose - earliest.adjClose) / earliest.adjClose) * 100
            let returnSymbol = totalReturn >= 0 ? "🟢" : "🔴"
            
            print("")
            print("Performance Summary:")
            print("Starting Price:   $\(formatPrice(earliest.adjClose))")
            print("Ending Price:     $\(formatPrice(latest.adjClose))")
            print("Total Return:     \(returnSymbol) \(formatPercent(totalReturn))%")
            
            // Show recent prices (last 5 days)
            print("")
            print("Recent Prices:")
            print("Date         Open      High      Low       Close     Volume")
            print("───────────────────────────────────────────────────────────")
            
            for price in history.prices.suffix(5) {
                print("\(formatDateShort(price.date))  $\(formatPriceShort(price.open))  $\(formatPriceShort(price.high))  $\(formatPriceShort(price.low))  $\(formatPriceShort(price.close))  \(formatVolumeShort(price.volume))")
            }
        }
    }
}

// MARK: - Search Command

struct SearchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search for stocks by company name"
    )
    
    @Argument(help: "Company name or ticker to search for")
    var query: String
    
    @Option(name: .shortAndLong, help: "Maximum number of results")
    var limit: Int = 10
    
    @Flag(name: .shortAndLong, help: "Enable debug output")
    var debug = false
    
    @Flag(name: .shortAndLong, help: "Output raw JSON response")
    var json = false
    
    func run() async throws {
        let client = YFClient(debugEnabled: debug)
        
        if debug && !json {
            print("🔍 Debug mode enabled")
            print("🔎 Searching for: \(query)")
        }
        
        do {
            if json {
                let rawData = try await client.search.findRawJSON(companyName: query)
                print(formatJSONOutput(rawData))
            } else {
                let results = try await client.search.find(companyName: query)
                printSearchResults(results, query: query, limit: limit)
            }
        } catch {
            if json {
                printJSONError("Failed to search", error: error)
            } else {
                printError("Failed to search", error: error)
            }
            throw ExitCode.failure
        }
    }
    
    private func printSearchResults(_ results: [YFSearchResult], query: String, limit: Int) {
        print("🔎 Search Results for '\(query)'")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        if results.isEmpty {
            print("No results found.")
            return
        }
        
        print("Found \(results.count) results (showing first \(min(limit, results.count))):")
        print("")
        print("Symbol    Type      Name")
        print("────────────────────────────────────────────────────────")
        
        for result in results.prefix(limit) {
            let typeIcon = getTypeIcon(result.quoteType)
            let shortName = String(result.shortName.prefix(40))
            print("\(result.symbol.padding(toLength: 8, withPad: " ", startingAt: 0))  \(typeIcon) \(result.quoteType.rawValue.padding(toLength: 6, withPad: " ", startingAt: 0))  \(shortName)")
        }
    }
}

// MARK: - Fundamentals Command

struct FundamentalsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "fundamentals",
        abstract: "Get fundamental financial data (unified API)"
    )
    
    @Argument(help: "Stock ticker symbol")
    var symbol: String
    
    @Flag(name: .shortAndLong, help: "Enable debug output")
    var debug = false
    
    @Flag(name: .shortAndLong, help: "Output raw JSON response")
    var json = false
    
    func run() async throws {
        let client = YFClient(debugEnabled: debug)
        let ticker = YFTicker(symbol: symbol.uppercased())
        
        if debug && !json {
            print("🔍 Debug mode enabled")
            print("📊 Fetching fundamentals for: \(ticker.symbol)")
        }
        
        do {
            if json {
                let rawData = try await client.fundamentals.fetchRawJSON(ticker: ticker)
                print(formatJSONOutput(rawData))
            } else {
                let fundamentals = try await client.fundamentals.fetch(ticker: ticker)
                printFundamentalsInfo(fundamentals, ticker: ticker)
            }
        } catch {
            if json {
                printJSONError("Failed to fetch fundamentals", error: error)
            } else {
                printError("Failed to fetch fundamentals", error: error)
            }
            throw ExitCode.failure
        }
    }
    
    private func printFundamentalsInfo(_ fundamentals: FundamentalsTimeseriesResponse, ticker: YFTicker) {
        print("💼 \(ticker.symbol) - Fundamental Data")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        guard let results = fundamentals.timeseries?.result, !results.isEmpty else {
            print("No fundamental data available.")
            return
        }
        
        print("Available Data Metrics:")
        var metricCount = 0
        
        for result in results {
            // Income Statement metrics
            if let revenue = result.annualTotalRevenue?.first?.reportedValue?.raw {
                print("📈 Total Revenue (Annual): $\(formatLargeNumber(revenue))")
                metricCount += 1
            }
            
            if let netIncome = result.annualNetIncome?.first?.reportedValue?.raw {
                print("💰 Net Income (Annual): $\(formatLargeNumber(netIncome))")
                metricCount += 1
            }
            
            // Balance Sheet metrics
            if let totalAssets = result.annualTotalAssets?.first?.reportedValue?.raw {
                print("🏢 Total Assets (Annual): $\(formatLargeNumber(totalAssets))")
                metricCount += 1
            }
            
            if let equity = result.annualTotalStockholderEquity?.first?.reportedValue?.raw {
                print("📊 Stockholder Equity (Annual): $\(formatLargeNumber(equity))")
                metricCount += 1
            }
            
            // Cash Flow metrics
            if let freeCashFlow = result.annualFreeCashFlow?.first?.reportedValue?.raw {
                print("💵 Free Cash Flow (Annual): $\(formatLargeNumber(freeCashFlow))")
                metricCount += 1
            }
            
            if let operatingCashFlow = result.annualOperatingCashFlow?.first?.reportedValue?.raw {
                print("🔄 Operating Cash Flow (Annual): $\(formatLargeNumber(operatingCashFlow))")
                metricCount += 1
            }
            
            break // Only show first result for summary
        }
        
        if metricCount == 0 {
            print("No key financial metrics available.")
        } else {
            print("")
            print("📋 Note: This is a summary view. \(metricCount) key metrics shown.")
            print("📡 Data from unified fundamentals-timeseries API")
        }
    }
}

// MARK: - Utility Functions

private func printError(_ message: String, error: Error) {
    print("❌ \(message)")
    
    if let yfError = error as? YFError {
        switch yfError {
        case .networkError:
            print("💡 Please check your internet connection.")
        case .apiError(let apiMessage):
            print("💡 API Error: \(apiMessage)")
        case .invalidRequest:
            print("💡 Please check if the ticker symbol is valid.")
        default:
            print("💡 Please try again later.")
        }
    } else {
        print("💡 \(error.localizedDescription)")
    }
}

private func parseYFPeriod(_ periodString: String) -> YFPeriod? {
    switch periodString.lowercased() {
    case "1d": return .oneDay
    case "5d": return .oneWeek
    case "1mo": return .oneMonth
    case "3mo": return .threeMonths
    case "6mo": return .sixMonths
    case "1y": return .oneYear
    case "2y": return .twoYears
    case "5y": return .fiveYears
    case "10y": return .tenYears
    case "max": return .max
    default: return nil
    }
}

private func getTypeIcon(_ type: YFQuoteType) -> String {
    switch type {
    case .equity: return "📈"
    case .etf: return "📊"
    case .mutualFund: return "🏦"
    case .index: return "📉"
    case .future: return "⚡"
    case .currency: return "💱"
    case .cryptocurrency: return "₿"
    default: return "📋"
    }
}

// MARK: - Formatting Functions

private func formatPrice(_ price: Double) -> String {
    return String(format: "%.2f", price)
}

private func formatPriceShort(_ price: Double) -> String {
    return String(format: "%6.2f", price)
}

private func formatPercent(_ percent: Double) -> String {
    return String(format: "%.2f", percent)
}

private func formatLargeNumber(_ number: Double) -> String {
    if number >= 1_000_000_000_000 {
        return String(format: "%.1fT", number / 1_000_000_000_000)
    } else if number >= 1_000_000_000 {
        return String(format: "%.1fB", number / 1_000_000_000)
    } else if number >= 1_000_000 {
        return String(format: "%.1fM", number / 1_000_000)
    } else if number >= 1_000 {
        return String(format: "%.1fK", number / 1_000)
    } else {
        return String(format: "%.0f", number)
    }
}

private func formatVolume(_ volume: Int) -> String {
    return Double(volume).formatted(.number.notation(.compactName))
}

private func formatVolumeShort(_ volume: Int) -> String {
    if volume >= 1_000_000 {
        return String(format: "%5.1fM", Double(volume) / 1_000_000)
    } else if volume >= 1_000 {
        return String(format: "%5.1fK", Double(volume) / 1_000)
    } else {
        return String(format: "%7d", volume)
    }
}

private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}

private func formatDateShort(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd/yy"
    return formatter.string(from: date)
}

// MARK: - JSON Output Functions

/// JSON 출력을 위한 헬퍼 함수
///
/// 원본 JSON 데이터를 보기 좋게 포맷하여 출력합니다.
///
/// - Parameter data: 원본 JSON 데이터
/// - Returns: 포맷된 JSON 문자열
private func formatJSONOutput(_ data: Data) -> String {
    do {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
        return String(data: prettyData, encoding: .utf8) ?? String(data: data, encoding: .utf8) ?? "Invalid JSON"
    } catch {
        // JSON 파싱이 실패하면 원본 문자열 반환
        return String(data: data, encoding: .utf8) ?? "Invalid data"
    }
}

/// JSON 형식으로 에러를 출력합니다
///
/// - Parameters:
///   - message: 에러 메시지
///   - error: 발생한 에러
private func printJSONError(_ message: String, error: Error) {
    let errorDict: [String: Any] = [
        "error": true,
        "message": message,
        "details": error.localizedDescription,
        "type": String(describing: type(of: error))
    ]
    
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: errorDict, options: [.prettyPrinted])
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        } else {
            print("{\"error\": true, \"message\": \"\(message)\", \"details\": \"\(error.localizedDescription)\"}")
        }
    } catch {
        print("{\"error\": true, \"message\": \"\(message)\", \"details\": \"\(error.localizedDescription)\"}")
    }
}