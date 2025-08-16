# Phase 8 Step 6-7: WebSocket 고급 기능 구현 (Advanced)

> **목표**: 재연결 & 고급 기능 → YFClient 통합 & 최적화  
> **전제조건**: Step 1-5 완료 (기초 + 핵심 기능)

## 🔴 Step 6: 고급 기능 테스트

### 테스트 작성 (RED)
- [ ] **Task 6.1**: 연결 재시도 로직 테스트 (exponential backoff)
  - 📝 **업데이트**: `Tests/SwiftYFinanceTests/WebSocket/ReconnectionTests.swift` 생성
  - 🔄 **커밋**: `[Behavior] Add connection retry logic tests with exponential backoff`
- [ ] **Task 6.2**: 다중 심볼 구독 테스트 (`{"subscribe": ["AAPL", "TSLA"]}`)
  - 📝 **업데이트**: `SubscriptionManagementTests.swift`에 다중 심볼 테스트 추가
  - 🔄 **커밋**: `[Behavior] Add multiple symbol subscription tests`
- [ ] **Task 6.3**: 타임아웃 처리 테스트 (연결 및 메시지 수신)
  - 📝 **업데이트**: `ReconnectionTests.swift`에 타임아웃 테스트 추가
  - 🔄 **커밋**: `[Behavior] Add timeout handling tests for connection and messaging`
- [ ] **Task 6.4**: 네트워크 연결 끊김 테스트 (연결 복구 확인)
  - 📝 **업데이트**: `ReconnectionTests.swift`에 네트워크 끊김 테스트 추가
  - 🔄 **커밋**: `[Behavior] Add network disconnection recovery tests`

### 구현 (GREEN)
- [ ] **Task 6.5**: 자동 재연결 로직 구현 (exponential backoff)
  - 📝 **업데이트**: `YFWebSocketManager.swift`에 재연결 로직 구현
  - 🔄 **커밋**: `[Behavior] Implement auto-reconnection with exponential backoff`
- [ ] **Task 6.6**: 다중 심볼 구독 지원
  - 📝 **업데이트**: `YFWebSocketManager.swift`에 다중 심볼 구독 기능 확장
  - 🔄 **커밋**: `[Behavior] Implement multiple symbol subscription support`
- [ ] **Task 6.7**: 타임아웃 처리 구현
  - 📝 **업데이트**: `YFWebSocketManager.swift`에 타임아웃 처리 로직 추가
  - 🔄 **커밋**: `[Behavior] Implement timeout handling for connections and messages`
- [ ] **Task 6.8**: 연결 상태 모니터링 개선
  - 📝 **업데이트**: `YFWebSocketManager.swift`에 상태 모니터링 기능 개선
  - 🔄 **커밋**: `[Behavior] Improve connection state monitoring`

### 리팩터링 (REFACTOR)
- [ ] **Task 6.9**: 재연결 로직 최적화
  - 📝 **업데이트**: 재연결 로직 성능 및 안정성 최적화
  - 🔄 **커밋**: `[Tidy] Optimize reconnection logic for better performance`
- [ ] **Task 6.10**: 에러 복구 메커니즘 개선
  - 📝 **업데이트**: 에러 복구 로직 개선 및 안정성 향상
  - 🔄 **커밋**: `[Tidy] Improve error recovery mechanisms`
- [ ] **Task 6.11**: 상태 관리 통합
  - 📝 **업데이트**: 연결 상태 관리 로직 통합 및 일관성 확보
  - 🔄 **커밋**: `[Tidy] Integrate and standardize state management`

---

## 🔴 Step 7: YFClient 통합 테스트

### 테스트 작성 (RED)
- [ ] **Task 7.1**: YFClient WebSocket API 통합 테스트
  - 📝 **업데이트**: `Tests/SwiftYFinanceTests/WebSocket/YFClientIntegrationTests.swift` 생성
  - 🔄 **커밋**: `[Behavior] Add YFClient WebSocket API integration tests`
- [ ] **Task 7.2**: 기존 기능과 호환성 테스트
  - 📝 **업데이트**: `YFClientIntegrationTests.swift`에 호환성 테스트 추가
  - 🔄 **커밋**: `[Behavior] Add backward compatibility tests for existing features`
- [ ] **Task 7.3**: 인증 세션 연동 테스트
  - 📝 **업데이트**: `YFClientIntegrationTests.swift`에 세션 연동 테스트 추가
  - 🔄 **커밋**: `[Behavior] Add authentication session integration tests`
- [ ] **Task 7.4**: Rate Limiting 통합 테스트
  - 📝 **업데이트**: `YFClientIntegrationTests.swift`에 Rate Limiting 테스트 추가
  - 🔄 **커밋**: `[Behavior] Add Rate Limiting integration tests`

### 구현 (GREEN)
- [ ] **Task 7.5**: YFWebSocketAPI.swift 생성 (YFClient 확장)
  - 📝 **업데이트**: `Sources/SwiftYFinance/API/YFWebSocketAPI.swift` 생성
  - 🔄 **커밋**: `[Behavior] Create YFWebSocketAPI as YFClient extension`
- [ ] **Task 7.6**: 실시간 스트리밍 퍼블릭 API 구현
  - 📝 **업데이트**: `YFWebSocketAPI.swift`에 public API 구현
  - 🔄 **커밋**: `[Behavior] Implement public real-time streaming API`
- [ ] **Task 7.7**: 기존 세션과 통합 (인증, Rate Limiting)
  - 📝 **업데이트**: `YFWebSocketAPI.swift`에 기존 세션 통합
  - 🔄 **커밋**: `[Behavior] Integrate with existing session management`
- [ ] **Task 7.8**: 성능 최적화 및 메모리 관리
  - 📝 **업데이트**: `YFWebSocketAPI.swift`에 성능 최적화 구현
  - 🔄 **커밋**: `[Behavior] Implement performance optimization and memory management`

### 리팩터링 (REFACTOR)
- [ ] **Task 7.9**: 전체 아키텍처 정리
  - 📝 **업데이트**: 전체 WebSocket 아키텍처 정리 및 일관성 확보
  - 🔄 **커밋**: `[Tidy] Clean up overall WebSocket architecture`
- [ ] **Task 7.10**: API 인터페이스 최적화
  - 📝 **업데이트**: Public API 인터페이스 최적화 및 사용성 개선
  - 🔄 **커밋**: `[Tidy] Optimize API interfaces for better usability`
- [ ] **Task 7.11**: 문서화 및 예시 추가
  - 📝 **업데이트**: API 문서화 및 사용 예시 추가
  - 🔄 **커밋**: `[Tidy] Add comprehensive documentation and usage examples`

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

## 🧪 핵심 API 가이드 (Step 6-7)

> **고급 기능 원칙**: 복잡성보다는 **안정성과 사용성**을 우선시하세요.

### Step 6: 고급 기능 테스트
```swift
@Test("자동 재연결 테스트")
func testAutoReconnection() async {
    let manager = YFWebSocketManager()
    manager.testEnableAutoReconnection = true
    
    // 초기 연결
    try await manager.connect()
    #expect(manager.testGetConnectionState() == .connected)
    
    // 테스트용 API로 연결 강제 종료
    await manager.testForceDisconnect()
    #expect(manager.testGetConnectionState() == .disconnected)
    
    // 자동 재연결 확인 (최대 30초 대기)
    await manager.testWaitForReconnection(timeout: 30)
    #expect(manager.testGetConnectionState() == .connected)
    #expect(manager.testGetReconnectionAttempts() > 0)
}

@Test("다중 심볼 구독 테스트")
func testMultipleSymbolSubscription() async throws {
    let manager = YFWebSocketManager()
    try await manager.connect()
    
    let symbols = ["AAPL", "TSLA", "MSFT", "GOOGL", "AMZN"]
    try await manager.subscribe(symbols: symbols)
    
    // 테스트용 API로 구독 상태 확인
    let activeSubscriptions = manager.testGetActiveSubscriptions()
    #expect(activeSubscriptions.count == 5)
    
    for symbol in symbols {
        #expect(activeSubscriptions.contains(symbol))
    }
    
    // 실제 메시지 수신 확인
    var receivedSymbols: Set<String> = []
    
    for await message in manager.messageStream() {
        receivedSymbols.insert(message.symbol)
        
        if receivedSymbols.count >= 3 { // 최소 3개 심볼에서 메시지 수신
            break
        }
    }
    
    #expect(receivedSymbols.count >= 3)
}

@Test("타임아웃 처리 테스트")
func testTimeoutHandling() async {
    let manager = YFWebSocketManager()
    manager.connectionTimeout = 5.0 // 5초 타임아웃
    
    // 잘못된 URL로 연결 시도 (타임아웃 발생)
    let invalidURL = "wss://invalid-websocket-server.com"
    manager.serverURL = invalidURL
    
    await #expect(throws: YFWebSocketError.connectionTimeout) {
        try await manager.connect()
    }
    
    #expect(manager.connectionState == .disconnected)
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
    let manager = YFWebSocketManager()
    manager.maxRetryAttempts = 3
    
    // 잘못된 URL로 첫 번째 연결 시도
    manager.serverURL = "wss://invalid-server.com"
    
    await #expect(throws: YFWebSocketError.connectionFailed) {
        try await manager.connect()
    }
    
    // 올바른 URL로 재시도
    manager.serverURL = "wss://streamer.finance.yahoo.com/?version=2"
    try await manager.connect()
    
    // 연결 성공 확인
    #expect(manager.connectionState == .connected)
}
```

### 성능 테스트 패턴
```swift
@Test("대량 메시지 처리 성능 테스트")
func testHighVolumeMessageProcessing() async {
    let manager = YFWebSocketManager()
    try await manager.connect()
    
    // 여러 심볼 구독으로 대량 메시지 생성
    let symbols = ["AAPL", "TSLA", "MSFT", "GOOGL", "AMZN", "META", "NFLX", "NVDA"]
    try await manager.subscribe(symbols: symbols)
    
    let startTime = Date()
    var messageCount = 0
    
    // 30초 동안 대량 메시지 처리
    for await message in manager.messageStream() {
        messageCount += 1
        
        // 메시지 처리 성능 확인
        #expect(message.price > 0)
        #expect(message.symbol != nil)
        
        if Date().timeIntervalSince(startTime) > 30 || messageCount >= 1000 {
            break
        }
    }
    
    let duration = Date().timeIntervalSince(startTime)
    let messagesPerSecond = Double(messageCount) / duration
    
    #expect(messageCount > 100) // 최소 100개 메시지
    #expect(messagesPerSecond > 10) // 초당 10개 이상
}
```

### 🔍 테스트 검증 체크리스트
- [ ] **단위 테스트**: 각 클래스/메서드 독립적 테스트
- [ ] **통합 테스트**: 실제 WebSocket 서버를 통한 전체 플로우 테스트  
- [ ] **성능 테스트**: 실시간 메시지 처리 속도, 메모리 사용량
- [ ] **에러 시나리오**: 실제 네트워크 실패 케이스 및 복구 로직
- [ ] **스레드 안전성**: 동시성 환경에서의 안정성

---

## 🔄 유연성 유지 가이드

### 고급 기능 설계 원칙
- **자동 재연결**: 실제 필요성에 따라 구현 여부 결정
- **YFClient 통합**: 기존 API와 **일관성** 우선
- **성능 최적화**: 측정 후 실제 병목점만 해결
- **테스트 전략**: 실제 환경에서 동작 확인 우선

### 구현 우선순위  
1. **기본 동작 완성** (Step 1-5 기반)
2. **실제 사용 시나리오** 검증
3. **고급 기능 추가** (필요 시)
4. **성능 및 안정성 개선**

### 설계 개선 권장
- **더 Simple한 API**가 가능하면 적극 채택
- **복잡한 기능**은 실제 요구사항 확인 후 구현
- **테스트 지원**은 실제 개발 과정에서 필요한 것만 추가

---

**이전 단계**: [Phase 8 Step 4-5: 핵심 기능 구현](phase8-step4-5-core.md)  
**메인 문서**: [Phase 8 WebSocket 스트리밍 체크리스트](websocket-streaming-checklist.md)