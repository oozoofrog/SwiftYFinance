import Foundation
import SwiftYFinance
import ArgumentParser

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