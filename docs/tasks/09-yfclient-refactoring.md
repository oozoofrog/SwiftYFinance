# YFClient Refactoring Task

## 목표
YFClient의 extension 기반 구조를 OOP 원칙에 따라 개별 Service 클래스로 분리

## 핵심 원칙
- **NO Extensions**: YFClient에 extension 사용 금지
- **NO Protocols**: 프로토콜 사용 금지  
- **Single Responsibility**: 각 API는 독립적인 객체
- **OOP**: 객체 지향 설계 원칙 준수
- **TDD**: Test-Driven Development
- **Tidy First**: 구조 변경을 먼저, 기능 변경은 나중에

## 새로운 구조
```swift
// Before (Extension 기반)
extension YFClient {
    func fetchQuote() { }
}

// After (Service 객체 기반)
class YFClient {
    lazy var quote = YFQuoteService(session, requestBuilder, responseParser)
}
```

## 구현 체크리스트

### Phase 1: 공통 유틸리티 분리 ✅
- [x] YFDateHelper 클래스 생성 (periodStart, periodEnd, dateFromPeriod, periodToRangeString)
- [x] YFChartConverter 클래스 생성 (convertToPrices)

### Phase 2: Core API 서비스 클래스 생성
- [ ] YFQuoteService 클래스 생성 (fetchQuote 메서드들)
- [ ] YFHistoryService 클래스 생성 (fetchHistory, fetchPriceHistory)
- [ ] YFSearchService 클래스 생성 (search, searchSuggestions)

### Phase 3: Financial API 서비스 클래스 생성
- [ ] YFFinancialsService 클래스 생성 (fetchFinancials)
- [ ] YFBalanceSheetService 클래스 생성 (fetchBalanceSheet)
- [ ] YFCashFlowService 클래스 생성 (fetchCashFlow)
- [ ] YFEarningsService 클래스 생성 (fetchEarnings)

### Phase 4: Advanced API 서비스 클래스 생성
- [ ] YFNewsService 클래스 생성 (fetchNews 메서드들)
- [ ] YFOptionsService 클래스 생성 (fetchOptionsChain)
- [ ] YFScreeningService 클래스 생성 (screenStocks)
- [ ] YFWebSocketService 클래스 생성 (startRealTimeStreaming)
- [ ] YFTechnicalIndicatorsService 클래스 생성 (calculateIndicators)

### Phase 5: YFClient 리팩토링
- [ ] YFClient에 lazy property로 모든 서비스 추가
- [ ] YFClient의 private 유틸리티 메서드 제거
- [ ] YFClient의 Debug Methods extension 통합

### Phase 6: 기존 파일 정리
- [ ] YFQuoteAPI.swift 제거
- [ ] YFHistoryAPI.swift 제거
- [ ] YFSearchAPI.swift 제거
- [ ] YFFinancialsAPI.swift 제거
- [ ] YFBalanceSheetAPI.swift 제거
- [ ] YFCashFlowAPI.swift 제거
- [ ] YFEarningsAPI.swift 제거
- [ ] YFNewsAPI.swift 제거
- [ ] YFOptionsAPI.swift 제거
- [ ] YFScreeningAPI.swift 제거
- [ ] YFWebSocketAPI.swift 제거
- [ ] YFTechnicalIndicatorsAPI.swift 제거
- [ ] YFFinancialsAdvancedAPI.swift 제거

### Phase 7: 테스트 및 문서
- [ ] 각 Service 클래스에 대한 테스트 작성
- [ ] YFClient 테스트 업데이트
- [ ] 사용 예제 코드 업데이트
- [ ] DocC 문서 업데이트

### Phase 8: 최종 검증
- [ ] 모든 테스트 통과 확인
- [ ] 빌드 성공 확인
- [ ] API 호환성 확인 (기존 사용법 유지)
- [ ] Tidy First 원칙에 따른 커밋

## 진행 상황
- 시작: 2025-01-18
- 현재: Phase 1 완료 ✅ (YFDateHelper ✅, YFChartConverter ✅)
- 다음: Phase 2 시작 예정

## 사용 예시 (변경 후)
```swift
let client = YFClient()

// Service 객체를 통한 API 호출
let quote = try await client.quote.fetch(ticker: "AAPL")
let history = try await client.history.fetch(ticker: "AAPL", period: .oneYear)
let results = try await client.search.find("Apple")
```

## 장점
1. **명확한 책임 분리**: 각 서비스가 단일 책임
2. **코드 탐색 용이**: 기능별로 파일 분리
3. **테스트 용이**: 각 서비스 독립 테스트 가능
4. **유지보수 향상**: 변경 영향 범위 제한
5. **확장성**: 새 서비스 추가 용이

## 주의사항
- 기존 API 호환성 유지 필요 (client.fetchQuote → client.quote.fetch)
- 각 서비스는 YFSession, YFRequestBuilder, YFResponseParser 의존성 주입
- Lazy initialization으로 메모리 효율성 유지