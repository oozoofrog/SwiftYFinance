import Foundation
import SwiftYFinance
import ArgumentParser

struct NewsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "news",
        abstract: "Get news articles for stock ticker symbols"
    )
    
    @Argument(help: "Stock ticker symbol (e.g., AAPL, TSLA)")
    var symbol: String
    
    @Option(name: .shortAndLong, help: "Number of news articles to fetch (default: 10)")
    var count: Int = 10
    
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
            print("\(style.news) Fetching \(count) news articles for: \(ticker.symbol)")
        }

        do {
            if json {
                let rawData = try await client.news.fetchRawJSON(ticker: ticker, count: count)
                print(formatJSONOutput(rawData))
            } else {
                let news = try await client.news.fetchNews(ticker: ticker, count: count)
                printNewsInfo(news, for: ticker.symbol, style: style)
            }
        } catch {
            if json {
                printJSONError("Failed to fetch news", error: error)
            } else {
                printError("Failed to fetch news", error: error)
            }
            throw ExitCode.failure
        }
    }

    private func printNewsInfo(_ articles: [YFNewsArticle], for symbol: String, style: OutputStyle) {
        print("\(style.news) Latest News for \(symbol)")
        print(style.separator)
        print("")

        if articles.isEmpty {
            print("No news articles found for \(symbol)")
            return
        }

        for (index, article) in articles.enumerated() {
            let title = article.title ?? "Untitled"
            let publisher = article.publisher ?? "Unknown Source"
            let link = article.link ?? ""

            print("[\(index + 1)] \(title)")

            if let publishTimeStamp = article.providerPublishTime {
                let date = Date(timeIntervalSince1970: TimeInterval(publishTimeStamp))
                print("    \(style.clock) \(formatNewsDate(date))")
            }

            print("    \(style.news) \(publisher)")

            if let summary = article.summary, !summary.isEmpty {
                print("    \(style.hint) \(summary)")
            }

            if !link.isEmpty {
                print("    \(style.link) \(link)")
            }

            if let type = article.type {
                print("    [TYPE] \(type)")
            }

            print("")
        }

        print("Found \(articles.count) news article\(articles.count == 1 ? "" : "s")")
    }
    
    private func formatNewsDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}