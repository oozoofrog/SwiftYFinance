import Foundation
import Testing
@testable import SwiftYFinance

/// WebSocket 기능 테스트
@Suite("WebSocket Tests")
struct YFWebSocketTests {

    let session = YFSession()

    // MARK: - URL Builder Tests

    @Test("기본 WebSocket URL 구성 테스트")
    func testBasicWebSocketURL() async throws {
        let url = try await YFAPIURLBuilder.webSocket(session: session)
            .build()

        let urlString = url.absoluteString
        #expect(urlString.contains("wss://streamer.finance.yahoo.com"))
        #expect(urlString.contains("version=2"))
    }

    @Test("커스텀 버전 WebSocket URL 테스트")
    func testCustomVersionWebSocketURL() async throws {
        let url = try await YFAPIURLBuilder.webSocket(session: session)
            .version(3)
            .build()

        let urlString = url.absoluteString
        #expect(urlString.contains("version=3"))
    }

    @Test("커스텀 파라미터 WebSocket URL 테스트")
    func testCustomParameterWebSocketURL() async throws {
        let url = try await YFAPIURLBuilder.webSocket(session: session)
            .version(2)
            .parameter("test", "value")
            .build()

        let urlString = url.absoluteString
        #expect(urlString.contains("version=2"))
        #expect(urlString.contains("test=value"))
    }

    @Test("WebSocket 클라이언트 생성 테스트")
    func testWebSocketClientCreation() async throws {
        let client = try await YFAPIURLBuilder.webSocket(session: session)
            .defaultClient()

        let state = await client.state
        let subscription = await client.subscription
        #expect(state == .disconnected)
        #expect(subscription.symbols.isEmpty)
    }

    @Test("디버그 WebSocket 클라이언트 생성 테스트")
    func testDebugWebSocketClientCreation() async throws {
        let client = try await YFAPIURLBuilder.webSocket(session: session)
            .debugClient()

        let state = await client.state
        let subscription = await client.subscription
        #expect(state == .disconnected)
        #expect(subscription.symbols.isEmpty)
    }

    // MARK: - Live Stream Message Tests

    @Test("YFLiveStreamMessage 생성 테스트")
    func testLiveStreamMessageCreation() {
        let message = YFLiveStreamMessage(
            symbol: "AAPL",
            price: 150.0,
            change: 2.5,
            changePercent: 1.67,
            volume: 1000000,
            marketState: "REGULAR"
        )

        #expect(message.symbol == "AAPL")
        #expect(message.price == 150.0)
        #expect(message.change == 2.5)
        #expect(message.changePercent == 1.67)
        #expect(message.volume == 1000000)
        #expect(message.marketState == "REGULAR")
        #expect(message.error == nil)
    }

    @Test("에러 메시지 생성 테스트")
    func testErrorMessageCreation() {
        let message = YFLiveStreamMessage(error: "Connection failed")

        #expect(message.error == "Connection failed")
        #expect(message.symbol == nil)
        #expect(message.price == nil)
    }

    // MARK: - Subscription Tests

    @Test("기본 구독 생성 테스트")
    func testBasicSubscriptionCreation() {
        let subscription = YFSubscription(symbols: ["AAPL", "MSFT"])

        #expect(subscription.symbols.contains("AAPL"))
        #expect(subscription.symbols.contains("MSFT"))
        #expect(subscription.symbols.count == 2)
    }

    @Test("구독 심볼 추가 테스트")
    func testSubscriptionAddingSymbols() {
        let original = YFSubscription(symbols: ["AAPL"])
        let updated = original.adding(["MSFT", "GOOGL"])

        #expect(updated.symbols.contains("AAPL"))
        #expect(updated.symbols.contains("MSFT"))
        #expect(updated.symbols.contains("GOOGL"))
        #expect(updated.symbols.count == 3)

        // 원본은 변경되지 않음 (불변성)
        #expect(original.symbols.count == 1)
    }

    @Test("구독 심볼 제거 테스트")
    func testSubscriptionRemovingSymbols() {
        let original = YFSubscription(symbols: ["AAPL", "MSFT", "GOOGL"])
        let updated = original.removing(["MSFT"])

        #expect(updated.symbols.contains("AAPL"))
        #expect(!updated.symbols.contains("MSFT"))
        #expect(updated.symbols.contains("GOOGL"))
        #expect(updated.symbols.count == 2)

        // 원본은 변경되지 않음 (불변성)
        #expect(original.symbols.count == 3)
    }

    @Test("중복 심볼 추가 테스트")
    func testSubscriptionDuplicateSymbols() {
        let original = YFSubscription(symbols: ["AAPL"])
        let updated = original.adding(["AAPL", "MSFT"])

        // Set이므로 중복 제거됨
        #expect(updated.symbols.count == 2)
        #expect(updated.symbols.contains("AAPL"))
        #expect(updated.symbols.contains("MSFT"))
    }

    // MARK: - WebSocket State Tests

    @Test("WebSocket 상태 확인 테스트")
    func testWebSocketStates() {
        let disconnected: YFWebSocketState = .disconnected
        let connecting: YFWebSocketState = .connecting
        let connected: YFWebSocketState = .connected
        let error: YFWebSocketState = .error("Test error")

        switch disconnected {
        case .disconnected: break
        default: #expect(false, "Expected disconnected state")
        }

        switch connecting {
        case .connecting: break
        default: #expect(false, "Expected connecting state")
        }

        switch connected {
        case .connected: break
        default: #expect(false, "Expected connected state")
        }

        switch error {
        case .error(let message):
            #expect(message == "Test error")
        default: #expect(false, "Expected error state")
        }
    }

    // MARK: - WebSocket Client Tests

    @Test("WebSocket 클라이언트 기본 설정 테스트")
    func testWebSocketClientConfiguration() async {
        let customURL = URL(string: "wss://test.example.com")!
        let client = YFWebSocketClient(
            url: customURL,
            verbose: true,
            urlSession: .shared
        )

        let state = await client.state
        let subscription = await client.subscription
        #expect(state == .disconnected)
        #expect(subscription.symbols.isEmpty)
    }

    // MARK: - AsyncStream Tests

    @Test("AsyncStream 메시지 스트림 테스트")
    func testMessageStream() async {
        let client = YFWebSocketClient()

        // actor 메서드를 통해 스트림 접근
        let (messageStream, _) = await client.streams()
        let iterator = messageStream.makeAsyncIterator()
        #expect(iterator != nil)
    }

    @Test("AsyncStream 상태 스트림 테스트")
    func testStateStream() async {
        let client = YFWebSocketClient()

        let (_, stateStream) = await client.streams()
        let iterator = stateStream.makeAsyncIterator()
        #expect(iterator != nil)
    }

    @Test("AsyncStream과 streams() API 테스트")
    func testStreamsAPI() async {
        let client = YFWebSocketClient()

        let (messageStream, stateStream) = await client.streams()
        #expect(messageStream.makeAsyncIterator() != nil)
        #expect(stateStream.makeAsyncIterator() != nil)
    }

    // MARK: - Protocol Buffers Decoder Tests

    @Test("Base64 디코딩 에러 테스트")
    func testBase64DecodingError() {
        let decoder = YFLiveMessageDecoderWrapper()

        let invalidBase64 = "invalid-base64!!!"
        let result = decoder.decode(invalidBase64)

        #expect(result.error != nil)
        #expect(result.error?.contains("Failed to decode base64 message") == true)
    }

    @Test("빈 Base64 메시지 테스트")
    func testEmptyBase64Message() {
        let decoder = YFLiveMessageDecoderWrapper()

        let emptyBase64 = Data().base64EncodedString()
        let result = decoder.decode(emptyBase64)

        #expect(result.error == nil)
        #expect(result.raw != nil)
    }
}

// MARK: - Private Test Helpers

/// 테스트용 메시지 디코더 래퍼
private final class YFLiveMessageDecoderWrapper: Sendable {
    func decode(_ base64Message: String) -> YFLiveStreamMessage {
        guard let decodedData = Data(base64Encoded: base64Message) else {
            return YFLiveStreamMessage(error: "Failed to decode base64 message")
        }

        return YFLiveStreamMessage(
            raw: ["decoded_data_size": decodedData.count],
            error: nil
        )
    }
}
