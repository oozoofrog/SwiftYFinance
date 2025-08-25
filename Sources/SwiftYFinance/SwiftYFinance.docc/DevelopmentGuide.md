# Development Guide

SwiftYFinance 개발에 참여하기 위한 가이드

## Overview

SwiftYFinance는 **TDD (Test-Driven Development)**와 **Tidy First** 방법론을 엄격히 따라 개발되었습니다. 이 가이드는 프로젝트의 개발 원칙과 기여 방법을 설명합니다.

## 개발 원칙

### TDD (Test-Driven Development)

SwiftYFinance의 모든 기능은 TDD 사이클을 따라 개발됩니다:

```
🔴 Red → 🟢 Green → 🟡 Refactor
```

#### 1. 🔴 Red - 실패하는 테스트 작성

```swift
// 예시: 새로운 기능 추가 시
func testYFQuoteServiceFetchesMultipleQuotes() async throws {
    let service = YFQuoteService()
    let symbols = ["AAPL", "GOOGL", "MSFT"]
    
    let quotes = try await service.fetchQuotes(symbols: symbols)
    
    XCTAssertEqual(quotes.count, 3)
    XCTAssertNotNil(quotes["AAPL"])
    XCTAssertNotNil(quotes["GOOGL"]) 
    XCTAssertNotNil(quotes["MSFT"])
}
```

#### 2. 🟢 Green - 최소한의 코드로 테스트 통과

```swift
// 테스트를 통과시키는 최소한의 구현
extension YFQuoteService {
    func fetchQuotes(symbols: [String]) async throws -> [String: YFQuote] {
        // 최소한의 구현으로 테스트만 통과
        var result: [String: YFQuote] = [:]
        for symbol in symbols {
            result[symbol] = YFQuote(symbol: symbol, regularMarketPrice: 0.0, regularMarketTime: Date())
        }
        return result
    }
}
```

#### 3. 🟡 Refactor - 코드 개선

```swift
// 리팩토링된 실제 구현
extension YFQuoteService {
    func fetchQuotes(symbols: [String]) async throws -> [String: YFQuote] {
        let urlBuilder = YFQuoteURLBuilder()
        let parameters = YFQuoteParameters(symbols: symbols)
        let request = urlBuilder.buildRequest(parameters: parameters)
        
        let response = try await session.execute(request, responseType: YFQuoteResponse.self)
        return response.result.reduce(into: [:]) { dict, quote in
            dict[quote.symbol] = quote
        }
    }
}
```

### Tidy First 원칙

모든 변경사항은 구조적 변경과 기능적 변경을 분리합니다:

#### 구조적 변경 ([Tidy])
```bash
git commit -m "[Tidy] Extract YFQuoteService protocol"
git commit -m "[Tidy] Rename fetchData to fetchQuotes for clarity"
```

#### 기능적 변경 ([Feature])
```bash
git commit -m "[Feature] Add multi-symbol quote fetching"
git commit -m "[Feature] Implement real-time WebSocket streaming"
```

## 개발 환경 설정

### 1. 요구사항

- Swift 6.1+
- Xcode 16.0+
- macOS 15.0+

### 2. 프로젝트 클론 및 설정

```bash
git clone https://github.com/your-org/SwiftYFinance.git
cd SwiftYFinance

# 의존성 해결
swift package resolve

# 테스트 실행
swift test
```

### 3. 개발 워크플로우

```bash
# 1. 새로운 기능 브랜치 생성
git checkout -b feature/websocket-streaming

# 2. TDD 사이클 따르기
# - 실패하는 테스트 작성
# - 최소한의 코드로 통과
# - 리팩토링

# 3. 테스트 실행
swift test --filter WebSocketTests

# 4. 전체 테스트 실행
swift test

# 5. 커밋 (Tidy First 원칙 적용)
git add .
git commit -m "[Feature] Add WebSocket streaming support"

# 6. Push 및 PR 생성
git push origin feature/websocket-streaming
```

## 코드 품질 가이드

### 1. Swift 코딩 스타일

```swift
// ✅ 좋은 예
struct YFQuoteService {
    private let session: YFSession
    private let urlBuilder: YFQuoteURLBuilder
    
    init(session: YFSession = YFSession()) {
        self.session = session
        self.urlBuilder = YFQuoteURLBuilder()
    }
    
    func fetchQuote(symbol: String) async throws -> YFQuote? {
        let quotes = try await fetchQuotes(symbols: [symbol])
        return quotes[symbol]
    }
}

// ❌ 나쁜 예
struct YFQuoteService {
    var session:YFSession // 접근 제어 없음
    
    func fetchQuote(_ s:String) async throws -> YFQuote? { // 매개변수명 불명확
        // 구현...
    }
}
```

### 2. 에러 처리

```swift
// ✅ 구체적인 에러 타입 사용
enum YFServiceError: Error, LocalizedError {
    case invalidSymbol(String)
    case networkFailure(Error)
    case dataParsingError
    
    var errorDescription: String? {
        switch self {
        case .invalidSymbol(let symbol):
            return "Invalid symbol: \(symbol)"
        case .networkFailure(let error):
            return "Network error: \(error.localizedDescription)"
        case .dataParsingError:
            return "Failed to parse response data"
        }
    }
}
```

### 3. 테스트 작성 가이드

```swift
// ✅ 설명적인 테스트명
func testYFQuoteServiceFetchesValidQuoteForAppleStock() async throws {
    // Given
    let service = YFQuoteService()
    let symbol = "AAPL"
    
    // When
    let quote = try await service.fetchQuote(symbol: symbol)
    
    // Then
    XCTAssertNotNil(quote)
    XCTAssertEqual(quote?.symbol, "AAPL")
    XCTAssertGreaterThan(quote?.regularMarketPrice ?? 0, 0)
}

// ✅ 에러 케이스 테스트
func testYFQuoteServiceThrowsErrorForInvalidSymbol() async throws {
    let service = YFQuoteService()
    let invalidSymbol = "INVALID_SYMBOL_12345"
    
    do {
        _ = try await service.fetchQuote(symbol: invalidSymbol)
        XCTFail("Expected error for invalid symbol")
    } catch YFError.invalidSymbol(let symbol) {
        XCTAssertEqual(symbol, invalidSymbol)
    }
}
```

## 기여 프로세스

### 1. Issue 생성

새로운 기능이나 버그 수정을 위해 먼저 Issue를 생성합니다:

```markdown
**Feature Request: WebSocket Real-time Streaming**

**Description:**
Implement WebSocket-based real-time price streaming following the TDD methodology.

**Acceptance Criteria:**
- [ ] Can connect to Yahoo Finance WebSocket
- [ ] Can subscribe to multiple symbols
- [ ] Handles connection failures gracefully
- [ ] Provides AsyncStream interface
- [ ] Has comprehensive test coverage

**Technical Notes:**
- Follow existing YFService protocol pattern
- Use Actor for thread-safe state management
- Implement reconnection logic
```

### 2. TDD 개발 과정

```swift
// 1단계: 실패하는 테스트 작성
class YFWebSocketManagerTests: XCTestCase {
    func testWebSocketCanConnect() async throws {
        let manager = YFWebSocketManager()
        
        try await manager.connect()
        
        let state = await manager.connectionState
        XCTAssertEqual(state, .connected)
    }
}

// 2단계: 최소 구현
actor YFWebSocketManager {
    private(set) var connectionState: ConnectionState = .disconnected
    
    func connect() async throws {
        // 최소한의 구현
        connectionState = .connected
    }
}

// 3단계: 실제 구현으로 리팩토링
actor YFWebSocketManager {
    private var webSocketTask: URLSessionWebSocketTask?
    private(set) var connectionState: ConnectionState = .disconnected
    
    func connect() async throws {
        let url = URL(string: "wss://streamer.finance.yahoo.com")!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        connectionState = .connected
    }
}
```

### 3. Pull Request 가이드라인

```markdown
**[Feature] Add WebSocket Real-time Streaming**

**Changes Made:**
- ✅ Added YFWebSocketManager with Actor-based thread safety
- ✅ Implemented connection management and automatic reconnection
- ✅ Added comprehensive test suite (15 tests, 100% coverage)
- ✅ Followed TDD methodology throughout development
- ✅ Applied Tidy First principles (separate structural commits)

**Test Results:**
```
swift test --filter WebSocketTests
Test Suite 'WebSocketTests' passed at 2025-01-15 10:30:25.123.
     Executed 15 tests, with 0 failures (0 unexpected) in 2.847 seconds
```

**Breaking Changes:**
None

**Migration Guide:**
N/A - This is a new feature
```

## 성능 및 품질 확인

### 1. 테스트 실행

```bash
# 모든 테스트 실행
swift test

# 특정 테스트 실행
swift test --filter YFQuoteServiceTests

# 병렬 테스트 비활성화 (네트워크 테스트)
swift test --parallel

# 성능 테스트
swift test --filter PerformanceTests
```

### 2. 메모리 누수 확인

```bash
# Instruments를 사용한 메모리 프로파일링
xcodebuild test -scheme SwiftYFinance -enableAddressSanitizer YES
```

### 3. 코드 커버리지

```bash
swift test --enable-code-coverage
```

## 문서화

### 1. DocC 문서 업데이트

새로운 public API는 반드시 문서화해야 합니다:

```swift
/// WebSocket을 통한 실시간 Yahoo Finance 데이터 스트리밍 관리자
/// 
/// `YFWebSocketManager`는 Yahoo Finance WebSocket API에 연결하여
/// 실시간 주식 가격 데이터를 스트리밍합니다.
///
/// ```swift
/// let manager = YFWebSocketManager()
/// try await manager.connect()
/// try await manager.subscribe(symbols: ["AAPL", "GOOGL"])
/// 
/// for await update in manager.priceStream {
///     print("\(update.symbol): $\(update.price)")
/// }
/// ```
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public actor YFWebSocketManager {
    /// WebSocket 연결 상태
    public enum ConnectionState {
        case disconnected, connecting, connected, failed
    }
    
    /// 현재 연결 상태
    public private(set) var connectionState: ConnectionState = .disconnected
}
```

### 2. 예제 코드 업데이트

새로운 기능은 README와 문서에 예제를 추가해야 합니다.

## 릴리즈 프로세스

### 1. 버전 관리

SwiftYFinance는 [Semantic Versioning](https://semver.org/)을 따릅니다:

- **Major (X.0.0)**: Breaking changes
- **Minor (0.X.0)**: New features, backward compatible  
- **Patch (0.0.X)**: Bug fixes, backward compatible

### 2. 릴리즈 체크리스트

- [ ] 모든 테스트 통과
- [ ] 문서 업데이트
- [ ] CHANGELOG.md 업데이트
- [ ] Version tag 생성
- [ ] GitHub Release 생성

## 문제 해결

### 1. 테스트 실패

```bash
# 특정 테스트만 실행하여 디버깅
swift test --filter testSpecificFunction

# Verbose 모드로 자세한 정보 확인
swift test --verbose
```

### 2. 빌드 에러

```bash
# 클린 빌드
swift package clean
swift build

# 의존성 재설정
swift package reset
swift package resolve
```

## 참고 자료

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Test-Driven Development](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
- [Tidy First? by Kent Beck](https://www.oreilly.com/library/view/tidy-first/9781098151232/)
- [SwiftYFinance Architecture](doc:Architecture)

---

이 가이드를 따라 SwiftYFinance의 높은 코드 품질을 유지하며 기여해주시기 바랍니다. 질문이 있으시면 GitHub Issues를 통해 문의해주세요.