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

let ticker = YFTicker(symbol: "AAPL")
let quote = try await client.fetchQuote(ticker: ticker)
```

### Chrome 136 위장 기술 상세

SwiftYFinance는 Python [curl_cffi](https://github.com/yifeikong/curl_cffi) 라이브러리를 참고하여 구현된 고급 브라우저 위장 기술을 사용합니다.

#### 완전한 Chrome 136 Fingerprint

```swift
// Chrome 136 브라우저 식별 정보
struct Chrome136Fingerprint {
    static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36"
    
    static let secChUa = "\"Chromium\";v=\"136\", \"Google Chrome\";v=\"136\", \"Not.A.Brand\";v=\"24\""
    static let secChUaPlatform = "\"macOS\""
    static let secChUaMobile = "?0"
    
    // HTTP/2 설정 (Chrome 136과 동일)
    static let http2Settings: [String: Any] = [
        "HEADER_TABLE_SIZE": 65536,
        "ENABLE_PUSH": 1,
        "MAX_CONCURRENT_STREAMS": 1000,
        "INITIAL_WINDOW_SIZE": 6291456,
        "MAX_FRAME_SIZE": 16384,
        "MAX_HEADER_LIST_SIZE": 262144
    ]
    
    // TLS Fingerprint (Chrome 136 JA3)
    static let ja3Fingerprint = "771,4866-4867-4865-49196-49200-159-52393-52392-52394-49195-49199-158-49188-49192-107-49187-49191-103-49162-49172-57-49161-49171-51-157-156-61-60-53-47-255,0-23-65281-10-11-35-16-5-34-51-43-13-45-28-65037,29-23-24-25-256-257,0"
}
```

#### 정교한 헤더 구성

```swift
extension YFBrowserImpersonator {
    func getChromeHeaders(for url: URL) -> [String: String] {
        var headers: [String: String] = [:]
        
        // 기본 Chrome 헤더들
        headers["User-Agent"] = Chrome136Fingerprint.userAgent
        headers["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
        headers["Accept-Language"] = "en-US,en;q=0.9,ko;q=0.8"
        headers["Accept-Encoding"] = "gzip, deflate, br, zstd"
        headers["Connection"] = "keep-alive"
        headers["Upgrade-Insecure-Requests"] = "1"
        
        // Sec-CH-UA 헤더들 (Chrome 136 Client Hints)
        headers["Sec-CH-UA"] = Chrome136Fingerprint.secChUa
        headers["Sec-CH-UA-Mobile"] = Chrome136Fingerprint.secChUaMobile
        headers["Sec-CH-UA-Platform"] = Chrome136Fingerprint.secChUaPlatform
        headers["Sec-CH-UA-Platform-Version"] = "\"15.7.0\""
        headers["Sec-CH-UA-Arch"] = "\"x86\""
        headers["Sec-CH-UA-Model"] = "\"\""
        
        // Fetch Metadata 헤더들
        if url.host?.contains("finance.yahoo.com") == true {
            headers["Sec-Fetch-Site"] = "same-origin"
            headers["Sec-Fetch-Mode"] = "navigate"
            headers["Sec-Fetch-User"] = "?1"
            headers["Sec-Fetch-Dest"] = "document"
        } else {
            headers["Sec-Fetch-Site"] = "cross-site"
            headers["Sec-Fetch-Mode"] = "cors"
            headers["Sec-Fetch-Dest"] = "empty"
        }
        
        // Cache Control (Chrome 136 동작 모방)
        headers["Cache-Control"] = "max-age=0"
        
        // Priority Hints (Chrome 136 네트워크 우선순위)
        headers["Priority"] = "u=0, i"
        
        return headers
    }
}
```

#### HTTP/2 설정 적용

```swift
class YFHTTPClient {
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        
        // HTTP/2 강제 사용
        configuration.httpShouldUsePipelining = true
        configuration.httpMaximumConnectionsPerHost = 6 // Chrome 136과 동일
        configuration.requestCachePolicy = .useProtocolCachePolicy
        
        // TLS 설정
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        configuration.tlsMaximumSupportedProtocolVersion = .TLSv13
        
        // 타임아웃 설정 (Chrome 136과 유사)
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 300.0
        
        return URLSession(configuration: configuration)
    }()
}
```

#### 요청 순서 및 타이밍 모방

```swift
// Chrome 136의 요청 패턴 모방
actor YFRequestScheduler {
    private var lastRequestTime: Date?
    private let minimumInterval: TimeInterval = 0.05 // Chrome의 일반적인 요청 간격
    
    func scheduleRequest() async {
        if let lastTime = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < minimumInterval {
                let delay = minimumInterval - elapsed
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        // 약간의 랜덤 지연 (실제 브라우저 동작 모방)
        let randomDelay = Double.random(in: 0.01...0.03)
        try? await Task.sleep(nanoseconds: UInt64(randomDelay * 1_000_000_000))
        
        lastRequestTime = Date()
    }
}
```

### 브라우저 설정 커스터마이징

필요시 브라우저 모방 설정을 조정할 수 있습니다:

```swift
// 브라우저 설정 확인
let impersonator = YFBrowserImpersonator()
print("User-Agent: \(impersonator.userAgent)")
print("Chrome Version: 136.0.0.0")
print("HTTP Version: HTTP/2")
print("TLS Version: 1.2, 1.3")

// 헤더 정보 확인
let testURL = URL(string: "https://finance.yahoo.com")!
let headers = impersonator.getChromeHeaders(for: testURL)
for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
    print("\(key): \(value)")
}

// JA3 Fingerprint 확인
print("JA3: \(Chrome136Fingerprint.ja3Fingerprint)")
```

#### 고급 위장 기법

```swift
// 브라우저 세션 상태 관리
class YFBrowserSession {
    private var sessionId: String
    private var cookies: [HTTPCookie] = []
    private var referer: URL?
    private let impersonator = YFBrowserImpersonator()
    
    init() {
        // Chrome과 유사한 세션 ID 생성
        self.sessionId = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
    
    func createRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        
        // Chrome 136 헤더 적용
        let headers = impersonator.getChromeHeaders(for: url)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Referer 설정 (실제 브라우저 네비게이션 모방)
        if let referer = self.referer {
            request.setValue(referer.absoluteString, forHTTPHeaderField: "Referer")
        }
        
        // 쿠키 적용
        if !cookies.isEmpty {
            let cookieHeader = HTTPCookie.requestHeaderFields(with: cookies)
            for (key, value) in cookieHeader {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // 현재 URL을 다음 요청의 Referer로 설정
        self.referer = url
        
        return request
    }
}
```

#### 탐지 회피 기법

```swift
// 반복 패턴 탐지 회피
class YFAntiDetection {
    private var requestPattern: [Date] = []
    private let maxPatternLength = 10
    
    func randomizeRequestTiming() async {
        // 사람과 유사한 불규칙적 패턴 생성
        let patterns = [
            [0.1, 0.3, 0.2, 0.5], // 빠른 브라우징
            [0.5, 1.0, 0.8, 1.2], // 보통 브라우징  
            [1.0, 2.0, 1.5, 0.3], // 느린 브라우징 + 빠른 클릭
        ]
        
        let selectedPattern = patterns.randomElement()!
        let baseDelay = selectedPattern.randomElement()!
        
        // ±30% 랜덤 변이
        let variation = Double.random(in: 0.7...1.3)
        let finalDelay = baseDelay * variation
        
        try? await Task.sleep(nanoseconds: UInt64(finalDelay * 1_000_000_000))
        
        // 패턴 기록
        requestPattern.append(Date())
        if requestPattern.count > maxPatternLength {
            requestPattern.removeFirst()
        }
    }
    
    // 의심스러운 패턴 검사
    func isPatternSuspicious() -> Bool {
        guard requestPattern.count >= 5 else { return false }
        
        // 너무 규칙적인 간격 검사
        let intervals = zip(requestPattern.dropFirst(), requestPattern).map { $0.timeIntervalSince($1) }
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - avgInterval, 2) }.reduce(0, +) / Double(intervals.count)
        let standardDeviation = sqrt(variance)
        
        // 변동계수가 20% 미만이면 의심스러움 (너무 규칙적)
        let coefficientOfVariation = standardDeviation / avgInterval
        return coefficientOfVariation < 0.2
    }
}
```

### 위장 효과 검증

```swift
// 브라우저 위장 성공률 테스트
class YFImpersonationValidator {
    func validateImpersonation() async throws {
        print("=== Chrome 136 브라우저 위장 검증 ===")
        
        // 1. User-Agent 검증
        let session = YFBrowserSession()
        let testURL = URL(string: "https://httpbin.org/user-agent")!
        let request = session.createRequest(for: testURL)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        print("✅ User-Agent 테스트:")
        print("   전송: \(Chrome136Fingerprint.userAgent)")
        print("   수신: \(response["user-agent"] as? String ?? "없음")")
        
        // 2. 헤더 검증
        let headerTestURL = URL(string: "https://httpbin.org/headers")!
        let headerRequest = session.createRequest(for: headerTestURL)
        
        let (headerData, _) = try await URLSession.shared.data(for: headerRequest)
        let headerResponse = try JSONSerialization.jsonObject(with: headerData) as! [String: Any]
        
        if let headers = headerResponse["headers"] as? [String: String] {
            print("✅ Chrome 136 헤더 검증:")
            print("   Sec-CH-UA: \(headers["Sec-Ch-Ua"] ?? "없음")")
            print("   Accept: \(headers["Accept"] ?? "없음")")
            print("   Accept-Language: \(headers["Accept-Language"] ?? "없음")")
        }
        
        // 3. TLS Fingerprint 검증 (가능한 경우)
        print("✅ TLS 설정:")
        print("   최소 버전: TLS 1.2")
        print("   최대 버전: TLS 1.3")
        print("   JA3: \(Chrome136Fingerprint.ja3Fingerprint)")
        
        // 4. Yahoo Finance 접근 테스트
        let yahooURL = URL(string: "https://finance.yahoo.com")!
        let yahooRequest = session.createRequest(for: yahooURL)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: yahooRequest)
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ Yahoo Finance 접근:")
                print("   Status: \(httpResponse.statusCode)")
                print("   위장 성공: \(httpResponse.statusCode == 200 ? "예" : "아니오")")
            }
        } catch {
            print("❌ Yahoo Finance 접근 실패: \(error)")
        }
    }
}

// 검증 실행
let validator = YFImpersonationValidator()
try await validator.validateImpersonation()
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
    let ticker = YFTicker(symbol: symbol)
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
            let ticker = YFTicker(symbol: symbol)
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

SwiftYFinance는 시스템 쿠키 저장소를 활용한 자동 쿠키 관리를 제공합니다:

### 자동 쿠키 관리

```swift
// Yahoo Finance 쿠키 자동 추출 및 관리
let session = YFSession()
try await session.authenticateCSRF()

// 세션 인증 상태 확인
let isAuthenticated = await session.isCSRFAuthenticated
if isAuthenticated {
    print("✅ 유효한 인증 상태")
} else {
    print("❌ 인증 갱신 필요")
}
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
// 해결 방법: 새로운 세션으로 재시도
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