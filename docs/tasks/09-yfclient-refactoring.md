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
- [x] YFQuoteAPI.swift 제거
- [x] YFHistoryAPI.swift 제거
- [x] YFSearchAPI.swift 제거
- [x] YFAPIHelper.swift 제거 (기능을 YFBaseService로 통합)
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

### 🚧 구현 예정 서비스들 (Phase 3)
- **YFFinancialsService**: 재무제표 데이터
- **YFBalanceSheetService**: 대차대조표
- **YFCashFlowService**: 현금흐름표
- **YFEarningsService**: 실적 데이터

### 🚧 구현 예정 서비스들 (Phase 4+)
- **YFNewsService**: 뉴스 데이터
- **YFOptionsService**: 옵션 체인 데이터
- **YFWebSocketService**: 실시간 스트리밍
- **YFScreeningService**: 종목 스크리닝
- **YFTechnicalIndicatorsService**: 기술적 지표

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