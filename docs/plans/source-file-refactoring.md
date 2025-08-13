# 소스 파일 리팩토링 가이드

## 🚨 **작업 원칙 (매우 중요!)**

### 작업 순서
1. **문서 먼저 업데이트**: 작업 완료 후 바로 커밋하지 말고 **반드시 문서부터 업데이트**
2. **변경사항 문서화**: plan.md, source-file-refactoring.md 등 관련 문서 상태 업데이트
3. **체크리스트 갱신**: 완료된 작업을 체크리스트에서 [x]로 표시
4. **그 다음 커밋**: 문서 업데이트 완료 후 코드와 문서를 함께 커밋

### 의존성 관리
1. **순환 참조 방지**: extension을 활용하여 의존성 단방향 유지
2. **Import 최소화**: 필요한 Foundation 모듈만 import
3. **접근 제어**: public/internal/private 적절히 설정

### 테스트 호환성
1. **@testable import**: 분리 후에도 기존 테스트가 동작하도록
2. **API 호환성**: public 인터페이스 변경 없이 내부 구조만 정리
3. **테스트 파일 매핑**: 새 파일에 맞춰 테스트도 일부 조정 필요

### 빌드 안정성
1. **점진적 분리**: 한 번에 하나씩 분리하여 빌드 오류 최소화
2. **컴파일 검증**: 각 단계마다 swift build 확인
3. **테스트 검증**: swift test로 기능 정상 동작 확인

---

## 🎯 개요

현재 프로젝트의 3개 대형 소스 파일을 기능별/책임별로 분리하여 유지보수성과 가독성을 향상시킵니다.

- **YFClient.swift**: 856줄 → 4개 파일로 분리 (일부 이미 완료)
- **YFFinancials.swift**: 395줄 → 4개 파일로 분리  
- **YFSession.swift**: 326줄 → 3개 파일로 분리

## 📊 분리 전/후 비교

### 현재 상태 (2025-08-13 업데이트)
```
Sources/SwiftYFinance/
├── Core/
│   ├── YFClient.swift          (157줄)  ✅ 정리 완료
│   ├── YFSession.swift         (326줄)  🚨 분리 필요
│   ├── YFEnums.swift           (52줄)   ✅ 완료
│   ├── YFHistoryAPI.swift      (252줄)  ✅ 완료
│   ├── YFQuoteAPI.swift        (137줄)  ✅ 완료
│   ├── YFFinancialsAPI.swift   (463줄)  🚨 분리 필요
│   ├── YFBalanceSheetAPI.swift (149줄)  ✅ 완료
│   ├── YFRequestBuilder.swift  (73줄)   ✅ 완료
│   ├── YFResponseParser.swift  (39줄)   ✅ 완료
│   ├── YFCookieManager.swift   (204줄)  ✅ 완료
│   └── YFHTMLParser.swift      (70줄)   ✅ 완료
└── Models/
    ├── YFFinancials.swift      (395줄)  🚨 분리 필요
    ├── YFChartModels.swift     (91줄)   ✅ 완료
    ├── YFQuoteModels.swift     (48줄)   ✅ 완료
    ├── YFHistoricalData.swift  (31줄)   ✅ 완료
    ├── YFQuote.swift           (62줄)   ✅ 완료
    ├── YFTicker.swift          (27줄)   ✅ 완료
    ├── YFPrice.swift           (32줄)   ✅ 완료
    └── YFError.swift           (7줄)    ✅ 완료
```

### 목표 (남은 작업)
```
Sources/SwiftYFinance/
├── Core/
│   ├── YFClient.swift          (200줄)  ⏳ 대기
│   ├── YFQuoteAPI.swift        (150줄)  ⏳ 대기
│   ├── YFFinancialsAPI.swift   (350줄)  ⏳ 대기
│   ├── YFSession.swift         (150줄)  ⏳ 대기
│   ├── YFSessionAuth.swift     (100줄)  ⏳ 대기
│   └── YFSessionCookie.swift   (76줄)   ⏳ 대기
└── Models/
    ├── YFFinancials.swift      (90줄)   ⏳ 대기
    ├── YFBalanceSheet.swift    (90줄)   ⏳ 대기
    ├── YFCashFlow.swift        (130줄)  ⏳ 대기
    └── YFEarnings.swift        (185줄)  ⏳ 대기
```

## 🔧 Phase 1: YFClient.swift 분리

### 현재 구조 분석
```swift
// YFClient.swift (1151줄)
enum YFPeriod { ... }                    // 16줄 (5-21)
enum YFInterval { ... }                  // 44줄 (20-64)

class YFClient {                         // 838줄 (55-893)
    // 초기화 및 프로퍼티              // 20줄 (55-75)
    func fetchPriceHistory(...)          // 62줄 (73-135)
    func fetchHistory(...) x2            // 40줄 (135-175)
    func fetchQuote(...) x2              // 127줄 (175-302)
    func fetchFinancials(...)            // 99줄 (302-401)
    func fetchBalanceSheet(...)          // 119줄 (401-520)
    func fetchCashFlow(...)              // 126줄 (520-646)
    func fetchEarnings(...)              // 122줄 (646-768)
    private func periodStart(...)        // 25줄 (768-793)
    // ... 기타 유틸리티 메서드
}

// API Response 구조체들
struct ChartResponse { ... }             // 86줄 (905-991)
struct QuoteSummaryResponse { ... }      // 160줄 (995-1155)
```

### 분리 계획

#### 1. YFEnums.swift (60줄)
```swift
// YFPeriod, YFInterval enum + extension 이동
public enum YFPeriod { ... }
public enum YFInterval { ... }
```

#### 2. Models/YFChartModels.swift (100줄)
```swift
// Chart API 응답 구조체들 이동
struct ChartResponse: Codable { ... }
struct Chart: Codable { ... }
struct ChartResult: Codable { ... }
// ... 기타 Chart 관련 구조체
```

#### 3. Models/YFQuoteModels.swift (140줄)
```swift
// QuoteSummary API 응답 구조체들 이동
struct QuoteSummaryResponse: Codable { ... }
struct QuoteSummary: Codable { ... }
struct PriceData: Codable { ... }
// ... 기타 Quote 관련 구조체
```

#### 4. Core/YFHistoryAPI.swift (150줄)
```swift
// YFClient 확장으로 history 관련 메서드들
extension YFClient {
    public func fetchPriceHistory(...) async throws -> YFHistoricalData
    public func fetchHistory(...) async throws -> YFHistoricalData
    private func periodStart(...) -> String
}
```

#### 5. Core/YFQuoteAPI.swift (100줄)
```swift
// YFClient 확장으로 quote 관련 메서드들
extension YFClient {
    public func fetchQuote(...) async throws -> YFQuote
    public func fetchQuote(..., realtime: Bool) async throws -> YFQuote
}
```

#### 6. Core/YFFinancialsAPI.swift (350줄)
```swift
// YFClient 확장으로 재무 관련 메서드들
extension YFClient {
    public func fetchFinancials(...) async throws -> YFFinancials
    public func fetchBalanceSheet(...) async throws -> YFBalanceSheet
    public func fetchCashFlow(...) async throws -> YFCashFlow
    public func fetchEarnings(...) async throws -> YFEarnings
}
```

#### 7. Core/YFClient.swift (200줄)
```swift
// 메인 클래스 + 초기화 + 공통 유틸리티만 유지
public class YFClient {
    private let session: YFSession
    private let requestBuilder: YFRequestBuilder
    private let responseParser: YFResponseParser
    
    public init() { ... }
    // 공통 헬퍼 메서드들만 유지
}
```

## 🔧 Phase 2: YFFinancials.swift 분리

### 현재 구조 분석
```swift
// YFFinancials.swift (395줄)
public struct YFFinancials { ... }       // 46줄 (3-49)
public struct YFBalanceSheet { ... }     // 52줄 (49-101) 
public struct YFCashFlow { ... }         // 121줄 (97-218)
public struct YFEarnings { ... }         // 176줄 (218-394)
```

### 분리 계획

#### 1. Models/YFFinancials.swift (90줄)
```swift
// 기본 재무제표 구조체만 유지
public struct YFFinancials: Codable { ... }
public struct YFFinancialReport: Codable { ... }
```

#### 2. Models/YFBalanceSheet.swift (90줄) 
```swift
// 대차대조표 관련 구조체들
public struct YFBalanceSheet: Codable { ... }
public struct YFBalanceSheetReport: Codable { ... }
```

#### 3. Models/YFCashFlow.swift (130줄)
```swift  
// 현금흐름표 관련 구조체들
public struct YFCashFlow: Codable { ... }
public struct YFCashFlowReport: Codable { ... }
```

#### 4. Models/YFEarnings.swift (185줄)
```swift
// 손익계산서 관련 구조체들  
public struct YFEarnings: Codable { ... }
public struct YFEarningsReport: Codable { ... }
public struct YFEarningsEstimate: Codable { ... }
```

## 🔧 Phase 3: YFSession.swift 분리

### 현재 구조 분석
```swift
// YFSession.swift (326줄)
public class YFSession {
    // 기본 세션 관리                  // 100줄
    // CSRF 인증 메서드들              // 150줄  
    // Cookie 관리 메서드들            // 76줄
}
```

### 분리 계획

#### 1. Core/YFSession.swift (150줄)
```swift
// 메인 세션 클래스 + 기본 네트워크 기능만 유지
public class YFSession {
    public func request(...) async throws -> Data
    // 기본 HTTP 요청 처리
}
```

#### 2. Core/YFSessionAuth.swift (100줄)
```swift
// CSRF 인증 전용 extension
extension YFSession {
    public func authenticateCSRF() async throws
    private func attemptCSRFAuthentication() async -> Bool
    private func getConsentTokens() async -> [String: String]?
    private func processConsent(...) async -> Bool
}
```

#### 3. Core/YFSessionCookie.swift (76줄)
```swift
// Cookie 관리 전용 extension  
extension YFSession {
    // Cookie 관련 메서드들
}
```


## 🎯 예상 효과

### 가독성 향상
- 파일당 평균 150줄로 관리 용이
- 기능별 분리로 코드 탐색성 증가
- 단일 책임 원칙 준수

### 유지보수성 향상  
- 변경 영향 범위 축소
- 병렬 개발 가능
- 코드 재사용성 증가

### 성능 향상
- 컴파일 시간 단축 (증분 컴파일)
- IDE 응답성 개선
- 메모리 사용량 최적화

## 📋 체크리스트

### Phase 1: YFClient.swift 분리
- [x] YFEnums.swift 생성 및 이동 ✅ 완료 (52줄)
- [x] YFChartModels.swift 생성 및 이동 ✅ 완료 (91줄)
- [x] YFQuoteModels.swift 생성 및 이동 ✅ 완료 (48줄)
- [x] YFHistoryAPI.swift 생성 및 이동 ✅ 완료 (252줄)
- [x] YFQuoteAPI.swift 생성 및 이동 ✅ 완료 (137줄)
- [x] YFFinancialsAPI.swift 생성 및 이동 ✅ 완료 (463줄, 여전히 분리 필요)
- [x] YFClient.swift 정리 ✅ 완료 (710줄 → 157줄)
- [x] 컴파일 및 테스트 검증 ✅ 완료

### Phase 1.5: YFFinancialsAPI.swift 추가 분리 (463줄 → 3개 파일)
- [x] YFBalanceSheetAPI.swift 생성 및 이동 ✅ 완료 (149줄)
- [ ] YFCashFlowAPI.swift 생성 및 이동 ⏳ **다음 작업**
- [ ] YFEarningsAPI.swift 생성 및 이동
- [ ] YFFinancialsAPI.swift 정리 (fetchFinancials만 남기기)

### Phase 2: YFFinancials.swift 분리  
- [ ] YFBalanceSheet.swift 생성 및 이동
- [ ] YFEarnings.swift 생성 및 이동
- [ ] YFFinancials.swift 정리
- [ ] 컴파일 및 테스트 검증

### Phase 3: YFSession.swift 분리
- [ ] YFSessionAuth.swift 생성 및 이동
- [ ] YFSessionCookie.swift 생성 및 이동  
- [ ] YFSession.swift 정리
- [ ] 컴파일 및 테스트 검증

### 최종 검증
- [ ] 전체 테스트 스위트 통과
- [ ] API 호환성 확인
- [ ] 문서 업데이트
- [ ] Git commit 및 정리