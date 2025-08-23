# YFClient Refactoring Task

## 목표
YFClient의 extension 기반 구조를 Protocol + Struct 패턴으로 리팩토링

## 핵심 원칙
- **Protocol + Struct**: Extension 대신 Protocol + Struct 아키텍처 사용
- **Sendable 준수**: @unchecked 없이 완전한 thread-safety 구현  
- **Composition**: 상속 대신 YFServiceCore를 통한 합성 패턴
- **Single Responsibility**: 각 서비스는 독립적인 도메인 담당
- **OOP**: 객체 지향 설계 원칙 준수
- **TDD**: Test-Driven Development
- **Tidy First**: 구조 변경을 먼저, 기능 변경은 나중에

## 아키텍처 패턴

### 🔄 구조 변화 (Before vs After)

**기존**: Extension 기반으로 모든 API가 YFClient에 직접 구현
```swift
extension YFClient {
    func fetch{Domain}(...) { ... }
}
let result = try await client.fetch{Domain}(...)
```

**현재**: Protocol + Struct 기반으로 도메인별 서비스 분리
```swift
public struct YFClient: Sendable {
    public var {domain}: YF{Domain}Service { 
        YF{Domain}Service(client: self, debugEnabled: debugEnabled) 
    }
}
let result = try await client.{domain}.{method}(...)
```

### 🔧 새로운 서비스 추가 패턴

```swift
// 1. 서비스 구조체 정의
public struct YF{Domain}Service: YFService {
    public let client: YFClient
    public let debugEnabled: Bool
    private let core: YFServiceCore
    
    public init(client: YFClient, debugEnabled: Bool = false) {
        self.client = client
        self.debugEnabled = debugEnabled
        self.core = YFServiceCore(client: client, debugEnabled: debugEnabled)
    }
    
    public func fetch(...) async throws -> YF{Domain} {
        let data = try await core.performAPIRequest(
            path: "/api/endpoint/path",
            parameters: ["key": "value"],
            serviceName: "{Domain}"
        )
        return try core.parseJSON(data: data, type: YF{Domain}.self)
    }
}

// 2. YFClient에 computed property 추가
public var {domain}: YF{Domain}Service {
    YF{Domain}Service(client: self, debugEnabled: debugEnabled)
}

// 3. 사용법
let client = YFClient()
let result = try await client.{domain}.{method}({parameters})
```

**핵심 변화**:
- Extension → Protocol + Struct 패턴
- 직접 호출 → 서비스를 통한 호출  
- Class 상속 → Composition 패턴 (YFServiceCore)

## 구현 체크리스트

### Phase 1: 공통 유틸리티 분리 ✅
- [x] YFDateHelper 클래스 생성 (periodStart, periodEnd, dateFromPeriod, periodToRangeString)
- [x] YFChartConverter 클래스 생성 (convertToPrices)
- [x] YFClient에서 YFDateHelper 사용으로 변경

### Phase 2: Core API 서비스 Protocol + Struct 구조 생성 ✅
- [x] YFService 프로토콜 생성 (공통 인터페이스 정의)
- [x] YFServiceCore struct 생성 (Composition 패턴으로 공통 기능 통합)
- [x] YFQuoteService struct 생성 (Protocol + Struct 패턴, fetch 메서드들만 유지)
- [x] YFQuoteService에서 하위 호환성 fetchQuote 메서드 제거 (새 규칙 적용)
- [x] YFQuoteAPI.swift 파일 완전 제거
- [x] YFClient에서 fetchQuote 위임 메서드 제거 (서비스 기반으로 완전 전환)
- [x] Protocol + Struct 아키텍처 도입 (완전한 Sendable 준수, @unchecked 제거)
- [x] Composition over Inheritance 패턴 적용 (YFServiceCore 활용)
- [x] YFHistoryService struct 생성 (fetchHistory, fetchPriceHistory)
- [x] YFSearchService struct 생성 (search, searchSuggestions)
- [x] Template Method 패턴 구현 (표준 API 워크플로우)
- [x] CSRF 인증 로직 모든 서비스에 통합
- [x] 공통 에러 처리 및 디버깅 로그 통합
- [x] API 대칭성 달성 (모든 서비스 일관된 구조)
- [x] YFAPIBuilder Sendable struct로 개선 (thread-safe, immutable pattern)
- [x] Codable → Decodable 변환 완료 (성능 최적화, encoding 기능 제거)
- [x] isRealtime 속성 제거 (YFQuote 간소화)
- [x] QuoteSummaryResponse 중간 모델 제거 (YFQuote 직접 파싱)
- [x] Mock 사용 제거 (실제 API 테스트로 변경)

### Phase 3: Financial API 서비스 통합 ✅
- [x] **YFFundamentalsService 통합 구조체 생성** (단일 API 호출로 모든 재무 데이터 조회)
- [x] **API 중복 제거**: fundamentals-timeseries API 단일 호출로 통합
- [x] **중복 서비스 제거**: YFFinancialsService, YFBalanceSheetService 제거
- [x] **yfinance-reference 호환성**: Python 라이브러리와 동일한 아키텍처 적용
- [x] **68개 Balance Sheet 메트릭 지원** (yfinance-reference const.py 기준)
- [x] **Thread-safe 구현**: FundamentalsTimeseriesResponse Sendable 준수
- [x] **포괄적 테스트**: 아키텍처, 실제 데이터, 동시성, 일관성, 성능 테스트

### Phase 4: Advanced API 서비스 클래스 생성 ✅
- [x] **YFNewsService 구조체 생성** (fetchNews, fetchMultipleNews 메서드들)
  - [x] Raw JSON 지원 (CLI용 fetchRawJSON 메서드)
  - [x] 썸네일 이미지 및 관련 종목 파싱 개선
  - [x] 실제 API 응답 구조 기반 모델 업데이트
- [x] **YFOptionsService 구조체 생성** (fetchOptionsChain, fetchRawJSON 메서드들)
  - [x] 옵션 체인 데이터 파싱 (calls/puts, strikes, expirations)
  - [x] Raw JSON 지원 (CLI용 fetchRawJSON 메서드)
  - [x] 특정 만기일 필터링 지원
  - [x] 포괄적인 TDD 테스트 스위트 구현
  - [x] 실제 Yahoo Finance API 응답 구조 반영
- [x] **CLI 명령어 추가**: options 명령어 (Raw JSON 및 포맷된 출력 지원)
- [x] **JSON 샘플 개선**: API-TICKER 네이밍 컨벤션 (news-aapl.json, options-tsla.json)
- [x] **YFScreeningService 구조체 생성** (screenPredefined, fetchRawJSON 메서드들)
  - [x] 사전 정의 스크리너 지원 (9개 타입)
  - [x] Raw JSON 지원 (CLI용 fetchRawJSON 메서드)
  - [x] Protocol + Struct 패턴 적용
  - [x] 포괄적인 TDD 테스트 스위트 구현
- [x] **CLI 명령어 추가**: screening 명령어 (Raw JSON 및 포맷된 출력 지원)
- [ ] **YFAnalysisService 구조체 생성** (애널리스트 분석 데이터) - 🎯 다음 작업
  - [ ] 애널리스트 목표가 (analyst_price_targets)
  - [ ] 실적 추정치 (earnings_estimate, revenue_estimate)
  - [ ] EPS 트렌드 및 수정사항 (eps_trend, eps_revisions)
  - [ ] 성장률 추정치 (growth_estimates)
  - [ ] Protocol + Struct 패턴 적용
  - [ ] Yahoo Finance quoteSummary API 활용
  - [ ] TDD 테스트 스위트 구현
- [ ] YFWebSocketService 구조체 생성 (startRealTimeStreaming)

### Phase 5: YFClient 리팩토링 ✅
- [x] YFClient에 computed property로 모든 서비스 추가 (lazy 대신 경량 struct 활용)
- [x] YFClient의 private 유틸리티 메서드 제거
- [x] YFClient의 Debug Methods extension 통합

### Phase 6: 기존 파일 정리 🚧
- [x] YFQuoteAPI.swift 제거
- [x] YFHistoryAPI.swift 제거
- [x] YFSearchAPI.swift 제거
- [x] YFAPIHelper.swift 제거 (기능을 YFBaseService로 통합)
- [x] **YFFinancialsAPI.swift 제거** (통합된 YFFundamentalsService로 대체)
- [x] **YFBalanceSheetAPI.swift 제거** (통합된 YFFundamentalsService로 대체)
- [x] **YFCashFlowAPI.swift 제거** (통합된 YFFundamentalsService로 대체)
- [x] **YFEarningsAPI.swift 제거** (통합된 YFFundamentalsService로 대체)
- [x] **YFFinancialsAdvancedAPI.swift 제거** (통합된 YFFundamentalsService로 대체)
- [x] **YFNewsAPI.swift 제거** (YFNewsService로 대체 완료)
- [x] **YFOptionsAPI.swift 제거** (YFOptionsService로 대체 완료)
- [x] **YFScreeningAPI.swift 제거** (YFScreeningService로 대체 완료)
- [ ] YFWebSocketAPI.swift 제거
- [ ] **YFTechnicalIndicatorsAPI.swift 유지** (유틸리티 기능으로 보존)

### Phase 7: 테스트 및 문서 🚧
- [x] 구현된 Service 클래스 테스트 작성 (현재 128개 테스트)
  - [x] YFQuoteServiceTests (4개)
  - [x] YFHistoryServiceTests (16개)
  - [x] YFSearchServiceTests (20개)
  - [x] YFFundamentalsServiceTests (14개)
  - [x] YFNewsServiceTests (4개)
  - [x] YFOptionsServiceTests (6개)
  - [x] YFScreeningServiceTests (6개)
  - [ ] **YFAnalysisServiceTests** (예정) - 🎯 다음 작업
  - [ ] YFWebSocketServiceTests (예정)
- [x] YFClient 테스트 업데이트
- [x] 사용 예제 코드 업데이트 (CLI 명령어 구현)
- [ ] DocC 문서 업데이트

### Phase 8: 최종 검증 🚧
- [x] 현재 구현된 테스트 통과 확인 (128개 테스트 모두 통과)
- [x] 빌드 성공 확인 (Release 빌드 성공)
- [x] API 호환성 확인 (기존 사용법 유지)
- [ ] Tidy First 원칙에 따른 최종 커밋

## 구현 현황 및 로드맵

### ✅ 완료된 구성 요소
- **YFClient**: 메인 클라이언트 (모든 서비스의 진입점, Sendable struct)
- **YFService Protocol**: 모든 서비스의 공통 인터페이스 (Sendable 준수)
- **YFServiceCore**: 공통 기능 제공 구조체 (Composition 패턴, 인증/에러 처리/디버깅)
- **YFAPIBuilder**: Sendable URL 구성 Builder (thread-safe, immutable pattern)
- **YFDateHelper**: 날짜 변환 유틸리티 (period 계산, timestamp 변환)
- **YFChartConverter**: 차트 데이터 변환 유틸리티 (ChartResult → YFPrice[])
- **YFQuoteService**: 주식 시세 조회 서비스 (Protocol + Struct, Decodable 최적화)
- **YFHistoryService**: 과거 가격 데이터 조회 서비스 (일간/분간 OHLCV)
- **YFSearchService**: 종목 검색 및 자동완성 서비스
- **YFFundamentalsService**: 통합 재무제표 서비스 (Income Statement, Balance Sheet, Cash Flow 단일 API 호출)
- **YFNewsService**: 뉴스 데이터 조회 서비스 (단일/다중 종목 뉴스 조회, 썸네일 이미지 지원)
- **YFOptionsService**: 옵션 체인 데이터 조회 서비스 (옵션 체인, Raw JSON, 특정 만기일 조회)
- **YFScreeningService**: 종목 스크리닝 서비스 (사전 정의 스크리너, Raw JSON, 9개 타입 지원)

### 🚧 구현 예정 서비스들 (Phase 4+)
- **YFAnalysisService**: 애널리스트 분석 데이터 - 🎯 다음 작업
- **YFWebSocketService**: 실시간 스트리밍

## 설계 가이드라인

### 🏗️ 아키텍처 원칙
- **Protocol + Struct**: Extension/Class 대신 Protocol + Struct 패턴
- **Composition over Inheritance**: YFServiceCore를 통한 합성 패턴
- **완전한 Sendable 준수**: @unchecked 없이 순수 thread-safety 구현
- **단일 책임**: 각 서비스는 특정 도메인만 담당
- **경량 인스턴스**: computed property로 struct의 경량성 활용

### 📏 파일 관리
- **250줄 초과**: 분리 검토, **300줄 초과**: 강제 분리
- **테스트 파일**: 15개 메서드 초과 검토, 20개 초과 분리
- **의존성 단방향 유지**, **public 인터페이스 보존**

### 🎯 명명 규칙
- **일관된 메서드명**: fetch(), find(), suggestions()
- **명확한 파라미터**: ticker, period 등 명시적 이름
- **반환 타입**: YF[Domain] 형태 (YFQuote, YFHistory 등)

### 📈 성능 최적화
- **Decodable 우선**: encoding 기능 제거로 성능 향상
- **중간 모델 제거**: 불필요한 Response Wrapper 제거
- **struct 활용**: Reference Counting 오버헤드 제거


## 주요 장점
1. **완전한 Thread Safety**: @unchecked 없이 compile-time safety 보장
2. **성능 최적화**: struct 사용으로 Reference Counting 오버헤드 제거  
3. **메모리 효율성**: Decodable 사용으로 encoding 기능 제거
4. **명확한 책임 분리**: 도메인별 서비스로 코드 구조화
5. **유지보수 향상**: 변경 영향 범위 제한, 파일 크기 관리
6. **확장성**: 표준화된 패턴으로 새 서비스 추가 용이
7. **API 효율성**: 단일 fundamentals-timeseries 호출로 모든 재무 데이터 조회
8. **yfinance 호환성**: Python 라이브러리와 동일한 아키텍처 및 메트릭 지원

## 유틸리티 vs 서비스 구분
- **서비스 (Protocol + Struct)**: Yahoo Finance API를 호출하는 기능
  - YFQuoteService, YFHistoryService, YFAnalysisService 등
- **유틸리티 (Extension/Static)**: 자체 계산 및 헬퍼 기능
  - YFTechnicalIndicatorsAPI (기술적 지표 계산)
  - YFDateHelper, YFChartConverter 등