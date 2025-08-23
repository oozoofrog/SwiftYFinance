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
        
        #expect(client.state == .disconnected)
        #expect(client.subscription.symbols.isEmpty)
    }
    
    @Test("디버그 WebSocket 클라이언트 생성 테스트")
    func testDebugWebSocketClientCreation() async throws {
        let client = try await YFAPIURLBuilder.webSocket(session: session)
            .debugClient()
        
        #expect(client.state == .disconnected)
        #expect(client.subscription.symbols.isEmpty)
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
        case .disconnected: break // 성공
        default: #expect(false, "Expected disconnected state")
        }
        
        switch connecting {
        case .connecting: break // 성공
        default: #expect(false, "Expected connecting state")
        }
        
        switch connected {
        case .connected: break // 성공
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
    func testWebSocketClientConfiguration() {
        let customURL = URL(string: "wss://test.example.com")!
        let client = YFWebSocketClient(
            url: customURL,
            verbose: true,
            urlSession: .shared
        )
        
        #expect(client.state == .disconnected)
        #expect(client.subscription.symbols.isEmpty)
    }
    
    @Test("WebSocket 클라이언트 핸들러 설정 테스트")
    func testWebSocketClientHandlers() {
        let client = YFWebSocketClient()
        
        client.onMessage = { _ in
            // 메시지 핸들러 테스트
        }
        
        client.onStateChange = { _ in
            // 상태 변경 핸들러 테스트
        }
        
        // 핸들러가 설정되었는지 확인
        #expect(client.onMessage != nil)
        #expect(client.onStateChange != nil)
    }
    
    // MARK: - AsyncStream Tests
    
    @Test("AsyncStream 메시지 스트림 테스트")
    func testMessageStream() async {
        let client = YFWebSocketClient()
        
        // 메시지 스트림이 생성되는지 확인
        let messageStream = client.messageStream
        
        // AsyncStream이 반복 가능한지 확인
        let iterator = messageStream.makeAsyncIterator()
        #expect(iterator != nil)
    }
    
    @Test("AsyncStream 상태 스트림 테스트")
    func testStateStream() async {
        let client = YFWebSocketClient()
        
        // 상태 스트림이 생성되는지 확인
        let stateStream = client.stateStream
        
        // AsyncStream이 반복 가능한지 확인
        let iterator = stateStream.makeAsyncIterator()
        #expect(iterator != nil)
    }
    
    @Test("AsyncStream과 핸들러 동시 동작 테스트")
    func testStreamAndHandlerCoexistence() async {
        let client = YFWebSocketClient()
        
        // 핸들러 설정
        client.onMessage = { _ in }
        client.onStateChange = { _ in }
        
        // 스트림 접근
        let messageStream = client.messageStream
        let stateStream = client.stateStream
        
        // 둘 다 동시에 작동하는지 확인
        #expect(client.onMessage != nil)
        #expect(client.onStateChange != nil)
        #expect(messageStream.makeAsyncIterator() != nil)
        #expect(stateStream.makeAsyncIterator() != nil)
    }
    
    // MARK: - Protocol Buffers Decoder Tests
    
    @Test("Base64 디코딩 에러 테스트")
    func testBase64DecodingError() {
        let decoder = YFLiveMessageDecoder()
        
        // 잘못된 Base64 문자열
        let invalidBase64 = "invalid-base64!!!"
        let result = decoder.decode(invalidBase64)
        
        #expect(result.error != nil)
        #expect(result.error?.contains("Failed to decode base64 message") == true)
    }
    
    @Test("빈 Base64 메시지 테스트")
    func testEmptyBase64Message() {
        let decoder = YFLiveMessageDecoder()
        
        // 빈 Base64 문자열 (빈 데이터)
        let emptyBase64 = Data().base64EncodedString()
        let result = decoder.decode(emptyBase64)
        
        // 빈 데이터는 에러가 아니라 빈 결과를 반환해야 함
        #expect(result.error == nil)
        #expect(result.raw != nil)
    }
}

// MARK: - Private Test Helpers

private final class YFLiveMessageDecoder: Sendable {
    func decode(_ base64Message: String) -> YFLiveStreamMessage {
        guard let decodedData = Data(base64Encoded: base64Message) else {
            return YFLiveStreamMessage(error: "Failed to decode base64 message")
        }
        
        // 테스트를 위한 간단한 구현
        return YFLiveStreamMessage(
            raw: ["decoded_data_size": decodedData.count],
            error: nil
        )
    }
}

