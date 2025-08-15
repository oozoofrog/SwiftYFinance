# 회사명 검색 기능 개요

## 목표
Python yfinance의 검색 기능을 참고하여 SwiftYFinance에 회사명으로 티커 심볼을 검색할 수 있는 기능을 추가합니다.

## 배경
현재 SwiftYFinance는 정확한 티커 심볼을 알고 있어야만 데이터를 조회할 수 있습니다. 회사명만 알고 있는 경우가 많으므로, 검색 기능 추가가 개발자 편의성 향상에 크게 기여할 것입니다.

## 핵심 기능

### 1. 기본 검색
```swift
let client = YFClient()
let results = try await client.search(companyName: "Apple")
let appleTicker = results.first?.toTicker() // YFTicker(symbol: "AAPL")
```

### 2. 고급 검색  
```swift
let query = YFSearchQuery(
    term: "Tesla",
    maxResults: 5,
    country: .unitedStates,
    quoteTypes: [.equity, .etf]
)
let results = try await client.search(query: query)
```

### 3. 자동완성
```swift
let suggestions = try await client.searchSuggestions(prefix: "Appl")
// ["Apple Inc.", "Applied Materials", ...]
```

## 아키텍처 원칙
- **모델**: 순수한 데이터 구조 (API 호출 금지)
- **클라이언트**: 모든 API 호출은 YFClient를 통해
- **일관성**: 기존 패턴 준수

```swift
// ✅ 올바른 패턴
let client = YFClient()
let results = try await client.search(companyName: "Apple")

// ❌ 잘못된 패턴  
let results = try await YFTicker.search(companyName: "Apple")
```

## 구현 단계
1. **모델 생성**: YFSearchResult, YFSearchQuery
2. **API 구현**: YFClient 확장
3. **테스트 작성**: TDD 방식
4. **문서화**: DocC 가이드