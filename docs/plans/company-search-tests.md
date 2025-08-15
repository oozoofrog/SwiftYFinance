# 회사명 검색 테스트 계획

## TDD 테스트 우선순위

### 1순위: 기본 모델 테스트
```swift
func testYFSearchResultInitialization() {
    let result = YFSearchResult(
        symbol: "AAPL",
        shortName: "Apple Inc.",
        longName: "Apple Inc.",
        exchange: "NMS",
        quoteType: .equity,
        score: 1000000.0
    )
    
    XCTAssertEqual(result.symbol, "AAPL")
    XCTAssertEqual(result.shortName, "Apple Inc.")
}

func testYFSearchResultToTicker() throws {
    let result = YFSearchResult(/* ... */)
    let ticker = try result.toTicker()
    XCTAssertEqual(ticker.symbol, "AAPL")
}
```

### 2순위: 검색 쿼리 테스트
```swift
func testYFSearchQueryDefaultValues() {
    let query = YFSearchQuery(term: "Apple")
    XCTAssertEqual(query.term, "Apple")
    XCTAssertEqual(query.maxResults, 10)
    XCTAssertNil(query.country)
}
```

### 3순위: 클라이언트 검색 테스트
```swift
func testSearchAppleCompany() async throws {
    let client = YFClient()
    let results = try await client.search(companyName: "Apple")
    
    XCTAssertFalse(results.isEmpty)
    XCTAssertTrue(results.contains { $0.symbol == "AAPL" })
}

func testSearchWithQuery() async throws {
    let query = YFSearchQuery(
        term: "Microsoft",
        maxResults: 5,
        quoteTypes: [.equity]
    )
    let results = try await client.search(query: query)
    XCTAssertTrue(results.contains { $0.symbol == "MSFT" })
}
```

## 에러 케이스 테스트
```swift
func testSearchEmptyTerm() async {
    let client = YFClient()
    
    do {
        _ = try await client.search(companyName: "")
        XCTFail("Should throw searchQueryTooShort error")
    } catch YFError.searchQueryTooShort {
        // Expected
    } catch {
        XCTFail("Unexpected error: \(error)")
    }
}

func testSearchNoResults() async throws {
    let results = try await client.search(companyName: "XYZ999")
    XCTAssertTrue(results.isEmpty)
}
```

## 성능 테스트
```swift
func testSearchPerformance() async throws {
    let expectation = XCTestExpectation(description: "Search performance")
    
    let startTime = Date()
    _ = try await client.search(companyName: "Apple")
    let duration = Date().timeIntervalSince(startTime)
    
    XCTAssertLessThan(duration, 2.0, "Search should complete within 2 seconds")
}
```

## 통합 테스트
```swift
func testSearchAndFetchQuote() async throws {
    // 1. 검색으로 티커 찾기
    let results = try await client.search(companyName: "Apple")
    let appleTicker = try results.first?.toTicker()
    
    // 2. 찾은 티커로 시세 조회
    let quote = try await client.fetchQuote(ticker: appleTicker!)
    
    XCTAssertEqual(quote.symbol, "AAPL")
    XCTAssertNotNil(quote.regularMarketPrice)
}
```

## 테스트 우선순위
1. **모델 구조체 테스트** - 가장 기본적인 데이터 구조
2. **클라이언트 기본 검색** - 핵심 기능 
3. **고급 검색 옵션** - 필터링 기능
4. **에러 처리** - 예외 상황 처리
5. **성능 및 통합** - 전체 시스템 검증