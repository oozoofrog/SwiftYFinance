# Phase 8 Step 4-5: WebSocket 핵심 기능 구현 (Core)

> **목표**: 구독 관리 → 메시지 스트리밍 핵심 기능  
> **전제조건**: Step 1-3 완료 (기본 모델, Protobuf, 연결 기초)

## 🔴 Step 4: 구독 관리 테스트

### 테스트 작성 (RED)
- [ ] 단일 심볼 구독 테스트 (`{"subscribe": ["AAPL"]}`)
- [ ] 구독 상태 추적 테스트 (active subscriptions Set)
- [ ] 중복 구독 방지 테스트 (같은 심볼 재구독)
- [ ] 구독 해제 테스트 (심볼 제거)

### 구현 (GREEN)
- [ ] 구독 상태 관리 (activeSubscriptions: Set<String>)
- [ ] JSON 메시지 생성 (`{"subscribe": [symbols]}`)
- [ ] 단일 심볼 구독 메서드 (subscribe/unsubscribe)
- [ ] 중복 구독 방지 로직

### 리팩터링 (REFACTOR)
- [ ] 구독 관리 로직 최적화
- [ ] JSON 생성 유틸리티 분리
- [ ] 에러 처리 개선

---

## 🔴 Step 5: 메시지 스트리밍 테스트

### 테스트 작성 (RED)
- [ ] AsyncStream 기본 메시지 수신 테스트 (Mock 데이터)
- [ ] 실시간 가격 업데이트 테스트 (price, change 검증)
- [ ] 메시지 순서 테스트 (시간순 정렬)
- [ ] AsyncStream 메시지 수신 테스트 (`confirmation(expectedCount:)`)

### 구현 (GREEN)
- [ ] AsyncStream 기본 구현 (messageStream 메서드)
- [ ] 메시지 수신 및 파싱 연동
- [ ] Swift Concurrency 지원 (async/await)
- [ ] 기본 에러 처리

### 리팩터링 (REFACTOR)
- [ ] AsyncStream 성능 최적화
- [ ] 메시지 파싱 로직 개선
- [ ] 동시성 처리 최적화

---

## 📝 Step 4-5 완료 기준

### 기능 검증
- [ ] 모든 Step 4-5 테스트 통과 (100%)
- [ ] 단일/다중 심볼 구독 성공
- [ ] AsyncStream 메시지 수신 성공
- [ ] 실시간 가격 데이터 파싱 성공

### 성능 검증
- [ ] 구독 상태 변경 지연시간 < 100ms
- [ ] 메시지 스트리밍 지연시간 < 200ms
- [ ] 메모리 누수 없음 (기본 테스트)

### 코드 품질
- [ ] 메서드 크기 20줄 이하 유지
- [ ] 파일 크기 250줄 이하 (Step 4-5)
- [ ] AsyncStream 올바른 사용
- [ ] 스레드 안전성 확보

### 다음 단계 준비
- [ ] Step 6-7을 위한 기반 완성
- [ ] 재연결 로직을 위한 구조 준비
- [ ] 성능 측정 기반 마련

---

## 🧪 Step 4-5 테스트 예시

### Step 4: 구독 관리 테스트
```swift
@Test("단일 심볼 구독 테스트")
func testSingleSymbolSubscription() async throws {
    let mockManager = MockWebSocketManager()
    
    try await mockManager.subscribe(symbols: ["AAPL"])
    #expect(mockManager.activeSubscriptions.contains("AAPL"))
    
    // JSON 메시지 검증
    let expectedMessage = #"{"subscribe":["AAPL"]}"#
    #expect(mockManager.lastSentMessage == expectedMessage)
}

@Test("중복 구독 방지 테스트")
func testDuplicateSubscriptionPrevention() async throws {
    let mockManager = MockWebSocketManager()
    
    try await mockManager.subscribe(symbols: ["AAPL"])
    try await mockManager.subscribe(symbols: ["AAPL"]) // 중복 구독
    
    #expect(mockManager.activeSubscriptions.count == 1)
    #expect(mockManager.subscribeCallCount == 1) // 한 번만 호출
}
```

### Step 5: 메시지 스트리밍 테스트
```swift
@Test("AsyncStream 메시지 수신 테스트")
func testAsyncStreamMessageReceiving() async {
    let mockManager = MockWebSocketManager()
    let testMessages = [
        YFWebSocketMessage(symbol: "AAPL", price: 150.0, timestamp: Date()),
        YFWebSocketMessage(symbol: "AAPL", price: 151.0, timestamp: Date()),
        YFWebSocketMessage(symbol: "AAPL", price: 152.0, timestamp: Date())
    ]
    mockManager.mockMessages = testMessages
    
    var receivedMessages: [YFWebSocketMessage] = []
    
    // Swift Testing 방식
    await confirmation(expectedCount: 3) { confirm in
        for await message in mockManager.messageStream() {
            receivedMessages.append(message)
            #expect(message.symbol == "AAPL")
            #expect(message.price > 0)
            confirm()
        }
    }
    
    #expect(receivedMessages.count == 3)
    #expect(receivedMessages[0].price == 150.0)
    #expect(receivedMessages[2].price == 152.0)
}

@Test("실시간 가격 변화 테스트")
func testRealTimePriceUpdates() async {
    let mockManager = MockWebSocketManager()
    
    // 가격 변화 시뮬레이션
    let priceUpdates = [
        (price: 100.0, change: 0.0),
        (price: 101.5, change: 1.5),
        (price: 99.8, change: -1.7)
    ]
    
    for (index, update) in priceUpdates.enumerated() {
        let message = YFWebSocketMessage(
            symbol: "TEST",
            price: update.price,
            change: update.change,
            timestamp: Date()
        )
        mockManager.simulateMessage(message)
        
        let receivedMessage = await mockManager.getLatestMessage()
        #expect(receivedMessage?.price == update.price)
        #expect(receivedMessage?.change == update.change)
    }
}
```

---

## 🔧 Step 4-5 구현 세부사항

### 구독 관리 로직
```swift
class YFWebSocketManager {
    private var activeSubscriptions: Set<String> = []
    
    func subscribe(symbols: [String]) async throws {
        // yfinance/live.py의 subscribe 패턴 참조
        let newSymbols = Set(symbols).subtracting(activeSubscriptions)
        guard !newSymbols.isEmpty else { return } // 중복 방지
        
        // Yahoo Finance WebSocket 구독 메시지 형식
        let subscribeMessage = [
            "subscribe": Array(newSymbols)
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: subscribeMessage)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        try await sendMessage(jsonString)
        activeSubscriptions.formUnion(newSymbols)
    }
}
```

## 📂 yfinance-reference 소스 참조

### Step 4-5에서 참고할 소스 코드
- **`yfinance/live.py:238-249`** - subscribe() 메서드 구현
- **`yfinance/live.py:20`** - _subscriptions Set 관리
- **`yfinance/live.py:39-209`** - AsyncWebSocket 비동기 구현 패턴

### AsyncStream 구현
```swift
func messageStream() -> AsyncStream<YFWebSocketMessage> {
    AsyncStream { continuation in
        Task {
            do {
                while connectionState == .connected {
                    let message = try await webSocketTask?.receive()
                    
                    switch message {
                    case .data(let data):
                        if let decoded = try? decoder.decode(data) {
                            continuation.yield(decoded)
                        }
                    case .string(let string):
                        if let decoded = try? decoder.decode(string) {
                            continuation.yield(decoded)
                        }
                    case .none:
                        break
                    @unknown default:
                        break
                    }
                }
            } catch {
                continuation.finish()
            }
        }
    }
}
```

---

## 📊 Step 4-5 성능 목표

### 구독 관리 성능
- 구독 요청 처리: < 100ms
- 구독 상태 업데이트: < 50ms
- JSON 메시지 생성: < 10ms

### 메시지 스트리밍 성능  
- 메시지 수신 지연: < 200ms
- Protobuf 디코딩: < 5ms
- AsyncStream 처리: < 1ms

### 메모리 사용량
- 구독 상태 관리: < 1MB
- 메시지 버퍼링: < 10MB
- AsyncStream: < 5MB

---

## 🧪 AsyncStream 테스트 패턴

### Swift Testing 방식
```swift
@Test("WebSocket 메시지 스트림 테스트")
func testWebSocketMessageStream() async {
    let mockManager = MockWebSocketManager()
    mockManager.mockMessages = createTestMessages(count: 5)
    
    await confirmation(expectedCount: 5) { confirm in
        for await message in mockManager.messageStream() {
            #expect(message.symbol != nil)
            #expect(message.price > 0)
            confirm()
        }
    }
}
```

### XCTest 방식
```swift
func testWebSocketStream() async {
    let expectation = XCTestExpectation(description: "Messages")
    expectation.expectedFulfillmentCount = 5
    expectation.assertForOverFulfill = true
    
    for await message in mockWebSocketStream {
        XCTAssertNotNil(message.symbol)
        XCTAssertGreaterThan(message.price, 0)
        expectation.fulfill()
    }
    
    await fulfillment(of: [expectation], timeout: 10)
}
```

### 테스트 데이터 생성 유틸리티
```swift
func createTestMessages(count: Int) -> [YFWebSocketMessage] {
    return (0..<count).map { index in
        YFWebSocketMessage(
            symbol: "TEST\(index)",
            price: Double(100 + index),
            currency: "USD",
            exchange: "TEST",
            timestamp: Date()
        )
    }
}
```

---

**이전 단계**: [Phase 8 Step 1-3: 기초 구현](phase8-step1-3-foundation.md)  
**다음 단계**: [Phase 8 Step 6-7: 고급 기능 구현](phase8-step6-7-advanced.md)