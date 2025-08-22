import Foundation
import SwiftYFinance
import ArgumentParser

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
        let symbol = quote.symbol ?? "N/A"
        let shortName = quote.shortName ?? "Unknown"
        
        print("📈 \(symbol) - \(shortName)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Current price with change
        let currentPrice = quote.regularMarketPrice ?? 0
        let previousClose = quote.regularMarketPreviousClose ?? 0
        let change = currentPrice - previousClose
        let changePercent = previousClose > 0 ? (change / previousClose) * 100 : 0
        let changeSymbol = change >= 0 ? "🟢" : "🔴"
        let changeSign = change >= 0 ? "+" : ""
        
        print("Current Price:    $\(formatPrice(currentPrice))")
        print("Change:           \(changeSymbol) \(changeSign)$\(formatPrice(change)) (\(changeSign)\(formatPercent(changePercent))%)")
        print("Previous Close:   $\(formatPrice(previousClose))")
        print("")
        
        // Market data
        print("Open:             $\(formatPrice(quote.regularMarketOpen ?? 0))")
        print("High:             $\(formatPrice(quote.regularMarketDayHigh ?? 0))")
        print("Low:              $\(formatPrice(quote.regularMarketDayLow ?? 0))")
        print("Volume:           \(formatVolume(quote.regularMarketVolume ?? 0))")
        print("Market Cap:       $\(formatLargeNumber(quote.marketCap ?? 0))")
        
        // After-hours trading if available
        if let postPrice = quote.postMarketPrice,
           let postTimeStamp = quote.postMarketTime,
           let postChangePercent = quote.postMarketChangePercent {
            print("")
            print("After Hours Trading:")
            print("Price:            $\(formatPrice(postPrice))")
            print("Change:           \(postChangePercent >= 0 ? "🟢 +" : "🔴 ")\(formatPercent(postChangePercent))%")
            print("Time:             \(formatTime(Date(timeIntervalSince1970: TimeInterval(postTimeStamp))))")
        }
        
        // Pre-market trading if available
        if let prePrice = quote.preMarketPrice,
           let preTimeStamp = quote.preMarketTime,
           let preChangePercent = quote.preMarketChangePercent {
            print("")
            print("Pre-Market Trading:")
            print("Price:            $\(formatPrice(prePrice))")
            print("Change:           \(preChangePercent >= 0 ? "🟢 +" : "🔴 ")\(formatPercent(preChangePercent))%")
            print("Time:             \(formatTime(Date(timeIntervalSince1970: TimeInterval(preTimeStamp))))")
        }
        
        print("")
        if let timeStamp = quote.regularMarketTime {
            print("Last Updated:     \(formatTime(Date(timeIntervalSince1970: TimeInterval(timeStamp))))")
        }
    }
}