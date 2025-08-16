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
    let message = YFWebSocketMessage(
        symbol: "AAPL",
        price: 150.0,
        currency: "USD",
        timestamp: Date()
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
    let base64Message = "CgdCVEMtVVNEFYoMuUc..." // 실제 Yahoo Finance 데이터
    let decoder = YFWebSocketMessageDecoder()
    
    let message = try decoder.decode(base64Message)
    #expect(message.symbol == "BTC-USD")
    #expect(message.price > 0)
}
```

### Step 3: WebSocket 연결 테스트
```swift
@Test("Mock WebSocket 연결 테스트")
func testMockWebSocketConnection() async throws {
    let mockManager = MockWebSocketManager()
    
    try await mockManager.connect()
    #expect(mockManager.connectionState == .connected)
    
    await mockManager.disconnect()
    #expect(mockManager.connectionState == .disconnected)
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

**다음 단계**: [Phase 8 Step 4-5: 핵심 기능 구현](phase8-step4-5-core.md)