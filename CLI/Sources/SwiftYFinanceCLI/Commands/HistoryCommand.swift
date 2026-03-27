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

    /// 봉 단위 옵션 (기본값: 1d)
    /// 유효값: 1m, 2m, 5m, 15m, 30m, 60m, 90m, 1h, 1d, 5d, 1wk, 1mo, 3mo
    @Option(name: .customLong("interval"), help: "Candle interval (1m, 2m, 5m, 15m, 30m, 60m, 90m, 1h, 1d, 5d, 1wk, 1mo, 3mo). Default: 1d")
    var interval: String = "1d"

    @Flag(name: .shortAndLong, help: "Enable debug output")
    var debug = false

    @Flag(name: .shortAndLong, help: "Output raw JSON response")
    var json = false

    @Flag(name: .customLong("no-emoji"), help: "이모지 없이 ASCII 대체 문자로 출력합니다")
    var noEmoji = false

    /// 유효한 interval 값 목록 (13개)
    static let validIntervals: [String] = [
        "1m", "2m", "5m", "15m", "30m", "60m", "90m",
        "1h", "1d", "5d", "1wk", "1mo", "3mo"
    ]

    func run() async throws {
        let client = YFClient(debugEnabled: debug)
        let ticker = YFTicker(symbol: symbol.uppercased())
        let style = OutputStyle(noEmoji: noEmoji)

        // period 검증
        guard let yfPeriod = parseYFPeriod(period) else {
            let message = "Invalid period: \(period). Valid periods: 1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, 10y, max"
            if json {
                printJSONError("Invalid period", error: YFError.invalidParameter(message))
            } else {
                print("\(style.error) \(message)")
            }
            throw ExitCode.failure
        }

        // interval 검증 — 13개 유효값 검사
        guard let yfInterval = parseYFInterval(interval) else {
            let validList = HistoryCommand.validIntervals.joined(separator: ", ")
            let message = "Invalid interval: \(interval)\nValid intervals: \(validList)"
            if json {
                printJSONError("Invalid interval", error: YFError.invalidParameter("Invalid interval: \(interval)"))
            } else {
                print("\(style.error) \(message)")
            }
            throw ExitCode.failure
        }

        if debug && !json {
            print("\(style.search) Debug mode enabled")
            print("\(style.chart) Fetching \(period) history (interval: \(interval)) for: \(ticker.symbol)")
        }

        do {
            if json {
                let rawData = try await client.chart.fetchRawJSON(ticker: ticker, period: yfPeriod, interval: yfInterval)
                print(formatJSONOutput(rawData))
            } else {
                let history = try await client.chart.fetch(ticker: ticker, period: yfPeriod, interval: yfInterval)
                printHistoryInfo(history, period: period, interval: interval, style: style)
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

    private func printHistoryInfo(_ history: YFHistoricalData, period: String, interval: String, style: OutputStyle) {
        print("\(style.chart) \(history.ticker.symbol) - \(period.uppercased()) Historical Data (interval: \(interval))")
        print(style.separator)
        print("Period:           \(formatDate(history.startDate)) to \(formatDate(history.endDate))")
        print("Total Days:       \(history.prices.count)")

        if !history.prices.isEmpty {
            let latest = history.prices.last!
            let earliest = history.prices.first!
            let totalReturn = earliest.adjClose != 0
                ? ((latest.adjClose - earliest.adjClose) / earliest.adjClose) * 100
                : 0
            let returnIcon = style.changeIcon(change: totalReturn)

            print("")
            print("Performance Summary:")
            print("Starting Price:   $\(formatPrice(earliest.adjClose))")
            print("Ending Price:     $\(formatPrice(latest.adjClose))")
            print("Total Return:     \(returnIcon) \(formatPercent(totalReturn))%")

            // 최근 5개 데이터 포인트
            print("")
            print("Recent Prices:")
            print("Date         Open      High      Low       Close     Volume")
            print("───────────────────────────────────────────────────────────")

            for price in history.prices.suffix(5) {
                print("\(formatDateShort(price.date))  $\(formatPriceShort(price.open))  $\(formatPriceShort(price.high))  $\(formatPriceShort(price.low))  $\(formatPriceShort(price.close))  \(formatVolumeShort(price.volume))")
            }
        }
    }

    /// YFInterval 파싱 — 13개 유효값
    private func parseYFInterval(_ str: String) -> YFInterval? {
        switch str.lowercased() {
        case "1m": return .oneMinute
        case "2m": return .twoMinutes
        case "5m": return .fiveMinutes
        case "15m": return .fifteenMinutes
        case "30m": return .thirtyMinutes
        case "60m": return .sixtyMinutes
        case "90m": return .ninetyMinutes
        case "1h": return .oneHour
        case "1d": return .oneDay
        case "5d": return .fiveDays
        case "1wk": return .oneWeek
        case "1mo": return .oneMonth
        case "3mo": return .threeMonths
        default: return nil
        }
    }
}
