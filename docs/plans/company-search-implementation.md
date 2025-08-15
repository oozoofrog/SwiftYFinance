# 회사명 검색 구현 상세

## API 엔드포인트
```
Base URL: https://query2.finance.yahoo.com/v1/finance/search
Method: GET
```

## 데이터 모델

### YFSearchResult
```swift
public struct YFSearchResult: Codable, Sendable {
    public let symbol: String
    public let shortName: String
    public let longName: String?
    public let exchange: String
    public let quoteType: YFQuoteType
    public let score: Double
    
    public func toTicker() throws -> YFTicker {
        return try YFTicker(symbol: symbol)
    }
}
```

### YFSearchQuery
```swift
public struct YFSearchQuery: Sendable {
    public let term: String
    public let maxResults: Int
    public let country: YFCountry?
    public let quoteTypes: [YFQuoteType]
    
    public init(
        term: String,
        maxResults: Int = 10,
        country: YFCountry? = nil,
        quoteTypes: [YFQuoteType] = []
    )
}
```

## YFClient 확장
```swift
extension YFClient {
    /// 회사명으로 검색을 수행합니다
    public func search(companyName: String) async throws -> [YFSearchResult] {
        let query = YFSearchQuery(term: companyName)
        return try await search(query: query)
    }
    
    /// 고급 검색을 수행합니다
    public func search(query: YFSearchQuery) async throws -> [YFSearchResult] {
        return try await YFRateLimiter.shared.executeRequest {
            try await performSearch(query: query)
        }
    }
    
    /// 검색어 자동완성 제안을 반환합니다
    public func searchSuggestions(prefix: String) async throws -> [String] {
        let results = try await search(companyName: prefix)
        return results.compactMap { $0.longName ?? $0.shortName }
    }
}
```

## 파일 구조
```
Sources/SwiftYFinance/
├── Core/
│   └── YFSearchAPI.swift          # YFClient 검색 확장
├── Models/
│   ├── YFSearchResult.swift       # 검색 결과 모델
│   └── YFSearchQuery.swift        # 검색 쿼리 모델
└── Tests/
    └── YFSearchTests.swift        # 검색 기능 테스트
```

## 에러 처리
```swift
extension YFError {
    case searchQueryTooShort
    case searchResultsEmpty
    case searchQuotaExceeded
}
```

## 성능 최적화
- 검색 결과 메모리 캐싱 (5분 TTL)
- Rate limiting (분당 60회)
- 네트워크 요청 최적화