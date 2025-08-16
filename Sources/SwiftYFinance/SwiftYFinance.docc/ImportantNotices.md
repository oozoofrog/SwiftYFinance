# 주의사항 및 제약사항

SwiftYFinance 사용 시 반드시 알아두어야 할 중요한 사항들입니다.

## 📋 핵심 주의사항

### 1. Yahoo Finance API 정책

**⚠️ 중요**: SwiftYFinance는 Yahoo Finance의 공개 API를 사용하며, 다음 제한사항이 있습니다:

- **상업적 사용 제한**: Yahoo Finance 데이터는 개인적 용도로만 사용해야 합니다
- **재배포 금지**: 조회한 데이터를 제3자에게 재판매하거나 배포할 수 없습니다
- **실시간 거래 금지**: 이 라이브러리의 데이터로 실제 거래를 하지 마세요

### 2. 데이터 정확성 및 지연

```swift
// ❌ 위험: 실시간 거래에 사용
let quote = try await client.fetchQuote(ticker: ticker)
if quote.regularMarketPrice > targetPrice {
    // 실제 거래 실행 - 절대 금지!
}

// ✅ 안전: 분석 및 학습 목적
let quote = try await client.fetchQuote(ticker: ticker)
print("참고용 현재가: \(quote.regularMarketPrice)")
```

**데이터 특성:**
- **지연 데이터**: 15-20분 지연된 데이터일 수 있습니다
- **휴일/휴장**: 시장 휴장일에는 이전 거래일 데이터가 반환됩니다
- **통화 단위**: 각 시장의 기본 통화로 제공됩니다 (USD, KRW 등)

### 3. Rate Limiting 준수

**필수**: Yahoo Finance 서버 보호를 위해 요청 제한을 준수하세요:

```swift
// ✅ 권장: 적절한 간격으로 요청
let symbols = ["AAPL", "MSFT", "GOOGL"]
for symbol in symbols {
    let ticker = YFTicker(symbol: symbol)
    let quote = try await client.fetchQuote(ticker: ticker)
    
    // 요청 간 0.3초 대기 (자동 처리됨)
    print("\(symbol): \(quote.regularMarketPrice)")
}

// ❌ 위험: 동시에 대량 요청
let tasks = symbols.map { symbol in
    Task {
        let ticker = YFTicker(symbol: symbol)
        return try await client.fetchQuote(ticker: ticker)
    }
}
```

### 4. 에러 처리 필수

모든 API 호출에는 반드시 에러 처리를 포함하세요:

```swift
do {
    let ticker = YFTicker(symbol: "INVALID")
    let quote = try await client.fetchQuote(ticker: ticker)
} catch YFError.noDataAvailable {
    print("❌ 해당 심볼의 데이터를 찾을 수 없습니다")
} catch YFError.networkError(let error) {
    print("❌ 네트워크 오류: \(error)")
} catch YFError.rateLimitExceeded {
    print("❌ 요청 제한 초과 - 잠시 후 재시도")
} catch {
    print("❌ 예상치 못한 오류: \(error)")
}
```

## 🔒 보안 및 개인정보

### 1. 인증 정보 관리

```swift
// ✅ 안전: 임시 세션 사용
let client = YFClient() // 기본 설정으로 안전

// ❌ 위험: 개인 인증 정보 하드코딩 금지
// let apiKey = "your-secret-key"  // 절대 금지!
```

### 2. 로깅 주의사항

```swift
// ✅ 안전: 일반 정보만 로깅
print("AAPL 현재가: \(quote.regularMarketPrice)")

// ❌ 위험: 민감한 정보 로깅 금지
print("사용자 쿠키: \(cookieValue)")  // 절대 금지!
```

## 📱 플랫폼 호환성

### 지원 플랫폼
- **macOS**: 15.0 이상
- **iOS**: 18.0 이상  
- **tvOS**: 18.0 이상
- **watchOS**: 11.0 이상

### 성능 고려사항

```swift
// ✅ 권장: 메인 스레드 외에서 API 호출
Task.detached {
    let quote = try await client.fetchQuote(ticker: ticker)
    
    await MainActor.run {
        // UI 업데이트는 메인 스레드에서
        updatePriceLabel(quote.regularMarketPrice)
    }
}

// ❌ 비권장: 메인 스레드에서 직접 호출
let quote = try await client.fetchQuote(ticker: ticker) // UI 블록킹 위험
```

## 💾 데이터 캐싱 및 저장

### 1. 메모리 사용량

```swift
// ✅ 권장: 필요한 데이터만 보관
struct CompactQuote {
    let symbol: String
    let price: Double
    let timestamp: Date
}

// ❌ 비권장: 전체 응답 데이터 장기 보관
var allQuotes: [YFQuote] = [] // 메모리 사용량 증가
```

### 2. 캐시 유효기간

```swift
// ✅ 권장: 적절한 캐시 유효기간 설정
let cacheValidDuration: TimeInterval = 60 // 1분
let cachedTime = Date()

if Date().timeIntervalSince(cachedTime) > cacheValidDuration {
    // 새로운 데이터 요청
}
```

## 🌐 네트워크 환경

### 1. 연결 상태 확인

```swift
import Network

func checkNetworkConnection() -> Bool {
    let monitor = NWPathMonitor()
    var isConnected = false
    
    monitor.pathUpdateHandler = { path in
        isConnected = path.status == .satisfied
    }
    
    return isConnected
}

// API 호출 전 네트워크 상태 확인
if checkNetworkConnection() {
    let quote = try await client.fetchQuote(ticker: ticker)
} else {
    print("❌ 네트워크 연결을 확인하세요")
}
```

### 2. 타임아웃 처리

```swift
// 긴 요청에 대한 타임아웃 설정
func fetchWithTimeout<T>(_ operation: @escaping () async throws -> T) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: 30 * 1_000_000_000) // 30초
            throw YFError.networkTimeout
        }
        
        return try await group.next()!
    }
}
```

## 🛠️ 디버깅 및 문제 해결

### 1. 로그 레벨 설정

```swift
// 개발 중: 상세 로그 활성화
#if DEBUG
YFNetworkLogger.shared.logLevel = .debug
#else 
YFNetworkLogger.shared.logLevel = .error
#endif
```

### 2. 일반적인 오류 해결

**문제**: "Invalid ticker" 오류
```swift
// 해결책: 심볼 형식 확인
let ticker = YFTicker(symbol: "AAPL")   // ✅ 올바른 형식
let ticker = YFTicker(symbol: "Apple")  // ❌ 회사명이 아닌 심볼 사용
```

**문제**: 응답 속도 저하
```swift
// 해결책: 배치 크기 조정
let batchSize = 5 // 기본값 10에서 5로 감소
```

**문제**: 메모리 사용량 증가
```swift
// 해결책: 정기적인 캐시 정리
YFClient.shared.clearCache()
```

## 📖 추가 학습 자료

### 추천 문서
- <doc:GettingStarted> - 기본 사용법
- <doc:ErrorHandling> - 에러 처리 상세 가이드  
- <doc:BestPractices> - 모범 사례
- <doc:PerformanceOptimization> - 성능 최적화

### 외부 참고 자료
- [Yahoo Finance Terms of Use](https://legal.yahoo.com/us/en/yahoo/terms/otos/index.html)
- [Swift Concurrency Guide](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Network Framework Documentation](https://developer.apple.com/documentation/network)

---

⚠️ **면책 조항**: SwiftYFinance는 교육 및 개인 연구 목적으로만 제공됩니다. 실제 투자나 거래 결정에 사용해서는 안 되며, 모든 투자 책임은 사용자에게 있습니다.