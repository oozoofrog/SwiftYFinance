# Phase 8 Step 6-7: WebSocket 고급 기능 구현 (Advanced)

> **목표**: 재연결 & 고급 기능 → YFClient 통합 & 최적화  
> **전제조건**: Step 1-5 완료 (기초 + 핵심 기능)

## 🔴 Step 6: 고급 기능 테스트

### 테스트 작성 (RED)
- [ ] 연결 재시도 로직 테스트 (exponential backoff)
- [ ] 다중 심볼 구독 테스트 (`{"subscribe": ["AAPL", "TSLA"]}`)
- [ ] 타임아웃 처리 테스트 (연결 및 메시지 수신)
- [ ] 네트워크 연결 끊김 테스트 (연결 복구 확인)

### 구현 (GREEN)
- [ ] 자동 재연결 로직 구현 (exponential backoff)
- [ ] 다중 심볼 구독 지원
- [ ] 타임아웃 처리 구현
- [ ] 연결 상태 모니터링 개선

### 리팩터링 (REFACTOR)
- [ ] 재연결 로직 최적화
- [ ] 에러 복구 메커니즘 개선
- [ ] 상태 관리 통합

---

## 🔴 Step 7: YFClient 통합 테스트

### 테스트 작성 (RED)
- [ ] YFClient WebSocket API 통합 테스트
- [ ] 기존 기능과 호환성 테스트
- [ ] 인증 세션 연동 테스트
- [ ] Rate Limiting 통합 테스트

### 구현 (GREEN)
- [ ] YFWebSocketAPI.swift 생성 (YFClient 확장)
- [ ] 실시간 스트리밍 퍼블릭 API 구현
- [ ] 기존 세션과 통합 (인증, Rate Limiting)
- [ ] 성능 최적화 및 메모리 관리

### 리팩터링 (REFACTOR)
- [ ] 전체 아키텍처 정리
- [ ] API 인터페이스 최적화
- [ ] 문서화 및 예시 추가

---

## 📝 Step 6-7 완료 기준

### 고급 기능 검증
- [ ] 자동 재연결 성공 (네트워크 끊김 시)
- [ ] 다중 심볼 동시 스트리밍 (10+ 심볼)
- [ ] 타임아웃 처리 정상 작동
- [ ] 백그라운드/포그라운드 전환 안정성

### 통합 기능 검증
- [ ] YFClient API 완전 작동
- [ ] 기존 기능과 충돌 없음
- [ ] 인증 세션 정상 연동
- [ ] Rate Limiting 적용 확인

### 성능 및 안정성
- [ ] 30분 이상 연결 유지
- [ ] 초당 100+ 메시지 처리
- [ ] 메모리 사용량 < 50MB
- [ ] CPU 사용량 < 10%

### 최종 품질 검증
- [ ] 모든 테스트 통과 (100%)
- [ ] 코드 리뷰 완료
- [ ] 문서화 완료
- [ ] 배포 준비 완료

---

## 🧪 Step 6-7 테스트 예시

### Step 6: 고급 기능 테스트
```swift
@Test("자동 재연결 테스트")
func testAutoReconnection() async {
    let mockManager = MockWebSocketManager()
    mockManager.enableReconnection = true
    
    // 초기 연결
    try await mockManager.connect()
    #expect(mockManager.connectionState == .connected)
    
    // 연결 끊김 시뮬레이션
    mockManager.simulateDisconnection()
    #expect(mockManager.connectionState == .disconnected)
    
    // 자동 재연결 확인 (최대 10초 대기)
    await waitForConnection(mockManager, timeout: 10)
    #expect(mockManager.connectionState == .connected)
    #expect(mockManager.reconnectionAttempts > 0)
}

@Test("다중 심볼 구독 테스트")
func testMultipleSymbolSubscription() async throws {
    let mockManager = MockWebSocketManager()
    let symbols = ["AAPL", "TSLA", "MSFT", "GOOGL", "AMZN"]
    
    try await mockManager.subscribe(symbols: symbols)
    
    #expect(mockManager.activeSubscriptions.count == 5)
    for symbol in symbols {
        #expect(mockManager.activeSubscriptions.contains(symbol))
    }
    
    // 구독 메시지 검증
    let expectedMessage = #"{"subscribe":["AAPL","TSLA","MSFT","GOOGL","AMZN"]}"#
    #expect(mockManager.lastSentMessage.contains("subscribe"))
}

@Test("타임아웃 처리 테스트")
func testTimeoutHandling() async {
    let mockManager = MockWebSocketManager()
    mockManager.connectionTimeout = 5.0 // 5초 타임아웃
    mockManager.simulateSlowConnection = true
    
    await #expect(throws: YFWebSocketError.connectionTimeout) {
        try await mockManager.connect()
    }
    
    #expect(mockManager.connectionState == .disconnected)
}
```

### Step 7: YFClient 통합 테스트
```swift
@Test("YFClient WebSocket API 통합 테스트")
func testYFClientWebSocketIntegration() async throws {
    let client = YFClient()
    
    // WebSocket 스트리밍 시작
    let stream = try await client.startRealTimeStreaming(symbols: ["AAPL"])
    
    var messageCount = 0
    let expectation = XCTestExpectation(description: "Real-time messages")
    expectation.expectedFulfillmentCount = 5
    
    for await message in stream {
        #expect(message.symbol == "AAPL")
        #expect(message.price > 0)
        messageCount += 1
        expectation.fulfill()
        
        if messageCount >= 5 { break }
    }
    
    await fulfillment(of: [expectation], timeout: 30)
    
    // 스트리밍 종료
    try await client.stopRealTimeStreaming()
}

@Test("기존 기능 호환성 테스트")
func testBackwardCompatibility() async throws {
    let client = YFClient()
    
    // 기존 기능 테스트 (영향 없어야 함)
    let quote = try await client.fetchQuote(symbol: "AAPL")
    #expect(quote.symbol == "AAPL")
    
    let history = try await client.fetchPriceHistory(
        symbol: "AAPL", 
        period: .oneDay
    )
    #expect(!history.isEmpty)
    
    // WebSocket 기능과 동시 사용
    let stream = try await client.startRealTimeStreaming(symbols: ["AAPL"])
    
    // 동시 실행 확인
    async let liveData = stream.first(where: { _ in true })
    async let historicalData = client.fetchQuote(symbol: "AAPL")
    
    let (live, historical) = try await (liveData, historicalData)
    #expect(live?.symbol == historical.symbol)
}
```

---

## 🔧 Step 6-7 구현 세부사항

### 자동 재연결 로직
```swift
class YFWebSocketManager {
    private var reconnectionAttempts = 0
    private let maxReconnectionAttempts = 5
    private var reconnectionDelay: TimeInterval = 1.0
    
    private func attemptReconnection() async {
        guard reconnectionAttempts < maxReconnectionAttempts else {
            connectionState = .failed
            return
        }
        
        connectionState = .reconnecting
        reconnectionAttempts += 1
        
        // Exponential backoff
        try? await Task.sleep(nanoseconds: UInt64(reconnectionDelay * 1_000_000_000))
        reconnectionDelay = min(reconnectionDelay * 2, 30) // 최대 30초
        
        do {
            try await connect()
            reconnectionAttempts = 0
            reconnectionDelay = 1.0
        } catch {
            await attemptReconnection()
        }
    }
}
```

### YFClient 확장
```swift
// YFWebSocketAPI.swift
extension YFClient {
    /// 실시간 스트리밍 시작
    /// yfinance.Ticker.live 메서드와 유사한 API 제공
    public func startRealTimeStreaming(symbols: [String]) async throws -> AsyncStream<YFStreamingQuote> {
        let webSocketManager = YFWebSocketManager(session: session)
        try await webSocketManager.connect()
        try await webSocketManager.subscribe(symbols: symbols)
        
        return webSocketManager.messageStream()
            .compactMap { message in
                YFStreamingQuote(from: message)
            }
            .eraseToAnyAsyncSequence()
    }
    
    /// 실시간 스트리밍 종료
    public func stopRealTimeStreaming() async throws {
        await webSocketManager?.disconnect()
        webSocketManager = nil
    }
}
```

## 📂 yfinance-reference 소스 참조

### Step 6-7에서 참고할 소스 코드
- **`yfinance/base.py:37`** - WebSocket import 및 통합 패턴
- **`yfinance/tickers.py:27`** - WebSocket 다중 심볼 처리
- **`yfinance/live.py:15-21`** - 연결 관리 및 URL 설정
- **`yfinance/__init__.py:28`** - 퍼블릭 API 노출 패턴

---

## 📊 Step 6-7 성능 목표

### 고급 기능 성능
- 재연결 시간: < 5초 (exponential backoff)
- 다중 구독 처리: < 1초 (10개 심볼)
- 타임아웃 감지: < 설정값 + 500ms

### 통합 성능
- API 응답 시간: < 100ms
- 동시 기능 사용: 성능 저하 < 10%
- 메모리 증가: < 20MB (기존 대비)

### 안정성 목표
- 연속 운영: 24시간 이상
- 메모리 누수: 0
- 크래시 발생률: < 0.01%

---

## 🎯 Step 6-7 최적화 포인트

### 메모리 최적화
- AsyncStream 버퍼 크기 제한
- 메시지 객체 재사용
- 약한 참조 활용

### 성능 최적화
- 메시지 파싱 병렬화
- 구독 상태 캐싱
- 네트워크 요청 배칭

### 안정성 개선
- 에러 복구 자동화
- 상태 불일치 방지
- 로깅 및 모니터링 강화

---

## 🧪 고급 테스트 패턴

### 에러 처리 및 재연결 테스트
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

### 성능 테스트 패턴
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

### 🔍 테스트 검증 체크리스트
- [ ] **단위 테스트**: 각 클래스/메서드 독립적 테스트
- [ ] **통합 테스트**: Mock 서버를 통한 전체 플로우 테스트  
- [ ] **성능 테스트**: 메시지 처리 속도, 메모리 사용량
- [ ] **에러 시나리오**: 모든 실패 케이스 및 복구 로직
- [ ] **스레드 안전성**: 동시성 환경에서의 안정성

---

**이전 단계**: [Phase 8 Step 4-5: 핵심 기능 구현](phase8-step4-5-core.md)  
**메인 문서**: [Phase 8 WebSocket 스트리밍 체크리스트](websocket-streaming-checklist.md)