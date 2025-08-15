# Authentication

SwiftYFinance의 인증 시스템과 고급 설정

## Overview

SwiftYFinance는 Yahoo Finance API에 안정적으로 접근하기 위해 고급 인증 시스템을 제공합니다. Chrome 브라우저를 모방하는 기술을 통해 API 차단을 방지하고, 자동 CSRF 인증을 지원합니다.

## Browser Impersonation

SwiftYFinance는 Chrome 136 브라우저를 모방하여 Yahoo Finance의 차단을 우회합니다:

### 자동 브라우저 모방

기본적으로 모든 요청이 자동으로 Chrome 브라우저처럼 보이도록 처리됩니다:

```swift
let client = YFClient()
// 모든 요청이 자동으로 Chrome 136으로 인식됩니다

let ticker = try YFTicker(symbol: "AAPL")
let quote = try await client.fetchQuote(ticker: ticker)
```

### 브라우저 설정 커스터마이징

필요시 브라우저 모방 설정을 조정할 수 있습니다:

```swift
// 브라우저 설정 확인
let impersonator = YFBrowserImpersonator()
print("User-Agent: \(impersonator.userAgent)")
print("HTTP 버전: HTTP/2")

// 헤더 정보 확인
let headers = impersonator.getHeaders()
for (key, value) in headers {
    print("\(key): \(value)")
}
```

## CSRF Authentication

Yahoo Finance는 특정 API 엔드포인트에 대해 CSRF 토큰을 요구합니다. SwiftYFinance는 이를 자동으로 처리합니다:

### 자동 CSRF 처리

```swift
let session = YFSession()

// CSRF 인증이 필요한 경우 자동으로 처리됨
do {
    try await session.authenticateCSRF()
    print("CSRF 인증 완료")
} catch {
    print("CSRF 인증 실패: \(error)")
    // 기본 전략으로 폴백
}

// 인증 상태 확인
let isAuthenticated = await session.isCSRFAuthenticated
print("인증 상태: \(isAuthenticated)")
```

### 수동 인증

특별한 경우에는 수동으로 인증을 수행할 수 있습니다:

```swift
let client = YFClient()

// 인증이 필요한 고급 API 사용 전에 수동 인증
do {
    let session = client.session
    try await session.authenticateCSRF()
    
    // 이제 모든 API 호출이 인증된 상태로 수행됩니다
    let financials = try await client.fetchFinancials(ticker: ticker)
    
} catch YFError.authenticationFailed {
    print("인증 실패. 기본 API만 사용 가능합니다.")
} catch {
    print("인증 중 에러: \(error)")
}
```

## Rate Limiting

SwiftYFinance는 지능형 Rate Limiting을 제공하여 API 제한을 자동으로 관리합니다:

### 자동 Rate Limiting

```swift
// Rate Limiter가 자동으로 요청 간격을 조절합니다
let symbols = ["AAPL", "GOOGL", "MSFT", "AMZN", "TSLA"]

for symbol in symbols {
    let ticker = try YFTicker(symbol: symbol)
    let quote = try await client.fetchQuote(ticker: ticker)
    print("\(symbol): $\(quote.regularMarketPrice)")
    
    // Rate limiter가 자동으로 적절한 딜레이를 추가
}
```

### Rate Limiting 설정 조정

```swift
let rateLimiter = YFRateLimiter.shared

// 현재 설정 확인
print("최소 간격: \(rateLimiter.minimumInterval)초")
print("최대 동시 요청: \(rateLimiter.maxConcurrentRequests)")

// 더 보수적인 설정 (권장)
rateLimiter.minimumInterval = 0.5 // 0.5초
rateLimiter.maxConcurrentRequests = 1
```

### 대량 요청 처리

많은 종목을 처리할 때는 적절한 배치 처리를 사용하세요:

```swift
let symbols = Array(1...100).map { "SYMBOL\($0)" } // 100개 종목
let batchSize = 10

for batch in symbols.chunked(into: batchSize) {
    print("배치 처리 시작: \(batch.count)개 종목")
    
    for symbol in batch {
        do {
            let ticker = try YFTicker(symbol: symbol)
            let quote = try await client.fetchQuote(ticker: ticker)
            print("\(symbol): $\(quote.regularMarketPrice)")
            
        } catch {
            print("\(symbol) 실패: \(error)")
        }
        
        // 각 요청 사이에 딜레이
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2초
    }
    
    // 배치 사이에 더 긴 딜레이
    try await Task.sleep(nanoseconds: 2_000_000_000) // 2초
    print("배치 완료. 2초 대기 중...")
}
```

## Cookie Management

SwiftYFinance는 고급 쿠키 관리 시스템을 제공합니다:

### 자동 쿠키 관리

```swift
let cookieManager = YFCookieManager()

// Yahoo Finance 쿠키 자동 추출 및 관리
let session = YFSession()
try await session.authenticateCSRF()

// 쿠키 상태 확인
if cookieManager.hasValidCookies() {
    print("✅ 유효한 쿠키 보유")
} else {
    print("❌ 쿠키 갱신 필요")
}
```

### 쿠키 캐시 관리

```swift
// 쿠키 캐시 정리
cookieManager.clearExpiredCookies()

// 모든 쿠키 삭제 (문제 해결 시)
cookieManager.clearAllCookies()
print("쿠키 캐시가 정리되었습니다.")
```

## Network Configuration

네트워크 설정을 커스터마이징할 수 있습니다:

### 타임아웃 설정

```swift
// 커스텀 타임아웃 설정
let session = YFSession()
session.requestTimeout = 30.0 // 30초

// 긴 타임아웃이 필요한 요청
let longRunningData = try await client.fetchHistory(
    ticker: ticker,
    period: .fiveYears // 5년치 데이터
)
```

### 프록시 설정

기업 환경에서 프록시를 사용하는 경우:

```swift
// 주의: 실제 구현은 URLSessionConfiguration을 통해 수행
let session = YFSession()

// 시스템 프록시 설정 사용
// 일반적으로 자동으로 처리되지만, 필요시 수동 설정 가능
```

## Error Recovery

인증 실패 시 자동 복구 메커니즘:

### 자동 재시도

```swift
func robustFetch<T>(operation: () async throws -> T) async throws -> T {
    var retryCount = 0
    let maxRetries = 3
    
    while retryCount < maxRetries {
        do {
            return try await operation()
            
        } catch YFError.authenticationFailed {
            retryCount += 1
            
            if retryCount < maxRetries {
                print("인증 실패. \(retryCount)/\(maxRetries) 재시도 중...")
                
                // 새로운 인증 시도
                let session = YFSession()
                try await session.authenticateCSRF()
                
                // 지수 백오프
                let delay = pow(2.0, Double(retryCount))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } else {
                throw error
            }
            
        } catch {
            throw error
        }
    }
    
    throw YFError.authenticationFailed
}

// 사용 예제
let quote = try await robustFetch {
    try await client.fetchQuote(ticker: ticker)
}
```

## Security Best Practices

### 1. API 키 없음

SwiftYFinance는 API 키가 필요 없습니다. Yahoo Finance의 공개 데이터를 사용합니다.

### 2. 사용량 모니터링

```swift
// 요청 수 추적
var requestCount = 0
let maxDailyRequests = 1000

func trackRequest() {
    requestCount += 1
    
    if requestCount > maxDailyRequests {
        print("⚠️ 일일 요청 한도 초과")
    }
}
```

### 3. 에러 로깅

```swift
func logSecurityEvent(_ event: String, error: Error? = nil) {
    let timestamp = DateFormatter().string(from: Date())
    print("[\(timestamp)] Security: \(event)")
    
    if let error = error {
        print("  Error: \(error)")
    }
}

// 사용 예제
do {
    try await session.authenticateCSRF()
} catch {
    logSecurityEvent("CSRF authentication failed", error: error)
    throw error
}
```

## Troubleshooting Authentication

### 일반적인 문제들

**Authentication Failed**
```swift
// 해결 방법 1: 쿠키 캐시 정리
YFCookieManager().clearAllCookies()

// 해결 방법 2: 새로운 세션으로 재시도
let newSession = YFSession()
try await newSession.authenticateCSRF()
```

**Rate Limited**
```swift
// 해결 방법: 더 긴 딜레이 사용
YFRateLimiter.shared.minimumInterval = 1.0 // 1초로 증가
```

**Network Issues**
```swift
// 네트워크 상태 확인
func checkNetworkConnectivity() async -> Bool {
    do {
        let url = URL(string: "https://finance.yahoo.com")!
        let (_, response) = try await URLSession.shared.data(from: url)
        return (response as? HTTPURLResponse)?.statusCode == 200
    } catch {
        return false
    }
}

if await checkNetworkConnectivity() {
    print("✅ 네트워크 연결 정상")
} else {
    print("❌ 네트워크 연결 문제")
}
```

## Next Steps

인증 시스템을 이해했다면 다음을 확인해보세요:

- <doc:AdvancedFeatures> - 고급 기능 활용
- <doc:BestPractices> - 성능 최적화 및 모범 사례
- <doc:FAQ> - 문제 해결 가이드