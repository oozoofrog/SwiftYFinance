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
    
    func run() async throws {
        let normalizedSymbols = symbols.map { $0.uppercased() }
        
        if debug && !json {
            print("🔍 Debug mode enabled")
            print("📡 Starting WebSocket stream for: \(normalizedSymbols.joined(separator: ", "))")
            print("⏱️ Duration: \(duration) seconds")
        }
        
        let webSocketClient = YFWebSocketClient(verbose: debug)
        
        do {
            // WebSocket 연결
            try await webSocketClient.connect()
            
            if !json {
                print("🔗 Connected to Yahoo Finance WebSocket")
                print("📡 Subscribing to symbols: \(normalizedSymbols.joined(separator: ", "))")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print("")
            }
            
            // 심볼 구독
            try await webSocketClient.subscribe(normalizedSymbols)
            
            // 스트리밍 시작
            if json {
                try await streamJSONOutput(webSocketClient: webSocketClient, duration: duration)
            } else {
                try await streamFormattedOutput(webSocketClient: webSocketClient, duration: duration)
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
        
        for await message in webSocketClient.messageStream {
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
    
    private func streamFormattedOutput(webSocketClient: YFWebSocketClient, duration: Int) async throws {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(TimeInterval(duration))
        
        var messageCount = 0
        var lastPrices: [String: Double] = [:]
        
        print("📡 Real-time Data Stream")
        print("⏱️ Streaming for \(duration) seconds...")
        print("🛑 Press Ctrl+C to stop early")
        print("")
        
        for await message in webSocketClient.messageStream {
            let currentTime = Date()
            if currentTime > endTime {
                break
            }
            
            messageCount += 1
            
            if let error = message.error {
                print("❌ Error: \(error)")
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
                if price > prev {
                    priceChangeIcon = "📈"
                } else if price < prev {
                    priceChangeIcon = "📉"
                } else {
                    priceChangeIcon = "➡️"
                }
            } else {
                priceChangeIcon = "💫"
            }
            
            // 실시간 데이터 출력
            let timeString = formatTime(currentTime)
            let changeString = message.change.map { change in
                let changePercent = message.changePercent ?? 0
                let changeIcon = change >= 0 ? "🟢" : "🔴"
                let changeSign = change >= 0 ? "+" : ""
                return "\(changeIcon) \(changeSign)$\(formatPrice(change)) (\(changeSign)\(formatPercent(changePercent))%)"
            } ?? "N/A"
            
            let volumeString = message.volume.map { formatVolume(Int($0)) } ?? "N/A"
            let marketStateIcon = getMarketStateIcon(message.marketState)
            
            print("[\(timeString)] \(priceChangeIcon) \(symbol): $\(formatPrice(price)) | \(changeString) | Vol: \(volumeString) \(marketStateIcon)")
        }
        
        print("")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 Stream Summary:")
        print("   Messages Received: \(messageCount)")
        print("   Symbols Tracked: \(lastPrices.count)")
        print("   Final Prices:")
        
        for (symbol, price) in lastPrices.sorted(by: { $0.key < $1.key }) {
            print("   • \(symbol): $\(formatPrice(price))")
        }
        
        await webSocketClient.disconnect()
    }
    
    private func getMarketStateIcon(_ marketState: String?) -> String {
        switch marketState?.uppercased() {
        case "REGULAR":
            return "🟢"
        case "PRE":
            return "🌅"
        case "POST":
            return "🌆"
        case "CLOSED":
            return "🔴"
        default:
            return "⚪"
        }
    }
}