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

## 구조 변화

### 🔄 Before vs After

#### 기존 구조 (Extension 기반)
```swift
// 문제점: 모든 API가 YFClient에 직접 구현
extension YFClient {
    func fetch{Domain}(...) { ... }  // 각 도메인별 메서드들이 확장에 분산
}

// 사용법
let result = try await client.fetch{Domain}(...)
```

#### 새로운 구조 (Service 기반)
```swift
// 해결: 도메인별 독립적인 서비스 클래스
class YFClient {
    lazy var {domain} = YF{Domain}Service(client: self)
}

class YF{Domain}Service {
    private weak var client: YFClient?  // 순환 참조 방지
    
    init(client: YFClient) {
        self.client = client
    }
    
    func {method}(...) async throws -> YF{Domain} {
        guard let client = client else { 
            throw YFError.apiError("Client reference is nil") 
        }
        // client.session, client.requestBuilder, client.responseParser 사용
        // ... API 구현
    }
}
```

#### 사용법 변화
```swift
// Before: 직접 호출
client.fetch{Domain}(...)

// After: 서비스를 통한 호출
client.{domain}.{method}(...)
```

## 구현 체크리스트

### Phase 1: 공통 유틸리티 분리 ✅
- [x] YFDateHelper 클래스 생성 (periodStart, periodEnd, dateFromPeriod, periodToRangeString)
- [x] YFChartConverter 클래스 생성 (convertToPrices)
- [x] YFClient에서 YFDateHelper 사용으로 변경

### Phase 2: Core API 서비스 클래스 생성 ✅
- [x] YFBaseService 부모 클래스 생성 (공통 기능 통합)
- [x] YFQuoteService 클래스 생성 (fetch 메서드들만 유지)
- [x] YFQuoteService에서 하위 호환성 fetchQuote 메서드 제거 (새 규칙 적용)
- [x] YFQuoteAPI.swift 파일 완전 제거
- [x] YFClient에서 fetchQuote 위임 메서드 제거 (서비스 기반으로 완전 전환)
- [x] YFQuoteService가 YFClient를 인수로 받도록 구조 변경 (더 깔끔한 설계)
- [x] 순환 참조 방지를 위한 weak reference 적용
- [x] YFHistoryService 클래스 생성 (fetchHistory, fetchPriceHistory)
- [x] YFSearchService 클래스 생성 (search, searchSuggestions)
- [x] Template Method 패턴 구현 (표준 API 워크플로우)
- [x] CSRF 인증 로직 모든 서비스에 통합
- [x] 공통 에러 처리 및 디버깅 로그 통합
- [x] API 대칭성 달성 (모든 서비스 일관된 구조)

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
- **YFClient**: 메인 클라이언트 (모든 서비스의 진입점)
- **YFBaseService**: 모든 서비스의 공통 기능 부모 클래스 (인증, 에러 처리, 디버깅)
- **YFDateHelper**: 날짜 변환 유틸리티 (period 계산, timestamp 변환)
- **YFChartConverter**: 차트 데이터 변환 유틸리티 (ChartResult → YFPrice[])
- **YFQuoteService**: 주식 시세 조회 서비스
- **YFHistoryService**: 과거 가격 데이터 조회 서비스 (일간/분간 OHLCV)
- **YFSearchService**: 종목 검색 및 자동완성 서비스

### 🚧 구현 예정 서비스들
- **YFFinancialsService**: 재무제표 데이터
- **YFBalanceSheetService**: 대차대조표
- **YFCashFlowService**: 현금흐름표
- **YFEarningsService**: 실적 데이터
- **YFNewsService**: 뉴스 데이터
- **YFOptionsService**: 옵션 체인 데이터
- **YFWebSocketService**: 실시간 스트리밍
- **YFScreeningService**: 종목 스크리닝
- **YFTechnicalIndicatorsService**: 기술적 지표

### 🎯 최종 목표 구조
```swift
// 단일 진입점을 통한 모든 기능 접근
YFClient()
  ├── .{service1}.{method}(...)    // 각 도메인별 서비스
  ├── .{service2}.{method}(...)    // 독립적인 책임과 구현
  ├── .{service3}.{method}(...)    // 일관된 인터페이스
  └── .{serviceN}.{method}(...)    // 확장 가능한 구조

// 서비스 패턴 예시:
// client.quote.fetch(...)         ← 시세 조회
// client.history.fetch(...)       ← 과거 데이터
// client.search.find(...)         ← 검색 기능
// client.financials.fetch(...)    ← 재무 데이터
// client.webSocket.stream(...)    ← 실시간 스트리밍
```

## 사용 패턴 템플릿

### 🏁 기본 사용 패턴
```swift
// 1. 클라이언트 초기화
let client = YFClient()

// 2. 서비스를 통한 API 호출
let result = try await client.{service}.{method}({parameters})

// 3. 결과 활용
// result는 YF{Domain} 타입의 구조화된 데이터
```

### 📋 서비스별 사용 템플릿

#### Quote 서비스 (시세)
```swift
client.quote.fetch(ticker: {ticker})                    // 기본 시세
```

#### History 서비스 (과거 데이터)
```swift
client.history.fetch(ticker: {ticker}, period: {period})           // 기간별
client.history.fetch(ticker: {ticker}, from: {date}, to: {date})   // 날짜 범위
```

#### Search 서비스 (검색)
```swift
client.search.find({query})           // 종목 검색
client.search.suggestions({prefix})   // 자동완성
```

#### Financial 서비스들 (재무 데이터)
```swift
client.financials.fetch(ticker: {ticker})      // 재무제표
client.balanceSheet.fetch(ticker: {ticker})    // 대차대조표
client.cashFlow.fetch(ticker: {ticker})        // 현금흐름표
client.earnings.fetch(ticker: {ticker})        // 실적
```

#### 기타 서비스들
```swift
client.news.fetch(ticker: {ticker})                    // 뉴스
client.options.fetchChain(ticker: {ticker})            // 옵션
client.webSocket.startStreaming(symbols: {symbols})    // 실시간 스트리밍
client.screening.screen(criteria: {criteria})          // 스크리닝
```

## 장점
1. **명확한 책임 분리**: 각 서비스가 단일 책임
2. **코드 탐색 용이**: 기능별로 파일 분리
3. **테스트 용이**: 각 서비스 독립 테스트 가능
4. **유지보수 향상**: 변경 영향 범위 제한
5. **확장성**: 새 서비스 추가 용이

## 설계 원칙 및 주의사항

### 🏗️ 아키텍처 설계 원칙
- **서비스 기반 구조**: Extension 대신 독립적인 Service 클래스 사용
- **단일 책임 원칙**: 각 서비스는 특정 도메인만 담당
- **의존성 주입**: 모든 서비스는 `YFClient(client:)` 생성자로 클라이언트 주입
- **순환 참조 방지**: 서비스에서 `weak var client` 사용으로 메모리 안전성 보장
- **지연 초기화**: `lazy var`로 필요할 때만 서비스 인스턴스 생성

### 🎯 API 명명 규칙
- **일관된 메서드명**: 모든 서비스에서 `fetch()` 메서드 사용
- **명확한 파라미터**: ticker, period 등 명시적 파라미터명
- **반환 타입 일관성**: YF[Domain] 형태의 반환 타입 (YFQuote, YFHistory 등)

### 🔧 확장 가이드라인
#### 새로운 서비스 추가 시:
```swift
// 1. 서비스 클래스 생성 (YFBaseService 상속)
public final class YF[Domain]Service: YFBaseService {
    
    public func fetch(...) async throws -> YF[Domain] {
        let client = try validateClientReference()
        
        // CSRF 인증 시도
        await ensureCSRFAuthentication(client: client)
        
        // API 요청 및 응답 처리
        let url = try buildURL(baseURL: "...", parameters: [...])
        let (data, _) = try await authenticatedRequest(url: url)
        
        // 디버깅 로그
        logAPIResponse(data, serviceName: "[Domain]")
        
        // JSON 파싱 및 반환
        let response = try parseJSON(data: data, type: [Response].self)
        return [Domain](from: response)
    }
}

// 2. YFClient에 lazy property 추가
public lazy var [domain] = YF[Domain]Service(client: self, debugEnabled: debugEnabled)
```

### ⚠️ 중요한 제약사항
- **Extension 금지**: YFClient에 extension 추가 금지
- **Protocol 금지**: 프로토콜 사용 금지 (구체 클래스만 사용)
- **하위 호환성 없음**: 기존 fetchXXX 메서드는 완전 제거됨
- **메서드명 통일**: fetch(), find(), suggestions() 등 일관된 명명

### 🧪 테스트 패턴
```swift
@Suite("[ServiceName] Tests")
struct YF[Service]Tests {
    private func createMockClient() -> YFClient {
        return YFClient()
    }
    
    @Test("서비스 초기화")
    func testInitialization() {
        let client = createMockClient()
        let service = YF[Service](client: client)
        #expect(service != nil)
    }
}
```

### 📦 파일 구조
```
Sources/SwiftYFinance/
├── Core/
│   └── YFClient.swift              # 메인 클라이언트
├── Services/                       # 서비스 클래스들
│   └── YF[Domain]Service.swift
├── Helpers/                        # 공통 유틸리티
│   ├── YFDateHelper.swift
│   └── YFChartConverter.swift
└── Models/                         # 데이터 모델들
    └── YF[Domain].swift
```