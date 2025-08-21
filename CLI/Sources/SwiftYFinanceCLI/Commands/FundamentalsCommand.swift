import Foundation
import SwiftYFinance
import ArgumentParser

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