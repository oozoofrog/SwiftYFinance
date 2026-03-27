import Foundation
import SwiftYFinance
import ArgumentParser

struct QuoteSummaryCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "quotesummary",
        abstract: "Get comprehensive company information and financial data"
    )
    
    @Argument(help: "Stock ticker symbol (e.g., AAPL, TSLA)")
    var symbol: String
    
    @Option(name: .shortAndLong, help: "Type of quote summary data to fetch")
    var type: QuoteSummaryType = .essential
    
    @Flag(help: "Fetch quarterly financials (when using financials type)")
    var quarterly = false
    
    @Flag(name: .shortAndLong, help: "Enable debug output")
    var debug = false

    @Flag(name: .shortAndLong, help: "Output raw JSON response")
    var json = false

    /// 이모지 없이 ASCII 대체 문자로 출력 (CI/파이프라인 환경)
    @Flag(name: .customLong("no-emoji"), help: "이모지 없이 ASCII 대체 문자로 출력합니다")
    var noEmoji = false

    func run() async throws {
        let client = YFClient(debugEnabled: debug)
        let ticker = YFTicker(symbol: symbol.uppercased())
        let style = OutputStyle(noEmoji: noEmoji)

        if debug && !json {
            print("\(style.search) Debug mode enabled")
            print("\(style.chart) Fetching \(type) quote summary for: \(ticker.symbol)")
        }

        do {
            if json {
                let rawData = try await fetchRawJSON(client: client, ticker: ticker)
                print(formatJSONOutput(rawData))
            } else {
                let quoteSummary = try await fetchQuoteSummary(client: client, ticker: ticker)
                printQuoteSummaryInfo(quoteSummary, style: style)
            }
        } catch {
            if json {
                printJSONError("Failed to fetch quote summary", error: error)
            } else {
                printError("Failed to fetch quote summary", error: error)
            }
            throw ExitCode.failure
        }
    }
    
    private func fetchQuoteSummary(client: YFClient, ticker: YFTicker) async throws -> YFQuoteSummary {
        switch type {
        case .essential:
            return try await client.quoteSummary.fetchEssential(ticker: ticker)
        case .comprehensive:
            return try await client.quoteSummary.fetchComprehensive(ticker: ticker)
        case .company:
            return try await client.quoteSummary.fetchCompanyInfo(ticker: ticker)
        case .price:
            return try await client.quoteSummary.fetchPriceInfo(ticker: ticker)
        case .financials:
            return try await client.quoteSummary.fetchFinancials(ticker: ticker, quarterly: quarterly)
        case .earnings:
            return try await client.quoteSummary.fetchEarnings(ticker: ticker)
        case .ownership:
            return try await client.quoteSummary.fetchOwnership(ticker: ticker)
        case .analyst:
            return try await client.quoteSummary.fetchAnalystData(ticker: ticker)
        }
    }
    
    private func fetchRawJSON(client: YFClient, ticker: YFTicker) async throws -> Data {
        switch type {
        case .essential:
            return try await client.quoteSummary.fetchEssentialRawJSON(ticker: ticker)
        case .comprehensive:
            return try await client.quoteSummary.fetchComprehensiveRawJSON(ticker: ticker)
        case .company:
            let modules = YFQuoteSummaryModule.companyInfo
            return try await client.quoteSummary.fetchRawJSON(ticker: ticker, modules: modules)
        case .price:
            let modules = YFQuoteSummaryModule.priceInfo
            return try await client.quoteSummary.fetchRawJSON(ticker: ticker, modules: modules)
        case .financials:
            let modules = quarterly ? YFQuoteSummaryModule.allFinancials : YFQuoteSummaryModule.annualFinancials
            return try await client.quoteSummary.fetchRawJSON(ticker: ticker, modules: modules)
        case .earnings:
            let modules = YFQuoteSummaryModule.earningsData
            return try await client.quoteSummary.fetchRawJSON(ticker: ticker, modules: modules)
        case .ownership:
            let modules = YFQuoteSummaryModule.ownershipData
            return try await client.quoteSummary.fetchRawJSON(ticker: ticker, modules: modules)
        case .analyst:
            let modules = YFQuoteSummaryModule.analystData
            return try await client.quoteSummary.fetchRawJSON(ticker: ticker, modules: modules)
        }
    }
    
    private func printQuoteSummaryInfo(_ quoteSummary: YFQuoteSummary, style: OutputStyle) {
        guard let result = quoteSummary.result?.first else {
            print("\(style.error) No data available for \(symbol)")
            return
        }

        // 기본 기업 정보 — YFQuoteResult.price는 YFQuote 타입 (모듈형 구조체)
        let symbolStr = result.price?.basicInfo.symbol ?? self.symbol.uppercased()
        let shortName = result.price?.basicInfo.shortName ?? "Unknown Company"

        print("\(style.company) \(symbolStr) - \(shortName)")
        print(style.separator)

        // 가격 정보 (존재 시)
        if let price = result.price {
            let currentPrice = price.marketData.regularMarketPrice ?? 0
            let previousClose = price.marketData.regularMarketPreviousClose ?? 0
            let change = currentPrice - previousClose
            let changePercent = previousClose > 0 ? (change / previousClose) * 100 : 0
            let changeSymbol = style.changeIcon(change: change)
            let changeSign = change >= 0 ? "+" : ""

            print("Current Price:    $\(formatPrice(currentPrice))")
            print("Change:           \(changeSymbol) \(changeSign)$\(formatPrice(change)) (\(changeSign)\(formatPercent(changePercent))%)")
            print("Previous Close:   $\(formatPrice(previousClose))")
            print("")
            print("Open:             $\(formatPrice(price.marketData.regularMarketOpen ?? 0))")
            print("High:             $\(formatPrice(price.marketData.regularMarketDayHigh ?? 0))")
            print("Low:              $\(formatPrice(price.marketData.regularMarketDayLow ?? 0))")
            print("Volume:           \(formatVolume(price.volumeInfo.regularMarketVolume ?? 0))")
            print("Market Cap:       $\(formatLargeNumber(price.volumeInfo.marketCap ?? 0))")
        }

        print("")
        print("\(style.chart) Quote Summary Data Type: \(type)")
        print("\(style.clock) Retrieved at: \(formatTime(Date()))")
    }
}

enum QuoteSummaryType: String, CaseIterable, ExpressibleByArgument {
    case essential = "essential"
    case comprehensive = "comprehensive"
    case company = "company"
    case price = "price"
    case financials = "financials"
    case earnings = "earnings"
    case ownership = "ownership"
    case analyst = "analyst"
    
    var defaultValueDescription: String {
        switch self {
        case .essential: return "Essential information (default)"
        case .comprehensive: return "Comprehensive analysis data"
        case .company: return "Company profile and information"
        case .price: return "Price and market data"
        case .financials: return "Financial statements"
        case .earnings: return "Earnings data and history"
        case .ownership: return "Ownership information"
        case .analyst: return "Analyst recommendations"
        }
    }
}