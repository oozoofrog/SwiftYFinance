# Phase 8 Step 1-3: WebSocket 기초 구현 (Foundation)

> **목표**: 기본 데이터 모델 → Protobuf 디코딩 → WebSocket 연결 기초  
> **원칙**: TDD (RED → GREEN → REFACTOR)

## 🔴 Step 1: 기본 데이터 모델 테스트 ⭐️

### 테스트 작성 (RED)
- [ ] **Task 1.1**: YFWebSocketMessage 초기화 테스트 (기본 프로퍼티)
  - 📝 **업데이트**: `Tests/SwiftYFinanceTests/WebSocket/YFWebSocketMessageTests.swift` 생성
  - 🔄 **커밋**: `[Behavior] Add YFWebSocketMessage basic initialization tests`
- [ ] **Task 1.2**: YFStreamingQuote 모델 테스트 (price, symbol, timestamp)
  - 📝 **업데이트**: `Tests/SwiftYFinanceTests/WebSocket/YFStreamingQuoteTests.swift` 생성
  - 🔄 **커밋**: `[Behavior] Add YFStreamingQuote model tests`
- [ ] **Task 1.3**: YFWebSocketError 열거형 테스트 (에러 케이스 정의)
  - 📝 **업데이트**: `Tests/SwiftYFinanceTests/WebSocket/YFWebSocketErrorTests.swift` 생성
  - 🔄 **커밋**: `[Behavior] Add YFWebSocketError enum tests`
- [ ] **Task 1.4**: YFWebSocketManager 기본 구조 테스트 (연결 상태 관리)
  - 📝 **업데이트**: `Tests/SwiftYFinanceTests/WebSocket/YFWebSocketManagerTests.swift` 생성
  - 🔄 **커밋**: `[Behavior] Add YFWebSocketManager basic structure tests`

### 구현 (GREEN)
- [ ] **Task 1.5**: YFWebSocketMessage.swift 생성 (기본 프로퍼티만)
  - 📝 **업데이트**: `Sources/SwiftYFinance/Models/YFWebSocketMessage.swift` 생성
  - 🔄 **커밋**: `[Behavior] Implement YFWebSocketMessage basic model`
- [ ] **Task 1.6**: YFStreamingQuote.swift 생성 (price, symbol, timestamp)
  - 📝 **업데이트**: `Sources/SwiftYFinance/Models/YFStreamingQuote.swift` 생성
  - 🔄 **커밋**: `[Behavior] Implement YFStreamingQuote model`
- [ ] **Task 1.7**: YFWebSocketError 케이스 추가 (기본 에러 타입)
  - 📝 **업데이트**: `Sources/SwiftYFinance/Models/YFError.swift` 확장
  - 🔄 **커밋**: `[Behavior] Add YFWebSocketError cases to YFError`
- [ ] **Task 1.8**: YFWebSocketManager 기본 클래스 구현 (상태 관리 포함)
  - 📝 **업데이트**: `Sources/SwiftYFinance/Core/YFWebSocketManager.swift` 생성
  - 🔄 **커밋**: `[Behavior] Implement YFWebSocketManager basic structure`

### 리팩터링 (REFACTOR)
- [ ] **Task 1.9**: 모델 구조 정리 및 최적화
  - 📝 **업데이트**: 모든 Step 1 파일들 리팩터링
  - 🔄 **커밋**: `[Tidy] Refactor Step 1 model structures and optimize`
- [ ] **Task 1.10**: 코드 중복 제거
  - 📝 **업데이트**: 중복 코드 제거 및 공통 유틸리티 추출
  - 🔄 **커밋**: `[Tidy] Remove code duplication in Step 1 implementation`
- [ ] **Task 1.11**: 네이밍 일관성 확인
  - 📝 **업데이트**: 전체 파일의 네이밍 일관성 검토 및 수정
  - 🔄 **커밋**: `[Tidy] Ensure naming consistency in Step 1 components`

---

## 🔴 Step 2: Protobuf 디코딩 테스트 ⭐️

### 테스트 작성 (RED)
- [ ] **Task 2.1**: Base64 디코딩 기본 테스트 (valid input)
  - 📝 **업데이트**: `Tests/SwiftYFinanceTests/WebSocket/ProtobufDecodingTests.swift` 생성
  - 🔄 **커밋**: `[Behavior] Add Base64 decoding basic tests`
- [ ] **Task 2.2**: 잘못된 Base64 처리 테스트 (invalid input → error)
  - 📝 **업데이트**: `ProtobufDecodingTests.swift`에 에러 케이스 추가
  - 🔄 **커밋**: `[Behavior] Add invalid Base64 error handling tests`
- [ ] **Task 2.3**: YFWebSocketMessage Protobuf 디코딩 테스트 (실제 Yahoo Finance 데이터)
  - 📝 **업데이트**: `ProtobufDecodingTests.swift`에 실제 데이터 테스트 추가
  - 🔄 **커밋**: `[Behavior] Add real Yahoo Finance protobuf decoding tests`
- [ ] **Task 2.4**: Protobuf 파싱 오류 테스트 (corrupted data → error)
  - 📝 **업데이트**: `ProtobufDecodingTests.swift`에 파싱 에러 테스트 추가
  - 🔄 **커밋**: `[Behavior] Add protobuf parsing error tests`

### 구현 (GREEN)
- [ ] **Task 2.5**: SwiftProtobuf 종속성 추가 (Package.swift)
  - 📝 **업데이트**: `Package.swift`에 SwiftProtobuf 의존성 추가
  - 🔄 **커밋**: `[Behavior] Add SwiftProtobuf dependency to Package.swift`
- [ ] **Task 2.6**: PricingData.proto 파일 추가 (Yahoo Finance 스키마)
  - 📝 **업데이트**: `Sources/SwiftYFinance/Protobuf/PricingData.proto` 생성
  - 🔄 **커밋**: `[Behavior] Add Yahoo Finance PricingData.proto schema`
- [ ] **Task 2.7**: Base64 디코딩 유틸리티 구현 (기본 디코딩만)
  - 📝 **업데이트**: `Sources/SwiftYFinance/Core/YFWebSocketMessageDecoder.swift` 생성
  - 🔄 **커밋**: `[Behavior] Implement Base64 decoding utility`
- [ ] **Task 2.8**: YFWebSocketMessageDecoder 구현 (Protobuf → 모델)
  - 📝 **업데이트**: `YFWebSocketMessageDecoder.swift` 완성
  - 🔄 **커밋**: `[Behavior] Implement Protobuf to model decoding`

### 리팩터링 (REFACTOR)
- [ ] **Task 2.9**: 에러 처리 개선
  - 📝 **업데이트**: 디코딩 에러 처리 로직 개선
  - 🔄 **커밋**: `[Tidy] Improve error handling in protobuf decoding`
- [ ] **Task 2.10**: 디코딩 성능 최적화
  - 📝 **업데이트**: 디코딩 성능 최적화 적용
  - 🔄 **커밋**: `[Tidy] Optimize protobuf decoding performance`
- [ ] **Task 2.11**: 메서드 분리 (20줄 이하)
  - 📝 **업데이트**: 긴 메서드 분리 및 가독성 개선
  - 🔄 **커밋**: `[Tidy] Split long methods in protobuf decoder`

---

## 🔴 Step 3: WebSocket 연결 테스트 ⭐️

### 테스트 작성 (RED)
- [ ] **Task 3.1**: 실제 WebSocket 연결 성공 테스트 (로컬/원격 서버)
  - 📝 **업데이트**: `Tests/SwiftYFinanceTests/WebSocket/WebSocketConnectionTests.swift` 생성
  - 🔄 **커밋**: `[Behavior] Add real WebSocket connection success tests`
- [ ] **Task 3.2**: WebSocket 연결 실패 테스트 (잘못된 URL)
  - 📝 **업데이트**: `WebSocketConnectionTests.swift`에 실패 케이스 추가
  - 🔄 **커밋**: `[Behavior] Add WebSocket connection failure tests`
- [ ] **Task 3.3**: 연결 상태 추적 테스트 (disconnected → connecting → connected)
  - 📝 **업데이트**: `WebSocketConnectionTests.swift`에 상태 추적 테스트 추가
  - 🔄 **커밋**: `[Behavior] Add connection state tracking tests`
- [ ] **Task 3.4**: 테스트용 API 검증 테스트 (DEBUG 빌드 전용)
  - 📝 **업데이트**: `WebSocketConnectionTests.swift`에 테스트 API 검증 추가
  - 🔄 **커밋**: `[Behavior] Add testing API validation tests`

### 구현 (GREEN)
- [ ] **Task 3.5**: YFWebSocketManager 기본 구조 확장 (연결 기능 추가)
  - 📝 **업데이트**: 기존 `YFWebSocketManager.swift`에 연결 기능 구현
  - 🔄 **커밋**: `[Behavior] Extend YFWebSocketManager with connection functionality`
- [ ] **Task 3.6**: URLSessionWebSocketTask 기반 연결 (connect/disconnect)
  - 📝 **업데이트**: `YFWebSocketManager.swift`에 URLSessionWebSocketTask 구현
  - 🔄 **커밋**: `[Behavior] Implement URLSessionWebSocketTask based connections`
- [ ] **Task 3.7**: 연결 상태 열거형 (disconnected, connecting, connected)
  - 📝 **업데이트**: `YFWebSocketManager.swift`에 ConnectionState enum 추가
  - 🔄 **커밋**: `[Behavior] Add ConnectionState enum for state management`
- [ ] **Task 3.8**: 테스트 지원 API 구현 (#if DEBUG)
  - 📝 **업데이트**: `YFWebSocketManager.swift`에 DEBUG 전용 테스트 API 추가
  - 🔄 **커밋**: `[Behavior] Implement testing support API with DEBUG guards`

### 리팩터링 (REFACTOR)
- [ ] **Task 3.9**: 상태 관리 개선
  - 📝 **업데이트**: 연결 상태 관리 로직 개선 및 최적화
  - 🔄 **커밋**: `[Tidy] Improve connection state management logic`
- [ ] **Task 3.10**: 에러 처리 통합
  - 📝 **업데이트**: WebSocket 관련 에러 처리 통합 및 일관성 확보
  - 🔄 **커밋**: `[Tidy] Integrate and standardize WebSocket error handling`
- [ ] **Task 3.11**: API 인터페이스 정리
  - 📝 **업데이트**: public/internal API 정리 및 문서화
  - 🔄 **커밋**: `[Tidy] Clean up API interfaces and improve documentation`

---

## 📝 Step 1-3 완료 기준

### 기능 검증
- [ ] **Task C.1**: 모든 Step 1-3 테스트 통과 (100%)
  - 📝 **업데이트**: 전체 테스트 실행 결과 확인 및 README 업데이트
  - 🔄 **커밋**: `[Behavior] Verify all Step 1-3 tests pass (100% success rate)`
- [ ] **Task C.2**: 기본 모델 초기화 성공
  - 📝 **업데이트**: 모델 초기화 검증 완료 문서화
  - 🔄 **커밋**: `[Behavior] Confirm basic model initialization success`
- [ ] **Task C.3**: Protobuf 디코딩 성공 (실제 Yahoo Finance 데이터)
  - 📝 **업데이트**: 실제 Yahoo Finance 데이터 디코딩 검증 완료
  - 🔄 **커밋**: `[Behavior] Verify protobuf decoding with real Yahoo Finance data`
- [ ] **Task C.4**: 실제 WebSocket 연결/해제 성공
  - 📝 **업데이트**: WebSocket 연결 기능 검증 완료 문서화
  - 🔄 **커밋**: `[Behavior] Confirm real WebSocket connection/disconnection works`

### 코드 품질
- [ ] **Task Q.1**: 메서드 크기 20줄 이하
  - 📝 **업데이트**: 모든 메서드 크기 검토 및 분리 완료
  - 🔄 **커밋**: `[Tidy] Ensure all methods are under 20 lines`
- [ ] **Task Q.2**: 파일 크기 200줄 이하 (Step 1-3)
  - 📝 **업데이트**: 파일 크기 검토 및 분리 완료
  - 🔄 **커밋**: `[Tidy] Keep Step 1-3 files under 200 lines each`
- [ ] **Task Q.3**: 중복 코드 없음
  - 📝 **업데이트**: 코드 중복 제거 및 공통 유틸리티 추출 완료
  - 🔄 **커밋**: `[Tidy] Remove all code duplication in Step 1-3`
- [ ] **Task Q.4**: 실제 구현 기반 설계 완료
  - 📝 **업데이트**: 설계 문서 업데이트 및 아키텍처 검토 완료
  - 🔄 **커밋**: `[Tidy] Complete real implementation-based design`

### 다음 단계 준비
- [ ] **Task P.1**: Step 4-5를 위한 기반 완성
  - 📝 **업데이트**: Step 4-5 요구사항 기반 구조 준비 완료
  - 🔄 **커밋**: `[Behavior] Prepare foundation for Step 4-5 implementation`
- [ ] **Task P.2**: 실제 WebSocket 기본 동작 완료
  - 📝 **업데이트**: WebSocket 기본 동작 검증 및 문서화
  - 🔄 **커밋**: `[Behavior] Complete basic WebSocket operations`
- [ ] **Task P.3**: 에러 처리 기본 구조 완성
  - 📝 **업데이트**: 에러 처리 패턴 정립 및 문서화
  - 🔄 **커밋**: `[Behavior] Complete basic error handling structure`

---

## 🧪 핵심 테스트 API 가이드

> **유연성 원칙**: 아래 예시는 **방향 제시용**입니다. 더 나은 구현 방법이 있다면 자유롭게 개선하세요.

### 필수 API 시그니처
```swift
// Step 1: 기본 모델
struct YFWebSocketMessage {
    let symbol: String      // yfinance PricingData.id
    let price: Double       // yfinance PricingData.price  
    let timestamp: Date     // yfinance PricingData.time
    let currency: String?   // yfinance PricingData.currency
}

// Step 2: Protobuf 디코딩
class YFWebSocketMessageDecoder {
    func decode(_ base64Message: String) throws -> YFWebSocketMessage
}

// Step 3: WebSocket 연결 + 테스트 지원
class YFWebSocketManager {
    // Production API
    func connect() async throws
    func disconnect() async
    
    // Testing API (#if DEBUG)
    func testGetConnectionState() -> ConnectionState
    func testConnectWithCustomURL(_ url: String) async throws
}
```

### 핵심 테스트 케이스 (1개씩)
```swift
// Step 1: 모델 초기화
@Test func testWebSocketMessageInit() {
    let message = YFWebSocketMessage(symbol: "AAPL", price: 150.0, timestamp: Date(), currency: "USD")
    #expect(message.symbol == "AAPL")
}

// Step 2: 실제 Yahoo Finance 데이터 디코딩
@Test func testYFinanceProtobufDecoding() throws {
    let decoder = YFWebSocketMessageDecoder()
    let message = try decoder.decode("CgdCVEMtVVNE...") // 실제 Base64 데이터
    #expect(message.symbol == "BTC-USD")
}

// Step 3: 실제 WebSocket 연결
@Test func testWebSocketConnection() async throws {
    let manager = YFWebSocketManager()
    try await manager.connect()
    #expect(manager.testGetConnectionState() == .connected)
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

## 🔧 구현 참고사항

### 테스트 지원 설계 패턴
```swift
class YFWebSocketManager {
    // Production API - 최소한의 public 인터페이스
    func connect() async throws
    func disconnect() async
    func messageStream() -> AsyncStream<YFWebSocketMessage>
    
    // Testing API - DEBUG 빌드에서만 사용
    #if DEBUG
    func testGetConnectionState() -> ConnectionState
    func testForceDisconnect() async
    func testConnectWithCustomURL(_ url: String) async throws
    // 기타 테스트 필요한 메서드들...
    #endif
}
```

### yfinance 호환 데이터 구조
```swift
// yfinance/pricing.proto 기반 필수 필드
struct YFWebSocketMessage {
    let symbol: String      // PricingData.id
    let price: Double       // PricingData.price
    let timestamp: Date     // PricingData.time
    let currency: String?   // PricingData.currency
    let exchange: String?   // PricingData.exchange
    let change: Double?     // PricingData.change
    // 필요에 따라 추가 필드들...
}

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

Tests/SwiftYFinanceTests/
├── WebSocket/
│   ├── YFWebSocketMessageTests.swift
│   ├── YFStreamingQuoteTests.swift
│   ├── ProtobufDecodingTests.swift
│   └── WebSocketConnectionTests.swift
└── TestUtilities/
    └── TestDataProvider.swift
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

> **🎯 핵심 원칙**: 아래는 **가이드라인**입니다. 더 효과적인 방법을 찾으면 **적극 적용**하세요.

### ✅ DO (권장사항)
- **가장 간단한 테스트**부터 시작 
- **실제 구현체** 기반 테스트 (실제 Yahoo Finance 데이터 활용)
- **하나의 기능씩** 단계별 구현
- **API 시그니처** 먼저 정의 후 구현

### ❌ DON'T (주의사항)
- 복잡한 통합부터 시작하지 말 것
- 테스트 없이 구현하지 말 것  
- 여러 기능을 동시에 구현하지 말 것

### 🔄 유연성 유지
- **더 나은 설계**가 떠오르면 주저 없이 변경
- **yfinance 호환성**은 유지하되 Swift다운 API 설계
- **테스트용 API**는 필요에 따라 추가/수정

---

**다음 단계**: [Phase 8 Step 4-5: 핵심 기능 구현](phase8-step4-5-core.md)