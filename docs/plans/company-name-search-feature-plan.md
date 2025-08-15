# SwiftYFinance 회사명 검색 기능 구현 계획

## 📋 프로젝트 개요

### 목표
Python yfinance의 검색 기능을 참고하여 SwiftYFinance에 회사명으로 티커 심볼을 검색할 수 있는 기능을 추가합니다.

### 배경
현재 SwiftYFinance는 정확한 티커 심볼을 알고 있어야만 데이터를 조회할 수 있습니다. 많은 사용자들이 회사명만 알고 있는 경우가 많으므로, 검색 기능 추가가 사용성 향상에 크게 기여할 것입니다.

### 범위
- Yahoo Finance Search API 통합
- 회사명 → 티커 심볼 검색
- 부분 검색 및 자동완성 지원
- 다중 결과 반환 및 필터링

## 🎯 기능 요구사항

### 핵심 기능

#### 1. 기본 검색
```swift
// 간단한 회사명 검색 (YFClient를 통해)
let client = YFClient()
let results = try await client.search(companyName: "Apple")
let appleTicker = results.first?.toTicker() // YFTicker(symbol: "AAPL")
```

#### 2. 고급 검색
```swift
// 세부 옵션을 포함한 검색
let client = YFClient()
let query = YFSearchQuery(
    term: "Tesla",
    maxResults: 5,
    country: .unitedStates,
    quoteTypes: [.equity, .etf],
    exchanges: [.nasdaq, .nyse]
)
let results = try await client.search(query: query)
```

#### 3. 자동완성
```swift
// 검색어 제안 기능
let client = YFClient()
let suggestions = try await client.searchSuggestions(prefix: "Appl")
// ["Apple Inc.", "Applied Materials", "Applebee's", ...]
```

### 부가 기능

#### 1. 검색 결과 상세 정보
- 회사 전체명
- 거래소 정보
- 종목 유형 (주식, ETF, 지수 등)
- 검색 정확도 점수

#### 2. 필터링 옵션
- 국가별 필터링
- 거래소별 필터링
- 종목 유형별 필터링
- 시가총액 범위 필터링

#### 3. 캐싱 및 성능 최적화
- 검색 결과 메모리 캐싱
- 자주 검색되는 항목 우선순위
- Rate limiting 적용

## 🏛️ 아키텍처 원칙

### 설계 철학
SwiftYFinance는 명확한 관심사 분리(Separation of Concerns)를 따릅니다:

- **모델 (Models)**: 순수한 데이터 구조체/클래스. API 실행 로직 포함하지 않음
- **클라이언트 (YFClient)**: 모든 API 호출 및 네트워크 로직 담당
- **확장 (Extensions)**: 모델에는 계산 속성이나 편의 메서드만 추가, API 호출 금지

### 기존 패턴 준수
```swift
// ✅ 올바른 패턴 (일관성 있음)
let client = YFClient()
let quote = try await client.fetchQuote(ticker: ticker)
let financials = try await client.fetchFinancials(ticker: ticker)
let searchResults = try await client.search(companyName: "Apple")

// ❌ 잘못된 패턴 (일관성 없음)
let quote = try await YFTicker.fetchQuote(symbol: "AAPL") // 모델에 API 로직
let results = try await YFTicker.search(companyName: "Apple") // 부적절한 정적 메서드
```

### 이점
- **테스트 용이성**: 모델과 API 로직 분리로 단위 테스트 간편
- **유지보수성**: 네트워크 로직 변경 시 모델에 영향 없음  
- **일관성**: 모든 API가 동일한 패턴 사용
- **재사용성**: 모델을 다른 컨텍스트에서 안전하게 재사용 가능

## 🏗️ 기술 설계

### API 엔드포인트
```
Base URL: https://query2.finance.yahoo.com/v1/finance/search
Method: GET
```

### 요청 파라미터
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| q | String | ✅ | 검색어 (회사명 또는 부분 문자열) |
| quotes_count | Int | ❌ | 반환할 결과 수 (기본값: 10) |
| country | String | ❌ | 국가 코드 (예: "United States") |
| lang | String | ❌ | 언어 코드 (기본값: "en") |

### 응답 구조
```json
{
  "explains": [],
  "count": 1,
  "quotes": [
    {
      "exchange": "NMS",
      "shortname": "Apple Inc.",
      "quoteType": "EQUITY", 
      "symbol": "AAPL",
      "index": "quotes",
      "score": 1000000.0,
      "typeDisp": "Equity",
      "longname": "Apple Inc.",
      "isYahooFinance": true
    }
  ],
  "news": [],
  "nav": []
}
```

### 데이터 모델

#### YFSearchResult
```swift
public struct YFSearchResult: Codable, Sendable {
    public let symbol: String
    public let shortName: String
    public let longName: String?
    public let exchange: String
    public let quoteType: YFQuoteType
    public let score: Double
    public let typeDisplay: String
    
    /// 검색 결과를 YFTicker로 변환
    public func toTicker() throws -> YFTicker {
        return try YFTicker(symbol: symbol)
    }
}
```

#### YFSearchQuery
```swift
public struct YFSearchQuery: Sendable {
    public let term: String
    public let maxResults: Int
    public let country: YFCountry?
    public let quoteTypes: [YFQuoteType]
    public let exchanges: [YFExchange]
    
    public init(
        term: String,
        maxResults: Int = 10,
        country: YFCountry? = nil,
        quoteTypes: [YFQuoteType] = [],
        exchanges: [YFExchange] = []
    )
}
```

#### YFQuoteType (확장)
```swift
public enum YFQuoteType: String, Codable, CaseIterable {
    case equity = "EQUITY"
    case etf = "ETF"
    case mutualFund = "MUTUALFUND"
    case index = "INDEX"
    case currency = "CURRENCY"
    case cryptocurrency = "CRYPTOCURRENCY"
    case futures = "FUTURE"
    case option = "OPTION"
}
```

### 아키텍처 구조

```
SwiftYFinance/
├── Core/
│   ├── YFSearchAPI.swift          # YFClient 검색 확장
│   └── YFSearchResponseParser.swift # 검색 응답 파서
├── Models/
│   ├── YFSearchResult.swift       # 검색 결과 모델
│   └── YFSearchQuery.swift        # 검색 쿼리 모델
└── Tests/
    └── YFSearchTests.swift        # 검색 기능 테스트
```

## 📅 구현 단계

### Phase 1: 기반 구조 (1주)

#### 1.1 모델 구조체 생성
- [ ] YFSearchResult.swift 작성
- [ ] YFSearchQuery.swift 작성  
- [ ] YFQuoteType 열거형 확장
- [ ] YFCountry, YFExchange 열거형 추가

#### 1.2 네트워크 계층
- [ ] YFSearchAPI.swift 구현
- [ ] YFSearchResponseParser.swift 구현
- [ ] 에러 타입 정의 (YFError 확장)

### Phase 2: 핵심 기능 (1주)

#### 2.1 기본 검색 기능
- [ ] YFClient.search(companyName:) 편의 메서드
- [ ] YFClient.search(query:) 고급 검색 메서드  
- [ ] YFClient.searchSuggestions(prefix:) 자동완성 메서드
- [ ] 기본 검색 결과 파싱 및 변환

#### 2.2 고급 검색 기능
- [ ] 필터링 옵션 구현
- [ ] 결과 정렬 및 점수 기반 랭킹
- [ ] 페이지네이션 지원

### Phase 3: 최적화 및 안정성 (1주)

#### 3.1 성능 최적화
- [ ] 검색 결과 캐싱 구현
- [ ] Rate limiting 적용
- [ ] 네트워크 요청 최적화

#### 3.2 에러 처리
- [ ] 검색 결과 없음 처리
- [ ] 네트워크 에러 처리
- [ ] API 제한 초과 처리

### Phase 4: 테스트 및 문서화 (1주)

#### 4.1 테스트 작성
- [ ] 단위 테스트 (YFSearchTests.swift)
- [ ] 통합 테스트
- [ ] 성능 테스트
- [ ] 에러 케이스 테스트

#### 4.2 문서화
- [ ] DocC 문서 작성 (Search.md)
- [ ] API 문서 업데이트
- [ ] 사용 예시 및 튜토리얼
- [ ] FAQ 업데이트

## 🔧 구현 세부사항

### YFSearchAPI.swift
```swift
class YFSearchAPI {
    private let session: YFSession
    private let baseURL = "https://query2.finance.yahoo.com/v1/finance/search"
    
    func search(query: YFSearchQuery) async throws -> YFSearchResponse {
        let url = try buildSearchURL(from: query)
        let data = try await session.data(from: url)
        return try YFSearchResponseParser().parse(data)
    }
    
    private func buildSearchURL(from query: YFSearchQuery) throws -> URL {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query.term),
            URLQueryItem(name: "quotes_count", value: String(query.maxResults))
        ]
        
        if let country = query.country {
            components.queryItems?.append(
                URLQueryItem(name: "country", value: country.rawValue)
            )
        }
        
        guard let url = components.url else {
            throw YFError.invalidURL
        }
        return url
    }
}
```

### YFSearchAPI.swift (YFClient 확장)
```swift
extension YFClient {
    /// 회사명으로 검색을 수행합니다 (편의 메서드)
    /// 
    /// - Parameter companyName: 검색할 회사명 (부분 검색 지원)
    /// - Returns: 검색된 결과들의 배열 (관련도 순 정렬)
    /// - Throws: 네트워크 에러 또는 파싱 에러
    public func search(companyName: String) async throws -> [YFSearchResult] {
        let query = YFSearchQuery(term: companyName)
        return try await search(query: query)
    }
    
    /// 고급 검색을 수행합니다
    /// 
    /// - Parameter query: 검색 쿼리 (필터링 옵션 포함)
    /// - Returns: 검색된 결과들의 배열
    public func search(query: YFSearchQuery) async throws -> [YFSearchResult] {
        return try await YFRateLimiter.shared.executeRequest {
            try await performSearch(query: query)
        }
    }
    
    /// 검색어 자동완성 제안을 반환합니다
    /// 
    /// - Parameter prefix: 검색어 접두사
    /// - Returns: 제안된 회사명들의 배열
    public func searchSuggestions(prefix: String) async throws -> [String] {
        let results = try await search(companyName: prefix)
        return results.compactMap { $0.longName ?? $0.shortName }
    }
    
    private func performSearch(query: YFSearchQuery) async throws -> [YFSearchResult] {
        let api = YFSearchAPI(session: session)
        let response = try await api.search(query: query)
        return YFSearchResponseParser().parse(response)
    }
}
```

## ⚡ 성능 고려사항

### 캐싱 전략
```swift
class YFSearchCache {
    private let cache = NSCache<NSString, YFSearchCacheEntry>()
    private let cacheTimeout: TimeInterval = 300 // 5분
    
    func get(for query: String) -> [YFSearchResult]? {
        guard let entry = cache.object(forKey: query as NSString),
              Date().timeIntervalSince(entry.timestamp) < cacheTimeout else {
            return nil
        }
        return entry.results
    }
    
    func set(_ results: [YFSearchResult], for query: String) {
        let entry = YFSearchCacheEntry(results: results, timestamp: Date())
        cache.setObject(entry, forKey: query as NSString)
    }
}
```

### Rate Limiting
- 기존 YFRateLimiter에 검색 요청 포함
- 검색 전용 제한: 분당 60회, 시간당 1000회
- 동일 검색어 중복 요청 방지

## 🛡️ 에러 처리

### 새로운 에러 타입
```swift
extension YFError {
    case searchQueryTooShort
    case searchResultsEmpty
    case searchQuotaExceeded
    case searchServiceUnavailable
}
```

### 에러 처리 예시
```swift
do {
    let results = try await YFTicker.search(companyName: "AAPL")
} catch YFError.searchQueryTooShort {
    print("검색어는 최소 2글자 이상이어야 합니다")
} catch YFError.searchResultsEmpty {
    print("검색 결과가 없습니다")
} catch YFError.rateLimitExceeded {
    print("검색 제한을 초과했습니다. 잠시 후 다시 시도하세요")
}
```

## 📊 테스트 계획

### 단위 테스트
- 검색 쿼리 빌드 테스트
- 응답 파싱 테스트
- 캐싱 로직 테스트
- 에러 핸들링 테스트

### 통합 테스트
```swift
func testSearchAppleCompany() async throws {
    let results = try await YFTicker.search(companyName: "Apple")
    XCTAssertFalse(results.isEmpty)
    XCTAssertEqual(results.first?.symbol, "AAPL")
}

func testSearchWithQuery() async throws {
    let query = YFSearchQuery(
        term: "Microsoft",
        maxResults: 5,
        quoteTypes: [.equity]
    )
    let results = try await YFClient().search(query: query)
    XCTAssertTrue(results.contains { $0.symbol == "MSFT" })
}
```

### 성능 테스트
- 동시 검색 요청 처리
- 캐시 적중률 측정
- 응답 시간 벤치마크

## 📚 문서화 계획

### DocC 가이드 (Search.md)
```markdown
# 회사명 검색

SwiftYFinance의 검색 기능을 사용하여 회사명으로 티커 심볼을 찾는 방법

## 기본 사용법
간단한 회사명 검색부터 고급 필터링까지 단계별 가이드

## 고급 검색
세부 옵션을 활용한 정확한 검색 결과 획득

## 성능 최적화
캐싱과 Rate Limiting을 고려한 효율적인 검색

## 문제 해결
일반적인 검색 오류와 해결 방법
```

### API 문서 업데이트
- YFTicker 클래스에 검색 메서드 문서화
- YFClient 클래스에 고급 검색 메서드 문서화
- 모든 새 모델에 상세 문서화

## 🚀 배포 계획

### 버전 관리
- 새로운 기능이므로 Minor 버전 증가 (예: 1.5.0)
- Breaking changes 없음 (기존 API 유지)

### 릴리스 노트
```markdown
## SwiftYFinance 1.5.0

### 🆕 새로운 기능
- 회사명으로 티커 검색 기능 추가
- 고급 검색 필터링 옵션 
- 검색 결과 캐싱 및 성능 최적화

### 📝 사용 예시
let results = try await YFTicker.search(companyName: "Apple")
```

## 📋 체크리스트

### 개발 완료 기준
- [ ] 모든 핵심 기능 구현 완료
- [ ] 단위/통합 테스트 100% 통과
- [ ] 성능 테스트 기준 만족 (응답시간 < 2초)
- [ ] 메모리 누수 없음
- [ ] 에러 처리 완전성 검증

### 문서화 완료 기준  
- [ ] DocC 가이드 문서 작성
- [ ] API 참조 문서 완성
- [ ] 코드 예시 검증 완료
- [ ] FAQ 업데이트 완료

### 품질 보증 완료 기준
- [ ] 코드 리뷰 완료
- [ ] 보안 검토 완료
- [ ] 접근성 검토 완료
- [ ] 성능 프로파일링 완료

---

이 계획을 통해 SwiftYFinance는 Python yfinance와 동등한 수준의 검색 기능을 갖춘 완전한 금융 데이터 라이브러리가 될 것입니다. 🎯