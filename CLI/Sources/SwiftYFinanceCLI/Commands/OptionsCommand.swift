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
            if json {
                let rawData = try await client.options.fetchRawJSON(for: ticker)
                print(formatJSONOutput(rawData))
            } else {
                let options = try await client.options.fetchOptionsChain(for: ticker)
                printOptionsInfo(options)
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
    
    private func printOptionsInfo(_ options: YFOptionsChainResult) {
        let symbol = options.underlyingSymbol ?? self.symbol.uppercased()
        
        print("⚡ \(symbol) - Options Chain")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Show available expiration dates (first few)
        if let expirationDates = options.expirationDates, !expirationDates.isEmpty {
            print("\n📅 Available Expiration Dates:")
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            
            for (index, timestamp) in expirationDates.prefix(3).enumerated() {
                let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
                let dateStr = dateFormatter.string(from: date)
                print("  \(index + 1). \(dateStr)")
            }
            
            if expirationDates.count > 3 {
                print("  ... and \(expirationDates.count - 3) more expiration dates")
            }
        }
        
        // Show option chain data for first expiration
        if let optionsData = options.options, !optionsData.isEmpty {
            let firstOption = optionsData[0]
            
            print("\n📊 Option Chain - \(Date(timeIntervalSince1970: TimeInterval(firstOption.expirationDate ?? 0)))")
            
            // Show calls
            if let calls = firstOption.calls, !calls.isEmpty {
                print("\n📞 Call Options (first 5):")
                print("Strike    Last    Bid     Ask     Volume  Impl Vol")
                print("─────────────────────────────────────────────────────")
                
                for call in calls.prefix(5) {
                    let strike = call.strike ?? 0
                    let lastPrice = call.lastPrice ?? 0
                    let bid = call.bid ?? 0
                    let ask = call.ask ?? 0
                    let volume = call.volume ?? 0
                    let impliedVol = (call.impliedVolatility ?? 0) * 100
                    
                    print(String(format: "$%-7.2f $%-5.2f $%-6.2f $%-6.2f %-7d %.1f%%", 
                                strike, lastPrice, bid, ask, volume, impliedVol))
                }
            }
            
            // Show puts
            if let puts = firstOption.puts, !puts.isEmpty {
                print("\n📉 Put Options (first 5):")
                print("Strike    Last    Bid     Ask     Volume  Impl Vol")
                print("─────────────────────────────────────────────────────")
                
                for put in puts.prefix(5) {
                    let strike = put.strike ?? 0
                    let lastPrice = put.lastPrice ?? 0
                    let bid = put.bid ?? 0
                    let ask = put.ask ?? 0
                    let volume = put.volume ?? 0
                    let impliedVol = (put.impliedVolatility ?? 0) * 100
                    
                    print(String(format: "$%-7.2f $%-5.2f $%-6.2f $%-6.2f %-7d %.1f%%", 
                                strike, lastPrice, bid, ask, volume, impliedVol))
                }
            }
        }
        
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("Mini Options: \(options.hasMiniOptions ?? false ? "Yes" : "No")")
        print("Total Expirations: \(options.expirationDates?.count ?? 0)")
        print("Total Strikes: \(options.strikes?.count ?? 0)")
    }
}