# Phase 8 Step 4-5: WebSocket 핵심 기능 구현 (Core)

> **목표**: 구독 관리 → 메시지 스트리밍 핵심 기능  
> **전제조건**: Step 1-3 완료 (기본 모델, Protobuf, 연결 기초)

## 🔴 Step 4: 구독 관리 테스트

### 테스트 작성 (RED)
- [ ] **Task 4.1**: 단일 심볼 구독 테스트 (`{"subscribe": ["AAPL"]}`)
  - 📝 **업데이트**: `Tests/SwiftYFinanceTests/WebSocket/SubscriptionManagementTests.swift` 생성
  - 🔄 **커밋**: `[Behavior] Add single symbol subscription tests`
- [ ] **Task 4.2**: 구독 상태 추적 테스트 (active subscriptions Set)
  - 📝 **업데이트**: `SubscriptionManagementTests.swift`에 상태 추적 테스트 추가
  - 🔄 **커밋**: `[Behavior] Add subscription state tracking tests`
- [ ] **Task 4.3**: 중복 구독 방지 테스트 (같은 심볼 재구독)
  - 📝 **업데이트**: `SubscriptionManagementTests.swift`에 중복 방지 테스트 추가
  - 🔄 **커밋**: `[Behavior] Add duplicate subscription prevention tests`
- [ ] **Task 4.4**: 구독 해제 테스트 (심볼 제거)
  - 📝 **업데이트**: `SubscriptionManagementTests.swift`에 구독 해제 테스트 추가
  - 🔄 **커밋**: `[Behavior] Add subscription unsubscribe tests`

### 구현 (GREEN)
- [ ] **Task 4.5**: 구독 상태 관리 (activeSubscriptions: Set<String>)
  - 📝 **업데이트**: `YFWebSocketManager.swift`에 구독 상태 관리 추가
  - 🔄 **커밋**: `[Behavior] Implement subscription state management`
- [ ] **Task 4.6**: JSON 메시지 생성 (`{"subscribe": [symbols]}`)
  - 📝 **업데이트**: `YFWebSocketManager.swift`에 JSON 메시지 생성 로직 추가
  - 🔄 **커밋**: `[Behavior] Implement JSON subscription message generation`
- [ ] **Task 4.7**: 단일 심볼 구독 메서드 (subscribe/unsubscribe)
  - 📝 **업데이트**: `YFWebSocketManager.swift`에 구독/해제 메서드 구현
  - 🔄 **커밋**: `[Behavior] Implement subscribe/unsubscribe methods`
- [ ] **Task 4.8**: 중복 구독 방지 로직
  - 📝 **업데이트**: `YFWebSocketManager.swift`에 중복 방지 로직 추가
  - 🔄 **커밋**: `[Behavior] Implement duplicate subscription prevention logic`

### 리팩터링 (REFACTOR)
- [ ] **Task 4.9**: 구독 관리 로직 최적화
  - 📝 **업데이트**: 구독 관리 성능 최적화 및 메모리 효율성 개선
  - 🔄 **커밋**: `[Tidy] Optimize subscription management logic`
- [ ] **Task 4.10**: JSON 생성 유틸리티 분리
  - 📝 **업데이트**: JSON 생성 로직을 별도 유틸리티로 분리
  - 🔄 **커밋**: `[Tidy] Extract JSON generation utility`
- [ ] **Task 4.11**: 에러 처리 개선
  - 📝 **업데이트**: 구독 관련 에러 처리 로직 개선
  - 🔄 **커밋**: `[Tidy] Improve subscription error handling`

---

## 🔴 Step 5: 메시지 스트리밍 테스트

### 테스트 작성 (RED)
- [ ] **Task 5.1**: AsyncStream 기본 메시지 수신 테스트 (실제 데이터)
  - 📝 **업데이트**: `Tests/SwiftYFinanceTests/WebSocket/MessageStreamingTests.swift` 생성
  - 🔄 **커밋**: `[Behavior] Add AsyncStream basic message receiving tests`
- [ ] **Task 5.2**: 실시간 가격 업데이트 테스트 (price, change 검증)
  - 📝 **업데이트**: `MessageStreamingTests.swift`에 실시간 가격 테스트 추가
  - 🔄 **커밋**: `[Behavior] Add real-time price update tests`
- [ ] **Task 5.3**: 메시지 순서 테스트 (시간순 정렬)
  - 📝 **업데이트**: `MessageStreamingTests.swift`에 메시지 순서 테스트 추가
  - 🔄 **커밋**: `[Behavior] Add message ordering tests`
- [ ] **Task 5.4**: AsyncStream 메시지 수신 테스트 (`confirmation(expectedCount:)`)
  - 📝 **업데이트**: `MessageStreamingTests.swift`에 confirmation 패턴 테스트 추가
  - 🔄 **커밋**: `[Behavior] Add AsyncStream confirmation pattern tests`

### 구현 (GREEN)
- [ ] **Task 5.5**: AsyncStream 기본 구현 (messageStream 메서드)
  - 📝 **업데이트**: `YFWebSocketManager.swift`에 AsyncStream 구현 추가
  - 🔄 **커밋**: `[Behavior] Implement AsyncStream messageStream method`
- [ ] **Task 5.6**: 메시지 수신 및 파싱 연동
  - 📝 **업데이트**: `YFWebSocketManager.swift`에 Protobuf 디코더 연동
  - 🔄 **커밋**: `[Behavior] Integrate message receiving with protobuf parsing`
- [ ] **Task 5.7**: Swift Concurrency 지원 (async/await)
  - 📝 **업데이트**: `YFWebSocketManager.swift`에 Swift Concurrency 패턴 적용
  - 🔄 **커밋**: `[Behavior] Implement Swift Concurrency support`
- [ ] **Task 5.8**: 기본 에러 처리
  - 📝 **업데이트**: `YFWebSocketManager.swift`에 스트리밍 에러 처리 추가
  - 🔄 **커밋**: `[Behavior] Implement basic streaming error handling`

### 리팩터링 (REFACTOR)
- [ ] **Task 5.9**: AsyncStream 성능 최적화
  - 📝 **업데이트**: AsyncStream 성능 최적화 및 메모리 효율성 개선
  - 🔄 **커밋**: `[Tidy] Optimize AsyncStream performance`
- [ ] **Task 5.10**: 메시지 파싱 로직 개선
  - 📝 **업데이트**: 메시지 파싱 로직 리팩터링 및 가독성 개선
  - 🔄 **커밋**: `[Tidy] Improve message parsing logic`
- [ ] **Task 5.11**: 동시성 처리 최적화
  - 📝 **업데이트**: Swift Concurrency 패턴 최적화
  - 🔄 **커밋**: `[Tidy] Optimize concurrency handling`

---

## 📝 Step 4-5 완료 기준

### 기능 검증
- [ ] **Task C.1**: 모든 Step 4-5 테스트 통과 (100%)
  - 📝 **업데이트**: 구독 관리 및 메시지 스트리밍 테스트 결과 확인 및 문서화
  - 🔄 **커밋**: `[Behavior] Verify all Step 4-5 tests pass (100% success rate)`
- [ ] **Task C.2**: 단일/다중 심볼 구독 성공
  - 📝 **업데이트**: 구독 기능 검증 완료 문서화
  - 🔄 **커밋**: `[Behavior] Confirm single/multiple symbol subscription success`
- [ ] **Task C.3**: AsyncStream 메시지 수신 성공
  - 📝 **업데이트**: AsyncStream 기능 검증 완료 문서화
  - 🔄 **커밋**: `[Behavior] Verify AsyncStream message receiving works`
- [ ] **Task C.4**: 실시간 가격 데이터 파싱 성공
  - 📝 **업데이트**: 실시간 데이터 파싱 검증 완료 문서화
  - 🔄 **커밋**: `[Behavior] Confirm real-time price data parsing success`

### 성능 검증
- [ ] **Task P.1**: 구독 상태 변경 지연시간 < 100ms
  - 📝 **업데이트**: 구독 성능 측정 결과 문서화
  - 🔄 **커밋**: `[Behavior] Verify subscription state change latency under 100ms`
- [ ] **Task P.2**: 메시지 스트리밍 지연시간 < 200ms
  - 📝 **업데이트**: 메시지 스트리밍 성능 측정 결과 문서화
  - 🔄 **커밋**: `[Behavior] Verify message streaming latency under 200ms`
- [ ] **Task P.3**: 메모리 누수 없음 (기본 테스트)
  - 📝 **업데이트**: 메모리 누수 테스트 결과 문서화
  - 🔄 **커밋**: `[Behavior] Confirm no memory leaks in basic operations`

### 코드 품질
- [ ] **Task Q.1**: 메서드 크기 20줄 이하 유지
  - 📝 **업데이트**: 모든 메서드 크기 검토 및 분리 완료
  - 🔄 **커밋**: `[Tidy] Ensure all Step 4-5 methods are under 20 lines`
- [ ] **Task Q.2**: 파일 크기 250줄 이하 (Step 4-5)
  - 📝 **업데이트**: 파일 크기 검토 및 분리 완료
  - 🔄 **커밋**: `[Tidy] Keep Step 4-5 files under 250 lines each`
- [ ] **Task Q.3**: AsyncStream 올바른 사용
  - 📝 **업데이트**: AsyncStream 사용 패턴 검토 및 최적화
  - 🔄 **커밋**: `[Tidy] Ensure proper AsyncStream usage patterns`
- [ ] **Task Q.4**: 스레드 안전성 확보
  - 📝 **업데이트**: 동시성 처리 안전성 검토 완료
  - 🔄 **커밋**: `[Tidy] Ensure thread safety in Step 4-5 implementation`

### 다음 단계 준비
- [ ] **Task N.1**: Step 6-7을 위한 기반 완성
  - 📝 **업데이트**: Step 6-7 요구사항 기반 구조 준비
  - 🔄 **커밋**: `[Behavior] Prepare foundation for Step 6-7 advanced features`
- [ ] **Task N.2**: 재연결 로직을 위한 구조 준비
  - 📝 **업데이트**: 재연결 기능을 위한 아키텍처 준비
  - 🔄 **커밋**: `[Behavior] Prepare structure for reconnection logic`
- [ ] **Task N.3**: 성능 측정 기반 마련
  - 📝 **업데이트**: 성능 측정 도구 및 메트릭 기반 구축
  - 🔄 **커밋**: `[Behavior] Establish performance measurement foundation`

---

## 🧪 핵심 API 가이드 (Step 4-5)

> **유연성 원칙**: 더 효율적인 API 설계가 있다면 **적극 채택**하세요.

### 필수 API 시그니처
```swift
// Step 4: 구독 관리
class YFWebSocketManager {
    func subscribe(symbols: [String]) async throws
    func unsubscribe(symbols: [String]) async throws
    
    // Testing API (#if DEBUG)
    func testGetActiveSubscriptions() -> Set<String>
    func testGetSubscribeCallCount() -> Int
    func testClearSubscriptions()
}

// Step 5: 메시지 스트리밍  
extension YFWebSocketManager {
    func messageStream() -> AsyncStream<YFWebSocketMessage>
}
```

### 핵심 테스트 케이스 (각 Step별 1개)
```swift
// Step 4: 구독 관리 검증
@Test func testSymbolSubscription() async throws {
    let manager = YFWebSocketManager()
    try await manager.connect()
    try await manager.subscribe(symbols: ["AAPL"])
    
    let subscriptions = manager.testGetActiveSubscriptions()
    #expect(subscriptions.contains("AAPL"))
}

// Step 5: 실시간 메시지 수신 검증
@Test func testRealTimeMessageStream() async throws {
    let manager = YFWebSocketManager()
    try await manager.connect()
    try await manager.subscribe(symbols: ["AAPL"])
    
    var receivedMessage: YFWebSocketMessage?
    for await message in manager.messageStream() {
        receivedMessage = message
        break // 첫 번째 메시지만 확인
    }
    
    #expect(receivedMessage?.symbol == "AAPL")
    #expect(receivedMessage?.price ?? 0 > 0)
}
```

---

## 🔧 Step 4-5 구현 세부사항

### 구현 참고사항

#### yfinance 호환 구독 메시지 형식
```swift
// yfinance/live.py:238-249 참조
let subscribeMessage = ["subscribe": ["AAPL", "TSLA"]]
let unsubscribeMessage = ["unsubscribe": ["AAPL"]]
```

#### 중복 방지 로직
```swift
func subscribe(symbols: [String]) async throws {
    let newSymbols = Set(symbols).subtracting(activeSubscriptions)
    guard !newSymbols.isEmpty else { return } // 중복 시 early return
    // 실제 구독 로직...
}
```

#### 테스트 지원 패턴  
```swift
#if DEBUG
func testGetActiveSubscriptions() -> Set<String> { /* 내부 상태 노출 */ }
func testClearSubscriptions() { /* 테스트 초기화 */ }
#endif
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

## 🎯 성능 및 품질 목표

> **측정 기준**: 아래는 **참고 목표**입니다. 실제 환경에 맞게 조정하세요.

### 성능 목표
- 구독 요청 처리: < 100ms
- 메시지 수신 지연: < 200ms  
- 메모리 사용량: < 10MB

### 품질 검증
```swift
// 기본 검증 패턴
#expect(message.symbol != nil)
#expect(message.price > 0)
#expect(message.timestamp != nil)

// Swift Testing confirmation 패턴  
await confirmation(expectedCount: 3) { confirm in
    for await message in stream { confirm() }
}
```

---

## 🔄 유연성 유지 가이드

### 설계 개선 권장사항
- **더 나은 API 패턴**을 발견하면 적극 적용
- **yfinance 호환성** 유지하되 Swift 관례 우선  
- **테스트 지원 API**는 실제 필요에 따라 조정
- **성능 최적화**가 필요하면 주저 없이 리팩터링

### 구현 우선순위
1. **동작하는 최소 구현** 먼저
2. **실제 Yahoo Finance 연동** 확인
3. **API 설계 개선** 및 최적화

---

**이전 단계**: [Phase 8 Step 1-3: 기초 구현](phase8-step1-3-foundation.md)  
**다음 단계**: [Phase 8 Step 6-7: 고급 기능 구현](phase8-step6-7-advanced.md)