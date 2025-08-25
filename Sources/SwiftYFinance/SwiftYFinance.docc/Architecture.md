# Architecture

SwiftYFinance의 계층화된 아키텍처 설계

## Overview

SwiftYFinance는 견고하고 확장 가능한 5단계 계층화된 아키텍처로 설계되었습니다. 각 계층은 명확한 역할과 책임을 가지며, Protocol-Oriented Programming 원칙을 따라 구현되었습니다.

## 아키텍처 다이어그램

```
┌─────────────────────────────────────┐
│            YFClient                 │  ← Public API Layer
│         (Main Interface)            │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│         Services Layer              │  ← Business Logic Layer
│  ┌─────────────┬─────────────────┐  │
│  │ YFService   │ 9 Specialized   │  │
│  │ Protocol    │ Services        │  │
│  └─────────────┴─────────────────┘  │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│        API Builders Layer           │  ← URL Construction Layer
│  ┌─────────────────────────────────┐ │
│  │     10 Specialized Builders     │ │
│  │  (Quote, Chart, Search, etc.)   │ │
│  └─────────────────────────────────┘ │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│        Network Layer                │  ← Transport Layer
│  ┌─────────────┬─────────────────┐  │
│  │ YFSession   │ Browser         │  │
│  │ + Auth      │ Impersonation   │  │
│  └─────────────┴─────────────────┘  │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│         Models Layer                │  ← Data Representation Layer
│  ┌─────────────────────────────────┐ │
│  │   Type-Safe Data Models         │ │
│  │  (Quote, Chart, News, etc.)     │ │
│  └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## Layer 1: Public API Layer

### YFClient - 메인 인터페이스

SwiftYFinance의 진입점이자 가장 사용하기 쉬운 인터페이스입니다.

```swift
// 간단한 사용법
let client = YFClient()
let ticker = YFTicker(symbol: "AAPL")
let quote = try await client.fetchQuote(ticker: ticker)
```

**특징:**
- **Simple API**: 모든 기능을 하나의 인터페이스로 제공
- **Auto Configuration**: 기본 설정으로 즉시 사용 가능
- **Error Abstraction**: 복잡한 에러를 사용자 친화적으로 변환
- **Service Composition**: 내부적으로 적절한 서비스를 조합하여 기능 제공

**주요 메서드:**
- `fetchQuote(ticker:)` - 실시간 시세 조회
- `fetchHistory(ticker:period:interval:)` - 과거 가격 데이터
- `fetchNews(ticker:limit:)` - 종목 뉴스
- `fetchOptions(ticker:)` - 옵션 체인
- `search(query:limit:)` - 종목 검색

## Layer 2: Services Layer

### 서비스 레이어 설계 철학

Protocol + Struct 패턴을 사용하여 확장성과 테스트 가능성을 보장합니다.

```swift
// 기본 서비스 프로토콜
protocol YFService {
    associatedtype RequestType
    associatedtype ResponseType
    
    func execute(request: RequestType) async throws -> ResponseType
}

// 구체적인 서비스 구현
struct YFQuoteService: YFService {
    typealias RequestType = YFQuoteRequest
    typealias ResponseType = [String: YFQuote]
    
    func execute(request: YFQuoteRequest) async throws -> [String: YFQuote] {
        // 실제 구현
    }
    
    // 편의 메서드
    func fetchQuote(symbol: String) async throws -> YFQuote? {
        let request = YFQuoteRequest(symbols: [symbol])
        let result = try await execute(request: request)
        return result[symbol]
    }
}
```

### 9개 전문 서비스

각 서비스는 특정 도메인에 특화되어 있습니다:

#### 1. YFQuoteService
```swift
struct YFQuoteService: YFService {
    // 실시간 시세 데이터 전문
    func fetchQuotes(symbols: [String]) async throws -> [String: YFQuote]
    func fetchQuote(symbol: String) async throws -> YFQuote?
}
```

#### 2. YFChartService
```swift
struct YFChartService: YFService {
    // 차트 및 과거 데이터 전문
    func fetchHistory(ticker: YFTicker, period: YFPeriod, interval: YFInterval) async throws -> YFHistoricalData
    func fetchIntraday(ticker: YFTicker, interval: YFInterval) async throws -> YFHistoricalData
}
```

#### 3. YFSearchService
```swift
struct YFSearchService: YFService {
    // 종목 검색 전문
    func search(query: String, limit: Int) async throws -> YFSearchResult
    func searchWithNews(query: String, limit: Int) async throws -> YFSearchResult
}
```

#### 4. YFNewsService
```swift
struct YFNewsService: YFService {
    // 뉴스 데이터 전문
    func fetchNews(ticker: YFTicker, limit: Int) async throws -> YFNews
    func fetchMarketNews(limit: Int) async throws -> YFNews
}
```

#### 5. YFOptionsService
```swift
struct YFOptionsService: YFService {
    // 옵션 데이터 전문
    func fetchOptionsChain(ticker: YFTicker) async throws -> YFOptions
    func fetchExpirationDates(ticker: YFTicker) async throws -> [Date]
}
```

#### 6. YFFundamentalsTimeseriesService
```swift
struct YFFundamentalsTimeseriesService: YFService {
    // 재무제표 시계열 데이터 전문
    func fetchTimeseries(ticker: YFTicker, metrics: [String]) async throws -> YFFundamentalsTimeseriesResponse
    func fetchAvailableMetrics() async throws -> [String]
}
```

#### 7. YFScreenerService
```swift
struct YFScreenerService: YFService {
    // 종목 스크리닝 전문
    func runScreener(query: YFScreenerQuery) async throws -> YFScreenResult
    func getPresetScreeners() async throws -> [YFScreenerQuery]
}
```

#### 8. YFCustomScreenerService
```swift
struct YFCustomScreenerService: YFService {
    // 커스텀 스크리닝 전문
    func runCustomScreener(criteria: YFCustomScreenerCriteria) async throws -> YFCustomScreenerResponse
}
```

#### 9. YFDomainService
```swift
struct YFDomainService: YFService {
    // 도메인 정보 전문 (섹터, 산업 등)
    func fetchSectorInfo() async throws -> YFDomainResponse
    func fetchIndustryInfo(sector: String) async throws -> YFDomainSectorResponse
}
```

### 서비스 레이어 장점

**1. 단일 책임 원칙**
- 각 서비스는 하나의 도메인만 담당
- 코드 유지보수성 향상

**2. 의존성 주입 지원**
```swift
class MyApp {
    let quoteService: YFQuoteService
    let newsService: YFNewsService
    
    init(quoteService: YFQuoteService = YFQuoteService(),
         newsService: YFNewsService = YFNewsService()) {
        self.quoteService = quoteService
        self.newsService = newsService
    }
}
```

**3. 테스트 용이성**
```swift
// 목 서비스 쉽게 생성 가능
struct MockQuoteService: YFService {
    func execute(request: YFQuoteRequest) async throws -> [String: YFQuote] {
        // 테스트용 데이터 반환
    }
}
```

**4. 확장성**
```swift
// 새로운 서비스 추가 시 기존 코드 영향 없음
struct YFCryptocurrencyService: YFService {
    // 새로운 도메인 서비스
}
```

## Layer 3: API Builders Layer

### URL 빌더 시스템

각 API 엔드포인트별로 전문화된 URL 빌더가 있습니다.

```swift
// 기본 URL 빌더 프로토콜
protocol YFURLBuilder {
    associatedtype ParameterType
    
    func buildURL(parameters: ParameterType) -> URL
    func buildRequest(parameters: ParameterType) -> URLRequest
}

// 구체적인 빌더 구현
struct YFQuoteURLBuilder: YFURLBuilder {
    typealias ParameterType = YFQuoteParameters
    
    func buildURL(parameters: YFQuoteParameters) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "query1.finance.yahoo.com"
        components.path = "/v7/finance/quote"
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "symbols", value: parameters.symbols.joined(separator: ",")))
        queryItems.append(URLQueryItem(name: "fields", value: parameters.fields.joined(separator: ",")))
        
        components.queryItems = queryItems
        return components.url!
    }
    
    func buildRequest(parameters: YFQuoteParameters) -> URLRequest {
        let url = buildURL(parameters: parameters)
        var request = URLRequest(url: url)
        
        // 브라우저 위장 헤더 추가
        let impersonator = YFBrowserImpersonator()
        for (key, value) in impersonator.getHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
}
```

### 10개 전문화된 URL 빌더

#### 1. YFQuoteURLBuilder
- 실시간 시세 API 요청 구성
- 다중 심볼 지원
- 필드 선택 기능

#### 2. YFChartURLBuilder  
- 차트 데이터 API 요청 구성
- 기간 및 간격 설정
- 이벤트 포함 옵션

#### 3. YFSearchURLBuilder
- 검색 API 요청 구성
- 검색어 인코딩
- 결과 수 제한

#### 4. YFNewsURLBuilder
- 뉴스 API 요청 구성
- 종목별 뉴스 필터링
- 날짜 범위 설정

#### 5. YFOptionsURLBuilder
- 옵션 체인 API 요청 구성
- 만료일 선택
- Strike 가격 범위

#### 6. YFFundamentalsURLBuilder
- 재무제표 API 요청 구성
- 메트릭 선택
- 시계열 기간 설정

#### 7. YFScreenerURLBuilder
- 스크리너 API 요청 구성
- 필터 조건 구성
- 정렬 옵션

#### 8. YFCustomScreenerURLBuilder
- 커스텀 스크리너 요청 구성
- 복잡한 필터 조건
- 결과 포맷 선택

#### 9. YFDomainURLBuilder
- 도메인 정보 API 구성
- 섹터/산업 정보
- 메타데이터 요청

#### 10. YFWebSocketURLBuilder
- WebSocket 연결 URL 구성
- 구독 관리
- 실시간 데이터 스트림

### URL 빌더 패턴의 장점

**1. 관심사 분리**
- URL 구성 로직과 비즈니스 로직 분리
- 각 API별 전문화된 구현

**2. 재사용성**
```swift
let builder = YFQuoteURLBuilder()
let request1 = builder.buildRequest(parameters: params1)
let request2 = builder.buildRequest(parameters: params2)
```

**3. 테스트 용이성**
```swift
func testURLBuilding() {
    let builder = YFQuoteURLBuilder()
    let params = YFQuoteParameters(symbols: ["AAPL", "GOOGL"])
    let url = builder.buildURL(parameters: params)
    
    XCTAssertEqual(url.host, "query1.finance.yahoo.com")
    XCTAssertTrue(url.query?.contains("symbols=AAPL,GOOGL") ?? false)
}
```

**4. 구성 통일성**
- 모든 빌더가 동일한 인터페이스 제공
- 브라우저 위장 헤더 자동 적용
- 에러 처리 일관성

## Layer 4: Network Layer

### 네트워크 계층 구성 요소

#### 1. YFSession - 네트워크 세션 관리
```swift
actor YFSession {
    private let urlSession: URLSession
    private let browserImpersonator: YFBrowserImpersonator
    private let rateLimiter: YFRateLimiter
    
    func executeRequest<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        // Rate limiting 적용
        await rateLimiter.throttle()
        
        // 브라우저 위장 헤더 적용
        var modifiedRequest = request
        browserImpersonator.applyHeaders(to: &modifiedRequest)
        
        // 요청 실행
        let (data, response) = try await urlSession.data(for: modifiedRequest)
        
        // 응답 검증 및 파싱
        return try parseResponse(data: data, response: response, type: T.self)
    }
}
```

#### 2. YFBrowserImpersonator - Chrome 136 위장
```swift
struct YFBrowserImpersonator {
    private let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36"
    
    func getHeaders() -> [String: String] {
        return [
            "User-Agent": userAgent,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": "none",
            "Cache-Control": "max-age=0"
        ]
    }
}
```

#### 3. YFSessionAuth - CSRF 인증 관리
```swift
actor YFSessionAuth {
    private var csrfToken: String?
    private var cookies: [HTTPCookie] = []
    
    func authenticateCSRF() async throws {
        // Yahoo Finance 페이지에서 CSRF 토큰 추출
        let mainPageURL = URL(string: "https://finance.yahoo.com")!
        let (data, _) = try await URLSession.shared.data(from: mainPageURL)
        
        // HTML 파싱으로 CSRF 토큰 추출
        let htmlString = String(data: data, encoding: .utf8) ?? ""
        self.csrfToken = extractCSRFToken(from: htmlString)
        
        // 쿠키 저장
        if let cookies = HTTPCookieStorage.shared.cookies(for: mainPageURL) {
            self.cookies = cookies
        }
    }
}
```

### 네트워크 레이어 고급 기능

#### Rate Limiting
```swift
actor YFRateLimiter {
    private let minimumInterval: TimeInterval = 0.1 // 100ms
    private var lastRequestTime: Date?
    
    func throttle() async {
        if let lastTime = lastRequestTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < minimumInterval {
                let delay = minimumInterval - elapsed
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
    }
}
```

#### 응답 파싱 및 에러 처리
```swift
func parseResponse<T: Decodable>(data: Data, response: URLResponse, type: T.Type) throws -> T {
    guard let httpResponse = response as? HTTPURLResponse else {
        throw YFError.networkError(URLError(.badServerResponse))
    }
    
    switch httpResponse.statusCode {
    case 200...299:
        // 성공 응답 파싱
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw YFError.dataParsingError(error)
        }
        
    case 429:
        throw YFError.rateLimited
        
    case 401, 403:
        throw YFError.authenticationFailed
        
    case 500...599:
        throw YFError.serverError(httpResponse.statusCode)
        
    default:
        throw YFError.serverError(httpResponse.statusCode)
    }
}
```

## Layer 5: Models Layer

### 타입 안전한 데이터 모델

#### 모델 계층 구조
```
Models/
├── Primitives/          # 기본 데이터 타입
│   ├── YFTicker.swift
│   ├── YFPrice.swift
│   ├── YFError.swift
│   └── YFQuoteType.swift
├── Network/             # API 응답 모델
│   ├── Quote/
│   ├── Chart/
│   ├── Search/
│   ├── News/
│   ├── Options/
│   └── Screening/
├── Business/            # 비즈니스 도메인 모델
│   ├── YFFinancials.swift
│   ├── YFBalanceSheet.swift
│   ├── YFCashFlow.swift
│   └── YFEarnings.swift
└── Configuration/       # 설정 모델
    ├── YFDomain.swift
    ├── YFQuoteSummaryModule.swift
    └── YFSearchQuery.swift
```

#### 모델 설계 원칙

**1. Codable 지원**
```swift
struct YFQuote: Codable {
    let symbol: String
    let regularMarketPrice: Double
    let regularMarketTime: Date
    let marketCap: Int64?
    
    // 커스텀 날짜 디코딩
    private enum CodingKeys: String, CodingKey {
        case symbol
        case regularMarketPrice
        case regularMarketTime
        case marketCap
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        symbol = try container.decode(String.self, forKey: .symbol)
        regularMarketPrice = try container.decode(Double.self, forKey: .regularMarketPrice)
        
        // Unix timestamp를 Date로 변환
        let timestamp = try container.decode(TimeInterval.self, forKey: .regularMarketTime)
        regularMarketTime = Date(timeIntervalSince1970: timestamp)
        
        marketCap = try container.decodeIfPresent(Int64.self, forKey: .marketCap)
    }
}
```

**2. 확장성과 호환성**
```swift
struct YFHistoricalData: Codable {
    let meta: ChartMeta
    let prices: [YFPrice]
    let events: YFEvents?
    
    // 호환성을 위한 옵셔널 필드
    let indicators: ChartIndicators?
    let timestamp: [TimeInterval]?
    
    // 편의 계산 속성
    var dateRange: ClosedRange<Date>? {
        guard let first = prices.first?.date,
              let last = prices.last?.date else { return nil }
        return first...last
    }
    
    var priceRange: ClosedRange<Double>? {
        let prices = self.prices.map { $0.close }
        guard let min = prices.min(), let max = prices.max() else { return nil }
        return min...max
    }
}
```

**3. 타입 안전성**
```swift
enum YFPeriod: String, CaseIterable, Codable {
    case oneDay = "1d"
    case fiveDays = "5d"
    case oneMonth = "1mo"
    case threeMonths = "3mo"
    case sixMonths = "6mo"
    case oneYear = "1y"
    case twoYears = "2y"
    case fiveYears = "5y"
    case tenYears = "10y"
    case yearToDate = "ytd"
    case max = "max"
    
    var displayName: String {
        switch self {
        case .oneDay: return "1일"
        case .fiveDays: return "5일"
        case .oneMonth: return "1개월"
        case .threeMonths: return "3개월"
        case .sixMonths: return "6개월"
        case .oneYear: return "1년"
        case .twoYears: return "2년"
        case .fiveYears: return "5년"
        case .tenYears: return "10년"
        case .yearToDate: return "연초대비"
        case .max: return "전체"
        }
    }
}
```

## 아키텍처 패턴과 원칙

### 1. Protocol-Oriented Programming

```swift
// 공통 프로토콜 정의
protocol YFDataFetchable {
    associatedtype DataType
    associatedtype ParameterType
    
    func fetchData(parameters: ParameterType) async throws -> DataType
}

// 구체적인 구현
extension YFQuoteService: YFDataFetchable {
    typealias DataType = [String: YFQuote]
    typealias ParameterType = [String]
    
    func fetchData(parameters: [String]) async throws -> [String: YFQuote] {
        return try await fetchQuotes(symbols: parameters)
    }
}
```

### 2. Actor 모델을 통한 동시성 안전성

```swift
actor YFWebSocketManager {
    private var connections: [String: WebSocketTask] = [:]
    private var subscriptions: Set<String> = []
    
    func subscribe(symbols: [String]) async throws {
        for symbol in symbols {
            subscriptions.insert(symbol)
            // WebSocket 구독 로직
        }
    }
    
    func getSubscriptions() async -> Set<String> {
        return subscriptions
    }
}
```

### 3. 의존성 역전 원칙

```swift
// 추상화에 의존
protocol YFNetworkSession {
    func execute<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T
}

// 구체적인 구현
struct YFURLSession: YFNetworkSession {
    func execute<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        // URLSession 사용
    }
}

// 서비스에서 추상화 사용
struct YFQuoteService {
    private let networkSession: YFNetworkSession
    
    init(networkSession: YFNetworkSession = YFURLSession()) {
        self.networkSession = networkSession
    }
}
```

### 4. 단일 책임 원칙

각 클래스와 구조체는 하나의 명확한 책임을 가집니다:

- **YFClient**: 사용자 친화적인 API 제공
- **YFQuoteService**: 시세 데이터 처리
- **YFQuoteURLBuilder**: Quote API URL 구성
- **YFBrowserImpersonator**: 브라우저 위장
- **YFQuote**: 시세 데이터 표현

## 확장성과 유지보수성

### 새로운 기능 추가 방법

#### 1. 새로운 API 엔드포인트 지원
```swift
// 1. 새로운 서비스 생성
struct YFCryptocurrencyService: YFService {
    typealias RequestType = YFCryptoRequest
    typealias ResponseType = YFCryptoResponse
    
    func execute(request: YFCryptoRequest) async throws -> YFCryptoResponse {
        // 구현
    }
}

// 2. URL 빌더 생성
struct YFCryptocurrencyURLBuilder: YFURLBuilder {
    // 구현
}

// 3. 모델 정의
struct YFCryptoData: Codable {
    // 암호화폐 데이터 모델
}

// 4. YFClient에 메서드 추가
extension YFClient {
    func fetchCryptocurrencyData(symbol: String) async throws -> YFCryptoData {
        let service = YFCryptocurrencyService()
        let request = YFCryptoRequest(symbol: symbol)
        let response = try await service.execute(request: request)
        return response.data
    }
}
```

#### 2. 새로운 인증 방법 추가
```swift
protocol YFAuthenticator {
    func authenticate() async throws
    func isAuthenticated() async -> Bool
}

struct YFOAuthAuthenticator: YFAuthenticator {
    func authenticate() async throws {
        // OAuth 인증 구현
    }
    
    func isAuthenticated() async -> Bool {
        // OAuth 토큰 유효성 검증
    }
}
```

### 성능 최적화 포인트

#### 1. 캐싱 레이어 추가
```swift
actor YFCache<Key: Hashable, Value> {
    private var cache: [Key: (value: Value, timestamp: Date)] = [:]
    private let maxAge: TimeInterval
    
    init(maxAge: TimeInterval = 300) { // 5분 기본 캐시
        self.maxAge = maxAge
    }
    
    func get(key: Key) -> Value? {
        guard let entry = cache[key] else { return nil }
        
        if Date().timeIntervalSince(entry.timestamp) > maxAge {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return entry.value
    }
    
    func set(key: Key, value: Value) {
        cache[key] = (value: value, timestamp: Date())
    }
}
```

#### 2. 요청 배치화
```swift
struct YFBatchRequestManager {
    func batchQuoteRequests(_ symbols: [String]) -> [YFQuoteRequest] {
        // 100개씩 묶어서 요청 최적화
        return symbols.chunked(into: 100).map { chunk in
            YFQuoteRequest(symbols: Array(chunk))
        }
    }
}
```

## 테스트 전략

### 계층별 테스트 접근법

#### 1. 서비스 레이어 테스트
```swift
class YFQuoteServiceTests: XCTestCase {
    func testFetchQuote() async throws {
        let mockSession = MockYFSession()
        let service = YFQuoteService(session: mockSession)
        
        let quote = try await service.fetchQuote(symbol: "AAPL")
        XCTAssertEqual(quote?.symbol, "AAPL")
    }
}
```

#### 2. URL 빌더 테스트
```swift
class YFQuoteURLBuilderTests: XCTestCase {
    func testURLBuilding() {
        let builder = YFQuoteURLBuilder()
        let params = YFQuoteParameters(symbols: ["AAPL", "GOOGL"])
        let url = builder.buildURL(parameters: params)
        
        XCTAssertEqual(url.host, "query1.finance.yahoo.com")
        XCTAssertTrue(url.query?.contains("symbols=AAPL,GOOGL") ?? false)
    }
}
```

#### 3. 모델 테스트
```swift
class YFQuoteTests: XCTestCase {
    func testDecoding() throws {
        let json = """
        {
            "symbol": "AAPL",
            "regularMarketPrice": 150.25,
            "regularMarketTime": 1641234567,
            "marketCap": 2500000000000
        }
        """
        
        let data = json.data(using: .utf8)!
        let quote = try JSONDecoder().decode(YFQuote.self, from: data)
        
        XCTAssertEqual(quote.symbol, "AAPL")
        XCTAssertEqual(quote.regularMarketPrice, 150.25)
    }
}
```

## 보안 고려사항

### 1. API 키 관리 (해당없음)
SwiftYFinance는 API 키가 불필요한 공개 Yahoo Finance API를 사용합니다.

### 2. Rate Limiting 준수
```swift
// 자동 Rate Limiting으로 서버 부하 방지
actor YFRateLimiter {
    static let shared = YFRateLimiter()
    
    private let requestsPerMinute: Int = 60
    private var requestTimes: [Date] = []
    
    func canMakeRequest() async -> Bool {
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        
        // 1분 이전 요청 기록 정리
        requestTimes = requestTimes.filter { $0 > oneMinuteAgo }
        
        return requestTimes.count < requestsPerMinute
    }
}
```

### 3. 데이터 검증
```swift
extension YFQuote {
    var isValid: Bool {
        return regularMarketPrice > 0 && 
               !symbol.isEmpty &&
               regularMarketTime <= Date()
    }
}
```

## Next Steps

아키텍처를 이해했다면 다음을 확인해보세요:

- <doc:GettingStarted> - 실제 사용법 익히기
- <doc:CLI> - 명령줄 도구 활용
- <doc:AdvancedFeatures> - 고급 기능 활용
- <doc:BestPractices> - 아키텍처 활용 모범 사례