# Phase 8 Step 1-3: WebSocket 기초 구현 (Foundation)

> **목표**: 기본 데이터 모델 → Protobuf 디코딩 → WebSocket 연결 기초  
> **원칙**: TDD (RED → GREEN → REFACTOR)

## 🔴 Step 1: 기본 데이터 모델 테스트 ⭐️

### 테스트 작성 (RED)
- [ ] YFWebSocketMessage 초기화 테스트 (기본 프로퍼티)
- [ ] YFStreamingQuote 모델 테스트 (price, symbol, timestamp)
- [ ] YFWebSocketError 열거형 테스트 (에러 케이스 정의)
- [ ] Mock 객체 프로토콜 정의 (WebSocketManagerProtocol)

### 구현 (GREEN)
- [ ] YFWebSocketMessage.swift 생성 (기본 프로퍼티만)
- [ ] YFStreamingQuote.swift 생성 (price, symbol, timestamp)
- [ ] YFWebSocketError 케이스 추가 (기본 에러 타입)
- [ ] WebSocketManagerProtocol 정의 (Mock을 위한 인터페이스)

### 리팩터링 (REFACTOR)
- [ ] 모델 구조 정리 및 최적화
- [ ] 코드 중복 제거
- [ ] 네이밍 일관성 확인

---

## 🔴 Step 2: Protobuf 디코딩 테스트 ⭐️

### 테스트 작성 (RED)
- [ ] Base64 디코딩 기본 테스트 (valid input)
- [ ] 잘못된 Base64 처리 테스트 (invalid input → error)
- [ ] YFWebSocketMessage Protobuf 디코딩 테스트 (실제 Yahoo Finance 데이터)
- [ ] Protobuf 파싱 오류 테스트 (corrupted data → error)

### 구현 (GREEN)
- [ ] SwiftProtobuf 종속성 추가 (Package.swift)
- [ ] PricingData.proto 파일 추가 (Yahoo Finance 스키마)
- [ ] Base64 디코딩 유틸리티 구현 (기본 디코딩만)
- [ ] YFWebSocketMessageDecoder 구현 (Protobuf → 모델)

### 리팩터링 (REFACTOR)
- [ ] 에러 처리 개선
- [ ] 디코딩 성능 최적화
- [ ] 메서드 분리 (20줄 이하)

---

## 🔴 Step 3: WebSocket 연결 테스트 ⭐️

### 테스트 작성 (RED)
- [ ] Mock WebSocket 연결 성공 테스트 (기본 연결)
- [ ] Mock WebSocket 연결 실패 테스트 (에러 시뮬레이션)
- [ ] 연결 상태 추적 테스트 (disconnected → connecting → connected)
- [ ] URLProtocol 비호환성 우회 (Protocol-Oriented Mock)

### 구현 (GREEN)
- [ ] YFWebSocketManager.swift 생성 (기본 구조)
- [ ] URLSessionWebSocketTask 기반 연결 (connect/disconnect)
- [ ] 연결 상태 열거형 (disconnected, connecting, connected)
- [ ] Mock WebSocket Manager 구현 (테스트용)

### 리팩터링 (REFACTOR)
- [ ] 상태 관리 개선
- [ ] 에러 처리 통합
- [ ] Protocol 인터페이스 정리

---

## 📝 Step 1-3 완료 기준

### 기능 검증
- [ ] 모든 Step 1-3 테스트 통과 (100%)
- [ ] 기본 모델 초기화 성공
- [ ] Protobuf 디코딩 성공 (실제 Yahoo Finance 데이터)
- [ ] Mock WebSocket 연결/해제 성공

### 코드 품질
- [ ] 메서드 크기 20줄 이하
- [ ] 파일 크기 200줄 이하 (Step 1-3)
- [ ] 중복 코드 없음
- [ ] Protocol-Oriented 설계 완료

### 다음 단계 준비
- [ ] Step 4-5를 위한 기반 완성
- [ ] Mock 객체 완전 작동
- [ ] 에러 처리 기본 구조 완성

---

## 🧪 Step 1-3 테스트 예시

### Step 1: 기본 모델 테스트
```swift
@Test("YFWebSocketMessage 초기화 테스트")
func testWebSocketMessageInit() {
    // yfinance/pricing.proto의 PricingData 필드 참조
    let message = YFWebSocketMessage(
        symbol: "AAPL",         // id 필드
        price: 150.0,           // price 필드
        currency: "USD",        // currency 필드
        timestamp: Date()       // time 필드
    )
    
    #expect(message.symbol == "AAPL")
    #expect(message.price == 150.0)
    #expect(message.currency == "USD")
}
```

### Step 2: Protobuf 디코딩 테스트
```swift
@Test("Base64 디코딩 테스트")
func testBase64Decoding() throws {
    // tests/test_live.py에서 추출한 실제 Yahoo Finance 데이터
    let base64Message = """
    CgdCVEMtVVNEFYoMuUcYwLCVgIplIgNVU0QqA0NDQzApOAFFPWrEP0iAgOrxvANVx/25R12csrRHZYD8skR9/
    7i0R7ABgIDq8bwD2AEE4AGAgOrxvAPoAYCA6vG8A/IBA0JUQ4ECAAAAwPrjckGJAgAA2P5ZT3tC
    """
    
    let decoder = YFWebSocketMessageDecoder()
    let message = try decoder.decode(base64Message)
    
    // yfinance test_live.py 예상 결과와 일치 확인
    #expect(message.symbol == "BTC-USD")  // id 필드
    #expect(message.price == 94745.08)    // price 필드
    #expect(message.currency == "USD")    // currency 필드
    #expect(message.exchange == "CCC")    // exchange 필드
}
```

### Step 3: WebSocket 연결 테스트
```swift
@Test("Mock WebSocket 연결 테스트")
func testMockWebSocketConnection() async throws {
    // yfinance/live.py의 BaseWebSocket 패턴 참조
    let mockManager = MockWebSocketManager()
    
    try await mockManager.connect()
    #expect(mockManager.connectionState == .connected)
    
    await mockManager.disconnect()
    #expect(mockManager.connectionState == .disconnected)
}
```

## 📂 yfinance-reference 소스 참조

### Step 1-3에서 참고할 소스 코드
- **`yfinance/pricing.proto`** - PricingData 스키마 (37개 필드 정의)
- **`yfinance/live.py:14-37`** - BaseWebSocket 기본 구조
- **`yfinance/live.py:23-36`** - _decode_message() 구현
- **`tests/test_live.py:8-22`** - 실제 테스트 데이터 및 검증

### 실제 사용 데이터 예시
```python
# tests/test_live.py에서 추출한 실제 Yahoo Finance Base64 메시지
message = ("CgdCVEMtVVNEFYoMuUcYwLCVgIplIgNVU0QqA0NDQzApOAFFPWrEP0iAgOrxvANVx/25R12csrRHZYD8skR9/"
           "7i0R7ABgIDq8bwD2AEE4AGAgOrxvAPoAYCA6vG8A/IBA0JUQ4ECAAAAwPrjckGJAgAA2P5ZT3tC")

# 디코딩 결과
expected = {
    'id': 'BTC-USD', 'price': 94745.08, 'time': '1736509140000', 
    'currency': 'USD', 'exchange': 'CCC', 'quote_type': 41, 
    'market_hours': 1, 'change_percent': 1.5344921, 
    'day_volume': '59712028672', 'day_high': 95227.555, 
    'day_low': 92517.22, 'change': 1431.8906, 
    'open_price': 92529.99, 'circulating_supply': 19808172.0,
    'market_cap': 1876726640000.0
}
```

## 🧪 Protocol-Oriented Testing Pattern

### WebSocket Manager Protocol
```swift
protocol WebSocketManagerProtocol {
    func connect() async throws
    func disconnect() async
    func subscribe(symbols: [String]) async throws
    func messageStream() -> AsyncStream<YFWebSocketMessage>
}

// Mock Implementation
class MockWebSocketManager: WebSocketManagerProtocol {
    var mockMessages: [YFWebSocketMessage] = []
    var shouldFailConnection = false
    
    func connect() async throws {
        if shouldFailConnection {
            throw YFWebSocketError.connectionFailed
        }
    }
    
    func messageStream() -> AsyncStream<YFWebSocketMessage> {
        AsyncStream { continuation in
            for message in mockMessages {
                continuation.yield(message)
            }
            continuation.finish()
        }
    }
}
```

### Protobuf 디코딩 테스트 (yfinance 패턴)
```swift
@Test("Protobuf 메시지 디코딩 테스트")
func testProtobufDecoding() throws {
    // yfinance test_live.py 참조 데이터
    let base64Message = """
    CgdCVEMtVVNEFYoMuUcYwLCVgIplIgNVU0QqA0NDQzApOAFFPWrEP0iAgOrxvANVx/25R12csrRHZYD8skR9/
    7i0R7ABgIDq8bwD2AEE4AGAgOrxvAPoAYCA6vG8A/IBA0JUQ4ECAAAAwPrjckGJAgAA2P5ZT3tC
    """
    
    let decoder = YFWebSocketMessageDecoder()
    let message = try decoder.decode(base64Message)
    
    // 예상 결과 검증
    #expect(message.symbol == "BTC-USD")
    #expect(message.price == 94745.08)
    #expect(message.currency == "USD")
    #expect(message.exchange == "CCC")
}

@Test("잘못된 Protobuf 데이터 처리")
func testInvalidProtobufDecoding() {
    let decoder = YFWebSocketMessageDecoder()
    let invalidBase64 = "invalid_base64_string"
    
    #expect(throws: YFWebSocketError.decodingFailed) {
        try decoder.decode(invalidBase64)
    }
}
```

---

## 🔧 필요한 종속성

### Swift Package Manager
```swift
dependencies: [
    .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.20.0")
]
```

### 파일 구조
```
Sources/SwiftYFinance/
├── Models/
│   ├── YFWebSocketMessage.swift     // Step 1
│   └── YFStreamingQuote.swift       // Step 1
├── Core/
│   ├── YFWebSocketManager.swift     // Step 3
│   └── YFWebSocketMessageDecoder.swift // Step 2
└── Protocols/
    └── WebSocketManagerProtocol.swift  // Step 1

Tests/SwiftYFinanceTests/
├── WebSocket/
│   ├── YFWebSocketMessageTests.swift
│   ├── YFStreamingQuoteTests.swift
│   ├── ProtobufDecodingTests.swift
│   └── WebSocketConnectionTests.swift
└── Mocks/
    └── MockWebSocketManager.swift
```

---

## 🔧 기술 스택

### Swift 기술
- URLSessionWebSocketTask (iOS 13+)
- Swift Concurrency (async/await, AsyncStream)
- Protocol-Oriented Programming

### 외부 종속성
- SwiftProtobuf (Google Protocol Buffers)
- Swift Testing (테스트 프레임워크)

### Yahoo Finance 연동
- WebSocket URL: `wss://streamer.finance.yahoo.com/?version=2`
- Protobuf 메시지: PricingData
- 구독 형식: JSON `{"subscribe": ["AAPL", "TSLA"]}`

### 참조 구현
- **Python yfinance/live.py** (동기/비동기 WebSocket 구현)
- **yfinance/pricing.proto** (Protobuf 스키마 정의)
- **tests/test_live.py** (WebSocket 테스트 패턴)
- 기존 SwiftYFinance 아키텍처 패턴

---

## 💡 TDD 성공 포인트

### ✅ DO (해야 할 것)
- **가장 간단한 테스트**부터 시작 (YFWebSocketMessage 초기화)
- **Mock 객체** 적극 활용 (Protocol-Oriented)
- **하나의 기능씩** 단계별 구현
- **테스트가 실패**하는 것을 확인 후 구현

### ❌ DON'T (하지 말 것)
- 복잡한 통합부터 시작하지 말 것
- 테스트 없이 구현하지 말 것
- 여러 기능을 동시에 구현하지 말 것
- Mock 없이 실제 WebSocket부터 시작하지 말 것

---

**다음 단계**: [Phase 8 Step 4-5: 핵심 기능 구현](phase8-step4-5-core.md)