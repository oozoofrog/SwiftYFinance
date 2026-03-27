import Foundation
import SwiftYFinance
import ArgumentParser

struct WebSocketCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "websocket",
        abstract: "Stream real-time stock price data via WebSocket"
    )
    
    @Argument(help: "Stock ticker symbols to subscribe (e.g., AAPL TSLA BTC-USD)")
    var symbols: [String]
    
    @Option(name: [.customLong("duration"), .customShort("t")], help: "Duration to stream data in seconds (default: 30)")
    var duration: Int = 30
    
    @Flag(name: .shortAndLong, help: "Enable debug output")
    var debug = false

    @Flag(name: .shortAndLong, help: "Output raw JSON response")
    var json = false

    /// 이모지 없이 ASCII 대체 문자로 출력 (CI/파이프라인 환경)
    @Flag(name: .customLong("no-emoji"), help: "이모지 없이 ASCII 대체 문자로 출력합니다")
    var noEmoji = false

    func run() async throws {
        let normalizedSymbols = symbols.map { $0.uppercased() }
        let style = OutputStyle(noEmoji: noEmoji)

        if debug && !json {
            print("\(style.search) Debug mode enabled")
            print("\(style.signal) Starting WebSocket stream for: \(normalizedSymbols.joined(separator: ", "))")
            print("\(style.clock) Duration: \(duration) seconds")
        }

        let webSocketClient = YFWebSocketClient(verbose: debug)

        do {
            // WebSocket 연결
            try await webSocketClient.connect()

            if !json {
                print("\(style.link) Connected to Yahoo Finance WebSocket")
                print("\(style.signal) Subscribing to symbols: \(normalizedSymbols.joined(separator: ", "))")
                print(style.separator)
                print("")
            }

            // 심볼 구독
            try await webSocketClient.subscribe(normalizedSymbols)

            // 스트리밍 시작
            if json {
                try await streamJSONOutput(webSocketClient: webSocketClient, duration: duration)
            } else {
                try await streamFormattedOutput(webSocketClient: webSocketClient, duration: duration, style: style)
            }

        } catch {
            if json {
                printJSONError("Failed to start WebSocket stream", error: error)
            } else {
                printError("Failed to start WebSocket stream", error: error)
            }
            throw ExitCode.failure
        }
    }
    
    private func streamJSONOutput(webSocketClient: YFWebSocketClient, duration: Int) async throws {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(TimeInterval(duration))

        print("{")
        print("  \"stream_start\": \"\(ISO8601DateFormatter().string(from: startTime))\",")
        print("  \"duration_seconds\": \(duration),")
        print("  \"symbols\": [\(symbols.map { "\"\($0.uppercased())\"" }.joined(separator: ", "))],")
        print("  \"messages\": [")

        var isFirstMessage = true

        // actor-isolated messageStream은 streams() 메서드를 통해 접근
        let (messageStream, _) = await webSocketClient.streams()
        for await message in messageStream {
            let currentTime = Date()
            if currentTime > endTime {
                break
            }
            
            if !isFirstMessage {
                print(",")
            }
            
            let messageJSON = [
                "timestamp": ISO8601DateFormatter().string(from: currentTime),
                "symbol": message.symbol ?? "",
                "price": message.price ?? 0,
                "change": message.change ?? 0,
                "changePercent": message.changePercent ?? 0,
                "volume": message.volume ?? 0,
                "marketState": message.marketState ?? "",
                "dayHigh": message.dayHigh ?? 0,
                "dayLow": message.dayLow ?? 0,
                "error": message.error ?? ""
            ] as [String: Any]
            
            let jsonData = try JSONSerialization.data(withJSONObject: messageJSON, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            
            // 각 줄에 적절한 들여쓰기 추가
            let indentedJSON = jsonString.components(separatedBy: .newlines)
                .map { "    \($0)" }
                .joined(separator: "\n")
            
            print(indentedJSON, terminator: "")
            isFirstMessage = false
        }
        
        print("")
        print("  ],")
        print("  \"stream_end\": \"\(ISO8601DateFormatter().string(from: Date()))\"")
        print("}")
        
        await webSocketClient.disconnect()
    }
    
    private func streamFormattedOutput(webSocketClient: YFWebSocketClient, duration: Int, style: OutputStyle) async throws {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(TimeInterval(duration))

        var messageCount = 0
        var lastPrices: [String: Double] = [:]

        print("\(style.signal) Real-time Data Stream")
        print("\(style.clock) Streaming for \(duration) seconds...")
        print("\(style.stop) Press Ctrl+C to stop early")
        print("")

        // actor-isolated messageStream은 streams() 메서드를 통해 접근
        let (messageStream, _) = await webSocketClient.streams()
        for await message in messageStream {
            let currentTime = Date()
            if currentTime > endTime {
                break
            }

            messageCount += 1

            if let error = message.error {
                print("\(style.error) Error: \(error)")
                continue
            }

            guard let symbol = message.symbol,
                  let price = message.price else {
                continue
            }

            // 가격 변화 계산
            let previousPrice = lastPrices[symbol]
            lastPrices[symbol] = price

            let priceChangeIcon: String
            if let prev = previousPrice {
                priceChangeIcon = style.trendIcon(current: price, previous: prev)
            } else {
                priceChangeIcon = style.noEmoji ? "[NEW]" : "🆕"
            }

            // 실시간 데이터 출력
            let timeString = formatTime(currentTime)
            let changeString = message.change.map { change in
                let changePercent = message.changePercent ?? 0
                let changeIcon = style.changeIcon(change: change)
                let changeSign = change >= 0 ? "+" : ""
                return "\(changeIcon) \(changeSign)$\(formatPrice(change)) (\(changeSign)\(formatPercent(changePercent))%)"
            } ?? "N/A"

            let volumeString = message.volume.map { formatVolume(Int($0)) } ?? "N/A"
            let marketStateLabel = getMarketStateLabel(message.marketState, style: style)

            print("[\(timeString)] \(priceChangeIcon) \(symbol): $\(formatPrice(price)) | \(changeString) | Vol: \(volumeString) \(marketStateLabel)")
        }

        print("")
        print(style.separator)
        print("\(style.chart) Stream Summary:")
        print("   Messages Received: \(messageCount)")
        print("   Symbols Tracked: \(lastPrices.count)")
        print("   Final Prices:")

        for (symbol, price) in lastPrices.sorted(by: { $0.key < $1.key }) {
            print("   - \(symbol): $\(formatPrice(price))")
        }

        await webSocketClient.disconnect()
    }

    private func getMarketStateLabel(_ marketState: String?, style: OutputStyle) -> String {
        switch marketState?.uppercased() {
        case "REGULAR":
            return style.greenCircle
        case "PRE":
            return style.noEmoji ? "[PRE]" : "🌅"
        case "POST":
            return style.noEmoji ? "[POST]" : "🌙"
        case "CLOSED":
            return style.redCircle
        default:
            return style.noEmoji ? "[--]" : "⚪"
        }
    }
}