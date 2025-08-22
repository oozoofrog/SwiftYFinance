import Foundation
import SwiftYFinance
import ArgumentParser

struct OptionsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "options",
        abstract: "Get options chain data for stock ticker symbols"
    )
    
    @Argument(help: "Stock ticker symbol (e.g., AAPL, TSLA)")
    var symbol: String
    
    @Option(name: .shortAndLong, help: "Specific expiration date (format: YYYY-MM-DD)")
    var expiration: String?
    
    @Flag(name: .shortAndLong, help: "Enable debug output")
    var debug = false
    
    @Flag(name: .shortAndLong, help: "Output raw JSON response")
    var json = false
    
    func run() async throws {
        let client = YFClient(debugEnabled: debug)
        let ticker = YFTicker(symbol: symbol.uppercased())
        
        if debug && !json {
            print("🔍 Debug mode enabled")
            print("📊 Fetching options chain for: \(ticker.symbol)")
            if let exp = expiration {
                print("📅 Expiration filter: \(exp)")
            }
        }
        
        do {
            // Parse expiration date if provided
            var expirationDate: Date?
            if let exp = expiration {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.timeZone = TimeZone(abbreviation: "EST")
                guard let date = formatter.date(from: exp) else {
                    if !json {
                        print("❌ Invalid date format. Please use YYYY-MM-DD")
                    }
                    throw ExitCode.failure
                }
                expirationDate = date
            }
            
            if json {
                let rawData = try await client.options.fetchRawJSON(for: ticker, expiration: expirationDate)
                print(formatJSONOutput(rawData))
            } else {
                let options = try await client.options.fetchOptionsChain(for: ticker, expiration: expirationDate)
                printOptionsInfo(options, for: ticker.symbol)
            }
        } catch {
            if json {
                printJSONError("Failed to fetch options chain", error: error)
            } else {
                printError("Failed to fetch options chain", error: error)
            }
            throw ExitCode.failure
        }
    }
    
    private func printOptionsInfo(_ options: YFOptionsChainResult, for symbol: String) {
        print("📊 Options Chain for \(symbol)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        
        // Quote information
        if let quote = options.quote {
            print("📈 Current Price")
            if let quotedSymbol = quote.symbol {
                print("  Symbol: \(quotedSymbol)")
            }
            if let price = quote.regularMarketPrice {
                print("  Price: $\(String(format: "%.2f", price))")
            }
            if let currency = quote.currency {
                print("  Currency: \(currency)")
            }
            print("")
        }
        
        // Expiration dates
        print("📅 Available Expiration Dates")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(abbreviation: "EST")
        
        if let expirationTimestamps = options.expirationDates {
            let expirationDates = expirationTimestamps.map { Date(timeIntervalSince1970: TimeInterval($0)) }
            for (index, date) in expirationDates.prefix(10).enumerated() {
                print("  [\(index + 1)] \(dateFormatter.string(from: date))")
            }
            if expirationDates.count > 10 {
                print("  ... and \(expirationDates.count - 10) more")
            }
        }
        print("")
        
        // Strike prices
        print("💰 Available Strike Prices")
        if let strikes = options.strikes {
            let sortedStrikes = strikes.sorted()
            if sortedStrikes.count > 20 {
                let minStrike = sortedStrikes.first ?? 0
            let maxStrike = strikes.last ?? 0
            print("  Range: $\(String(format: "%.2f", minStrike)) - $\(String(format: "%.2f", maxStrike))")
            print("  Total: \(strikes.count) strikes")
        } else {
            for strike in strikes {
                print("  $\(String(format: "%.2f", strike))")
            }
        }
        print("")
        
        // Options data summary
        if !options.options.isEmpty {
            print("📊 Options Data")
            for optionData in options.options.prefix(3) {
                let expDateStr = dateFormatter.string(from: optionData.expirationDate)
                print("\n  Expiration: \(expDateStr)")
                print("  ├─ Calls: \(optionData.calls.count) contracts")
                print("  └─ Puts: \(optionData.puts.count) contracts")
                
                // Show sample call
                if let firstCall = optionData.calls.first {
                    print("\n    Sample Call:")
                    print("    ├─ Strike: $\(String(format: "%.2f", firstCall.strike))")
                    print("    ├─ Last Price: $\(String(format: "%.2f", firstCall.lastPrice))")
                    if let bid = firstCall.bid, let ask = firstCall.ask {
                        print("    ├─ Bid/Ask: $\(String(format: "%.2f", bid)) / $\(String(format: "%.2f", ask))")
                    }
                    if let volume = firstCall.volume {
                        print("    ├─ Volume: \(volume)")
                    }
                    print("    └─ Open Interest: \(firstCall.openInterest)")
                }
                
                // Show sample put
                if let firstPut = optionData.puts.first {
                    print("\n    Sample Put:")
                    print("    ├─ Strike: $\(String(format: "%.2f", firstPut.strike))")
                    print("    ├─ Last Price: $\(String(format: "%.2f", firstPut.lastPrice))")
                    if let bid = firstPut.bid, let ask = firstPut.ask {
                        print("    ├─ Bid/Ask: $\(String(format: "%.2f", bid)) / $\(String(format: "%.2f", ask))")
                    }
                    if let volume = firstPut.volume {
                        print("    ├─ Volume: \(volume)")
                    }
                    print("    └─ Open Interest: \(firstPut.openInterest)")
                }
            }
            
            if options.options.count > 3 {
                print("\n  ... and \(options.options.count - 3) more expiration dates")
            }
        }
        
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Mini Options: \(options.hasMiniOptions ? "Yes" : "No")")
        print("Total Expirations: \(options.expirationDates.count)")
        print("Total Strikes: \(options.strikes.count)")
    }
}