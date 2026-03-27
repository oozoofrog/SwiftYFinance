import Foundation
import SwiftYFinance
import ArgumentParser

struct QuoteCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "quote",
        abstract: "Get real-time stock quote information"
    )

    @Argument(help: "Stock ticker symbol(s) (e.g., AAPL TSLA MSFT)")
    var symbols: [String]

    @Flag(name: .shortAndLong, help: "Enable debug output")
    var debug = false

    @Flag(name: .shortAndLong, help: "Output raw JSON response")
    var json = false

    /// 이모지 없이 ASCII 대체 문자로 출력 (CI/파이프라인 환경)
    @Flag(name: .customLong("no-emoji"), help: "이모지 없이 ASCII 대체 문자로 출력합니다")
    var noEmoji = false

    func run() async throws {
        guard !symbols.isEmpty else {
            print("Error: 종목 심볼을 하나 이상 입력하세요.")
            throw ExitCode.failure
        }

        let client = YFClient(debugEnabled: debug)
        let style = OutputStyle(noEmoji: noEmoji)
        let upperSymbols = symbols.map { $0.uppercased() }

        if debug && !json {
            print("\(style.search) Debug mode enabled")
            print("\(style.chart) Fetching quote for: \(upperSymbols.joined(separator: ", "))")
        }

        do {
            if json {
                if upperSymbols.count == 1 {
                    // 단일 심볼: 기존 fetchRawJSON 사용
                    let ticker = YFTicker(symbol: upperSymbols[0])
                    let rawData = try await client.quote.fetchRawJSON(ticker: ticker)
                    print(formatJSONOutput(rawData))
                } else {
                    // 복수 심볼: fetch(symbols:)로 배치 조회
                    let response = try await client.quote.fetch(symbols: upperSymbols)
                    let quotes = response.result ?? []
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    // YFQuote는 Encodable 미지원 → 딕셔너리 배열로 변환
                    let items: [[String: Any]] = quotes.map { quoteToDictionary($0) }
                    if let data = try? JSONSerialization.data(withJSONObject: items, options: .prettyPrinted),
                       let str = String(data: data, encoding: .utf8) {
                        print(str)
                    }
                }
            } else {
                if upperSymbols.count == 1 {
                    let ticker = YFTicker(symbol: upperSymbols[0])
                    let quote = try await client.quote.fetch(ticker: ticker)
                    printQuoteInfo(quote, style: style)
                } else {
                    // 복수 심볼: 배치 조회 후 심볼별 섹션 출력
                    let response = try await client.quote.fetch(symbols: upperSymbols)
                    let quotes = response.result ?? []
                    for (index, quote) in quotes.enumerated() {
                        if index > 0 { print("") }
                        printQuoteInfo(quote, style: style)
                    }
                }
            }
        } catch {
            if json {
                printJSONError("Failed to fetch quote", error: error)
            } else {
                printError("Failed to fetch quote", error: error, style: style)
            }
            throw ExitCode.failure
        }
    }

    private func printQuoteInfo(_ quote: YFQuote, style: OutputStyle) {
        let sym = quote.basicInfo.symbol ?? "N/A"
        let shortName = quote.basicInfo.shortName ?? "Unknown"

        print("\(style.chart) \(sym) - \(shortName)")
        print(style.separator)

        // 현재가 및 변화
        let currentPrice = quote.marketData.regularMarketPrice ?? 0
        let previousClose = quote.marketData.regularMarketPreviousClose ?? 0
        let change = currentPrice - previousClose
        let changePercent = previousClose > 0 ? (change / previousClose) * 100 : 0
        let changeIcon = style.changeIcon(change: change)
        let changeSign = change >= 0 ? "+" : ""

        print("Current Price:    $\(formatPrice(currentPrice))")
        print("Change:           \(changeIcon) \(changeSign)$\(formatPrice(change)) (\(changeSign)\(formatPercent(changePercent))%)")
        print("Previous Close:   $\(formatPrice(previousClose))")
        print("")

        // 시장 데이터
        print("Open:             $\(formatPrice(quote.marketData.regularMarketOpen ?? 0))")
        print("High:             $\(formatPrice(quote.marketData.regularMarketDayHigh ?? 0))")
        print("Low:              $\(formatPrice(quote.marketData.regularMarketDayLow ?? 0))")
        print("Volume:           \(formatVolume(quote.volumeInfo.regularMarketVolume ?? 0))")
        print("Market Cap:       $\(formatLargeNumber(quote.volumeInfo.marketCap ?? 0))")

        // 장후 거래
        if let postPrice = quote.extendedHours.postMarketPrice,
           let postTimeStamp = quote.extendedHours.postMarketTime,
           let postChangePercent = quote.extendedHours.postMarketChangePercent {
            print("")
            print("After Hours Trading:")
            print("Price:            $\(formatPrice(postPrice))")
            print("Change:           \(style.changeIcon(change: postChangePercent)) \(postChangePercent >= 0 ? "+" : "")\(formatPercent(postChangePercent))%")
            print("Time:             \(formatTime(Date(timeIntervalSince1970: TimeInterval(postTimeStamp))))")
        }

        // 장전 거래
        if let prePrice = quote.extendedHours.preMarketPrice,
           let preTimeStamp = quote.extendedHours.preMarketTime,
           let preChangePercent = quote.extendedHours.preMarketChangePercent {
            print("")
            print("Pre-Market Trading:")
            print("Price:            $\(formatPrice(prePrice))")
            print("Change:           \(style.changeIcon(change: preChangePercent)) \(preChangePercent >= 0 ? "+" : "")\(formatPercent(preChangePercent))%")
            print("Time:             \(formatTime(Date(timeIntervalSince1970: TimeInterval(preTimeStamp))))")
        }

        print("")
        if let timeStamp = quote.metadata.regularMarketTime {
            print("Last Updated:     \(formatTime(Date(timeIntervalSince1970: TimeInterval(timeStamp))))")
        }
    }

    /// YFQuote → 딕셔너리 변환 (JSON 직렬화용)
    private func quoteToDictionary(_ quote: YFQuote) -> [String: Any] {
        var dict: [String: Any] = [:]
        if let v = quote.basicInfo.symbol { dict["symbol"] = v }
        if let v = quote.basicInfo.shortName { dict["shortName"] = v }
        if let v = quote.marketData.regularMarketPrice { dict["regularMarketPrice"] = v }
        if let v = quote.marketData.regularMarketChange { dict["regularMarketChange"] = v }
        if let v = quote.marketData.regularMarketChangePercent { dict["regularMarketChangePercent"] = v }
        if let v = quote.volumeInfo.regularMarketVolume { dict["regularMarketVolume"] = v }
        if let v = quote.volumeInfo.marketCap { dict["marketCap"] = v }
        return dict
    }
}

/// OutputStyle 없는 printError 오버로드 — 기존 코드 호환성 유지
private func printError(_ message: String, error: Error, style: OutputStyle) {
    print("\(style.error) \(message)")
    if let yfError = error as? YFError {
        switch yfError {
        case .networkError:
            print("\(style.hint) Please check your internet connection.")
        case .apiError(let apiMessage):
            print("\(style.hint) API Error: \(apiMessage)")
        case .invalidRequest:
            print("\(style.hint) Please check if the ticker symbol is valid.")
        default:
            print("\(style.hint) Please try again later.")
        }
    } else {
        print("\(style.hint) \(error.localizedDescription)")
    }
}
