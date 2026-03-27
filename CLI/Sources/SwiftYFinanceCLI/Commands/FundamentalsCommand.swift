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

    /// 이모지 없이 ASCII 대체 문자로 출력 (CI/파이프라인 환경)
    @Flag(name: .customLong("no-emoji"), help: "이모지 없이 ASCII 대체 문자로 출력합니다")
    var noEmoji = false

    func run() async throws {
        let client = YFClient(debugEnabled: debug)
        let ticker = YFTicker(symbol: symbol.uppercased())
        let style = OutputStyle(noEmoji: noEmoji)

        if debug && !json {
            print("\(style.search) Debug mode enabled")
            print("\(style.chart) Fetching fundamentals for: \(ticker.symbol)")
        }

        do {
            if json {
                let rawData = try await client.fundamentalsTimeseries.fetchRawJSON(ticker: ticker)
                print(formatJSONOutput(rawData))
            } else {
                let fundamentals = try await client.fundamentalsTimeseries.fetch(ticker: ticker)
                printFundamentalsInfo(fundamentals, ticker: ticker, style: style)
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

    private func printFundamentalsInfo(_ fundamentals: FundamentalsTimeseriesResponse, ticker: YFTicker, style: OutputStyle) {
        print("[FUND] \(ticker.symbol) - Fundamental Data")
        print(style.separator)

        guard let results = fundamentals.timeseries?.result, !results.isEmpty else {
            print("No fundamental data available.")
            return
        }

        print("Available Data Metrics:")
        var metricCount = 0

        for result in results {
            // 손익계산서
            if let revenue = result.annualTotalRevenue?.first?.reportedValue?.raw {
                print("\(style.up) Total Revenue (Annual): $\(formatLargeNumber(revenue))")
                metricCount += 1
            }

            if let netIncome = result.annualNetIncome?.first?.reportedValue?.raw {
                print("[NET] Net Income (Annual): $\(formatLargeNumber(netIncome))")
                metricCount += 1
            }

            // 재무상태표
            if let totalAssets = result.annualTotalAssets?.first?.reportedValue?.raw {
                print("\(style.company) Total Assets (Annual): $\(formatLargeNumber(totalAssets))")
                metricCount += 1
            }

            if let equity = result.annualTotalStockholderEquity?.first?.reportedValue?.raw {
                print("\(style.chart) Stockholder Equity (Annual): $\(formatLargeNumber(equity))")
                metricCount += 1
            }

            // 현금흐름표
            if let freeCashFlow = result.annualFreeCashFlow?.first?.reportedValue?.raw {
                print("[FCF] Free Cash Flow (Annual): $\(formatLargeNumber(freeCashFlow))")
                metricCount += 1
            }

            if let operatingCashFlow = result.annualOperatingCashFlow?.first?.reportedValue?.raw {
                print("[OCF] Operating Cash Flow (Annual): $\(formatLargeNumber(operatingCashFlow))")
                metricCount += 1
            }

            break // 첫 번째 결과만 요약 출력
        }

        if metricCount == 0 {
            print("No key financial metrics available.")
        } else {
            print("")
            print("[NOTE] Note: This is a summary view. \(metricCount) key metrics shown.")
            print("\(style.signal) Data from unified fundamentals-timeseries API")
        }
    }
}