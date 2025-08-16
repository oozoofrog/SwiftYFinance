# Phase 8 WebSocket 실시간 스트리밍 구현 체크리스트

> **📋 통합 체크리스트**: 전체 개요 및 진행 상황 추적  
> **🔧 세부 가이드**: 단계별 상세 구현 문서 참조

## 🎯 TDD 구현 로드맵

### ⭐️ Step 1-3: 기초 구현 (Foundation)
**📄 세부 문서**: [Phase 8 Step 1-3: 기초 구현](phase8-step1-3-foundation.md)

- [ ] **Step 1**: 기본 데이터 모델 (YFWebSocketMessage, YFStreamingQuote)
- [ ] **Step 2**: Protobuf 디코딩 (Base64 → PricingData → 모델)
- [ ] **Step 3**: WebSocket 연결 기초 (Mock 기반 연결 관리)

### 🔧 Step 4-5: 핵심 기능 (Core)  
**📄 세부 문서**: [Phase 8 Step 4-5: 핵심 기능](phase8-step4-5-core.md)

- [ ] **Step 4**: 구독 관리 (JSON 메시지, 상태 추적)
- [ ] **Step 5**: 메시지 스트리밍 (AsyncStream, 실시간 처리)

### 🚀 Step 6-7: 고급 기능 (Advanced)
**📄 세부 문서**: [Phase 8 Step 6-7: 고급 기능](phase8-step6-7-advanced.md)

- [ ] **Step 6**: 재연결 & 고급 기능 (exponential backoff, 다중 구독)
- [ ] **Step 7**: YFClient 통합 & 최적화 (기존 아키텍처 연동)

---

## 📊 전체 진행 상황

### 🔴 Red: 테스트 작성
- [ ] Step 1-3 기초 테스트 (총 12개 테스트)
- [ ] Step 4-5 핵심 테스트 (총 8개 테스트)  
- [ ] Step 6-7 고급 테스트 (총 8개 테스트)
- [ ] 성능 & 스트레스 테스트 (총 6개 테스트)

### 🟢 Green: 구현  
- [ ] Step 1-3 기초 구현 (4개 모듈)
- [ ] Step 4-5 핵심 구현 (4개 모듈)
- [ ] Step 6-7 고급 구현 (4개 모듈)
- [ ] 통합 & 최적화 (2개 모듈)

### 🔵 Refactor: 개선
- [ ] 성능 최적화 (메시지 처리, 메모리 관리)
- [ ] 코드 품질 (중복 제거, 메서드 크기 최적화)
- [ ] 모니터링 & 디버깅 (연결 상태, 메시지 통계)

## 🟢 Green: 구현 (TDD 순서에 맞춘 단계별 구현)

> **구현 원칙**: 테스트를 통과시키는 **최소한의 코드**만 작성  
> **점진적 개선**: 각 단계마다 테스트 → 구현 → 리팩터링

### 1단계 구현: 기본 데이터 모델 ⭐️ (우선순위 1)
- [ ] YFWebSocketMessage.swift 생성 (기본 프로퍼티만)
- [ ] YFStreamingQuote.swift 생성 (price, symbol, timestamp)
- [ ] YFWebSocketError 케이스 추가 (기본 에러 타입)
- [ ] WebSocketManagerProtocol 정의 (Mock을 위한 인터페이스)

### 2단계 구현: Protobuf 디코딩 ⭐️ (우선순위 2)
- [ ] SwiftProtobuf 종속성 추가 (Package.swift)
- [ ] PricingData.proto 파일 추가 (Yahoo Finance 스키마)
- [ ] Base64 디코딩 유틸리티 구현 (기본 디코딩만)
- [ ] YFWebSocketMessageDecoder 구현 (Protobuf → 모델)

### 3단계 구현: WebSocket 연결 기초 ⭐️ (우선순위 3)
- [ ] YFWebSocketManager.swift 생성 (기본 구조)
- [ ] URLSessionWebSocketTask 기반 연결 (connect/disconnect)
- [ ] 연결 상태 열거형 (disconnected, connecting, connected)
- [ ] Mock WebSocket Manager 구현 (테스트용)

### 4단계 구현: 구독 관리 기초 (우선순위 4)
- [ ] 구독 상태 관리 (activeSubscriptions: Set<String>)
- [ ] JSON 메시지 생성 (`{"subscribe": [symbols]}`)
- [ ] 단일 심볼 구독 메서드 (subscribe/unsubscribe)
- [ ] 중복 구독 방지 로직

### 5단계 구현: 메시지 스트리밍 기초 (우선순위 5)
- [ ] AsyncStream 기본 구현 (messageStream 메서드)
- [ ] 메시지 수신 및 파싱 연동
- [ ] Swift Concurrency 지원 (async/await)
- [ ] 기본 에러 처리

### 6단계 구현: 고급 기능 (우선순위 6)
- [ ] 자동 재연결 로직 구현 (exponential backoff)
- [ ] 다중 심볼 구독 지원
- [ ] 타임아웃 처리 구현
- [ ] 연결 상태 모니터링 개선

### 7단계 구현: YFClient 통합 및 최적화 (우선순위 7)
- [ ] YFWebSocketAPI.swift 생성 (YFClient 확장)
- [ ] 실시간 스트리밍 퍼블릭 API 구현
- [ ] 기존 세션과 통합 (인증, Rate Limiting)
- [ ] 성능 최적화 및 메모리 관리

## 🔵 Refactor: 개선

### 성능 최적화
- [ ] 메시지 처리 성능 최적화
- [ ] 메모리 사용량 모니터링
- [ ] 백그라운드 처리 최적화
- [ ] 배치 구독 처리 구현

### 코드 품질
- [ ] 중복 코드 제거
- [ ] 메서드 크기 최적화 (20줄 이하)
- [ ] 파일 크기 확인 (300줄 이하)
- [ ] 의존성 주입 패턴 적용

### 모니터링 & 디버깅
- [ ] 연결 상태 추적
- [ ] 메시지 통계 수집
- [ ] 디버그 로깅 구현
- [ ] 성능 메트릭 수집

## 📚 문서화

### DocC 문서
- [ ] YFWebSocketManager 문서화
- [ ] YFStreamingQuote 문서화
- [ ] YFClient WebSocket 메서드 문서화
- [ ] 실시간 스트리밍 사용 예시 추가

### 가이드 문서
- [ ] WebSocket 기본 사용법 가이드
- [ ] 고급 스트리밍 기능 가이드
- [ ] 에러 처리 및 문제 해결 가이드
- [ ] 성능 최적화 가이드

## ✅ 완료 기준

### 기능 검증
- [ ] 모든 테스트 통과 (100%)
- [ ] 실제 WebSocket 연결 성공
- [ ] AAPL, MSFT, TSLA 실시간 스트리밍 성공
- [ ] 다중 심볼 동시 스트리밍 검증

### 성능 검증
- [ ] 메시지 지연시간 < 100ms
- [ ] 메모리 누수 없음
- [ ] 30분 이상 안정적 연결 유지
- [ ] 초당 100개 이상 메시지 처리 가능

### 품질 검증
- [ ] 에러 복구 완전성 검증
- [ ] 스레드 안전성 검증
- [ ] 백그라운드/포그라운드 전환 검증
- [ ] 다양한 네트워크 상황 테스트

### 최종 확인
- [ ] 코드 리뷰 완료
- [ ] 문서화 완료
- [ ] 기존 기능과 호환성 확인
- [ ] 커밋 및 푸시

---

## 🎯 TDD 구현 로드맵 (RED → GREEN → REFACTOR)

### ⭐️ 1단계: 기본 데이터 모델 (가장 간단한 시작점)
**RED**: 기본 모델 초기화 테스트 → **GREEN**: 최소 구현 → **REFACTOR**: 정리

### ⭐️ 2단계: Protobuf 디코딩 (외부 종속성 포함)
**RED**: Base64 디코딩 테스트 → **GREEN**: SwiftProtobuf 통합 → **REFACTOR**: 에러 처리

### ⭐️ 3단계: WebSocket 연결 기초 (Mock 기반)
**RED**: Mock 연결 테스트 → **GREEN**: Protocol 기반 구현 → **REFACTOR**: 상태 관리

### 4단계: 구독 관리 (JSON 메시지)
**RED**: 구독 상태 테스트 → **GREEN**: Set 기반 관리 → **REFACTOR**: 중복 제거

### 5단계: 메시지 스트리밍 (AsyncStream)
**RED**: 스트리밍 테스트 → **GREEN**: AsyncStream 구현 → **REFACTOR**: 동시성 최적화

### 6단계: 고급 기능 (재연결, 타임아웃)
**RED**: 복구 테스트 → **GREEN**: 재시도 로직 → **REFACTOR**: 성능 튜닝

### 7단계: YFClient 통합 (기존 아키텍처 연동)
**RED**: 통합 테스트 → **GREEN**: API 확장 → **REFACTOR**: 전체 정리

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

**현재 진행 상황**: 🚀 Phase 8 WebSocket 스트리밍 준비 완료

## 🔧 기술 스택

### Swift 기술
- URLSessionWebSocketTask (iOS 13+)
- Swift Concurrency (async/await, AsyncStream)
- Combine (선택적)

### 외부 종속성
- SwiftProtobuf (Google Protocol Buffers)
- Swift Testing (테스트 프레임워크)

### Yahoo Finance 연동
- WebSocket URL: `wss://streamer.finance.yahoo.com/?version=2`
- Protobuf 메시지: PricingData
- 구독 형식: JSON `{"subscribe": ["AAPL", "TSLA"]}`

### 참조 구현
- Python yfinance/live.py (동기/비동기 WebSocket)
- 기존 SwiftYFinance 아키텍처 패턴
- Phase 6 검색 기능 구현 경험

---

## 🧪 테스트 방법론 상세

### 1. Protocol-Oriented Testing Pattern

```swift
// WebSocket Manager Protocol
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

### 2. AsyncStream 테스트 패턴

```swift
// Swift Testing 방식
@Test("WebSocket 메시지 스트림 테스트")
func testWebSocketMessageStream() async {
    let mockManager = MockWebSocketManager()
    mockManager.mockMessages = createTestMessages(count: 5)
    
    await confirmation(expectedCount: 5) { confirm in
        for await message in mockManager.messageStream() {
            // 메시지 검증
            #expect(message.symbol != nil)
            #expect(message.price > 0)
            confirm()
        }
    }
}

// XCTest 방식  
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

### 3. Protobuf 디코딩 테스트 (yfinance 패턴)

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

### 4. 에러 처리 및 재연결 테스트

```swift
@Test("연결 실패 및 재시도 테스트")
func testConnectionRetry() async {
    let mockManager = MockWebSocketManager()
    mockManager.shouldFailConnection = true
    
    // 첫 번째 연결 실패 확인
    await #expect(throws: YFWebSocketError.connectionFailed) {
        try await mockManager.connect()
    }
    
    // 재시도 로직 테스트
    mockManager.shouldFailConnection = false
    try await mockManager.connect()
    
    // 연결 성공 확인
    #expect(mockManager.isConnected == true)
}
```

### 5. 성능 테스트 패턴

```swift
@Test("대량 메시지 처리 성능 테스트")
func testHighVolumeMessageProcessing() async {
    let mockManager = MockWebSocketManager()
    mockManager.mockMessages = createTestMessages(count: 1000)
    
    let startTime = Date()
    var messageCount = 0
    
    for await message in mockManager.messageStream() {
        messageCount += 1
        // 처리 로직 시뮬레이션
    }
    
    let duration = Date().timeIntervalSince(startTime)
    #expect(messageCount == 1000)
    #expect(duration < 1.0) // 1초 내 처리 완료
}
```

### 6. 테스트 데이터 생성 유틸리티

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

func createMockProtobufData() -> String {
    // 실제 Yahoo Finance WebSocket 메시지 Base64 데이터
    return "CgdCVEMtVVNEFYoMuUcYwLCVgIplIgNVU0Q..."
}
```

### 🔍 테스트 검증 체크리스트

- [ ] **단위 테스트**: 각 클래스/메서드 독립적 테스트
- [ ] **통합 테스트**: Mock 서버를 통한 전체 플로우 테스트  
- [ ] **성능 테스트**: 메시지 처리 속도, 메모리 사용량
- [ ] **에러 시나리오**: 모든 실패 케이스 및 복구 로직
- [ ] **스레드 안전성**: 동시성 환경에서의 안정성
- [ ] **실제 데이터**: Yahoo Finance 실제 메시지 포맷 검증