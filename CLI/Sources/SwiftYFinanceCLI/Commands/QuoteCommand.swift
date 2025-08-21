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