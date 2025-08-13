# 파일 조직화 규칙 및 원칙

## 🎯 분리 기준 (언제 분리할 것인가)

### 크기 기준 (모든 파일 공통)
- **250줄 초과**: 분리 검토 시작
- **300줄 초과**: 강제 분리 실행
- **테스트**: 15개 메서드 초과 시 검토, 20개 초과 시 강제 분리
- **소스코드**: 복잡도 15 초과 시 검토, 20 초과 시 분리
- **문서**: 섹션 10개 초과 시 검토, 15개 초과 시 분리

### 기능 기준
- 서로 다른 도메인 로직이 섞여있을 때
- 독립적으로 실행/사용 가능한 기능 그룹이 있을 때
- 의존성 구조가 복잡해질 때

## 📁 프로젝트 구조

### 전체 디렉토리 구조
```
SwiftYFinance/
├── Sources/SwiftYFinance/
│   ├── Core/                    # 핵심 비즈니스 로직
│   │   ├── YFClient.swift           # API 클라이언트
│   │   ├── YFSession.swift          # 네트워크 세션
│   │   ├── YFRequestBuilder.swift   # 요청 생성
│   │   ├── YFResponseParser.swift   # 응답 파싱
│   │   ├── YFHTMLParser.swift       # HTML 파싱
│   │   └── YFCookieManager.swift    # 쿠키 관리
│   ├── Models/                  # 데이터 모델
│   │   ├── YFError.swift            # 에러 정의
│   │   ├── YFTicker.swift           # 티커 정보
│   │   ├── YFPrice.swift            # 가격 데이터
│   │   ├── YFQuote.swift            # 실시간 시세
│   │   ├── YFHistoricalData.swift   # 과거 데이터
│   │   └── YFFinancials.swift       # 재무 정보
│   └── SwiftYFinance.swift      # 패키지 진입점
├── Tests/SwiftYFinanceTests/
│   ├── Parser/                  # JSON 파싱 관련
│   │   ├── BasicParsingTests.swift       # 기본 JSON 파싱
│   │   ├── TimestampParsingTests.swift   # 타임스탬프 변환
│   │   ├── OHLCVParsingTests.swift      # OHLCV 데이터 추출
│   │   └── ErrorParsingTests.swift      # 에러 응답 처리
│   ├── Network/                 # 네트워크 관련
│   │   ├── SessionTests.swift           # YFSession
│   │   └── RequestBuilderTests.swift   # YFRequestBuilder
│   ├── Client/                  # API 클라이언트
│   │   ├── PriceHistoryTests.swift     # 가격 이력
│   │   ├── QuoteDataTests.swift        # 실시간 시세
│   │   └── FinancialDataTests.swift    # 재무 데이터
│   ├── Models/                  # 데이터 모델
│   │   ├── TickerTests.swift
│   │   ├── PriceTests.swift
│   │   └── HistoricalDataTests.swift
│   └── Integration/             # 통합 테스트
│       ├── RealAPITests.swift         # 실제 API 호출
│       └── EndToEndTests.swift       # E2E 테스트
└── docs/
    ├── plans/                   # 개발 계획 문서
    │   ├── phase1-setup.md
    │   ├── phase2-models.md
    │   ├── phase3-network.md
    │   ├── phase4-api-integration.md
    │   ├── phase4-cookie-management.md
    │   ├── phase4-csrf-authentication.md
    │   └── file-organization.md
    ├── api/                     # API 문서
    │   ├── client-api.md
    │   ├── models-api.md
    │   └── error-handling.md
    └── guides/                  # 사용 가이드
        ├── quick-start.md
        ├── authentication.md
        └── advanced-usage.md
```

### 네이밍 컨벤션

#### 소스코드
- **패턴**: `YF{Feature}.swift`
- **예시**: `YFClient.swift`, `YFSession.swift`
- **클래스/구조체**: PascalCase
- **함수/변수**: camelCase

#### 테스트 파일
- **패턴**: `{Feature}Tests.swift` 
- **예시**: `SessionTests.swift`, `PriceHistoryTests.swift`

#### 문서 파일
- **패턴**: `{topic}-{subtopic}.md`
- **예시**: `phase1-setup.md`, `error-handling.md`
- **폴더 구조**: 목적별 분류 (plans/, api/, guides/)

## 🔄 분리 방식

### 소스코드 분리 원칙
1. **단일 책임 원칙**: 각 파일이 하나의 명확한 책임
2. **의존성 역전**: 고수준 모듈이 저수준 모듈에 의존하지 않음
3. **프로토콜 지향**: 구체 타입보다 프로토콜 사용

### 테스트 분리 원칙
1. **기능적 응집성**: 관련된 기능 테스트끼리 그룹화
2. **독립성**: 각 파일이 독립적으로 실행 가능
3. **빠른 실행**: 단위 테스트와 통합 테스트 분리

### 문서 분리 원칙
1. **주제별 분류**: 관련 주제별로 파일 분리
2. **깊이 제한**: 최대 3단계 깊이의 섹션 구조
3. **상호 참조**: 관련 문서 간 링크 유지

## 📋 분리 체크리스트

### Phase 1: 현재 상태 분석
- [ ] 각 소스 파일의 라인 수 확인
- [ ] 각 소스 파일의 복잡도 측정
- [ ] 테스트 파일의 메서드 개수 확인
- [ ] 문서 파일의 섹션 구조 확인
- [ ] 도메인별 그룹화 가능 여부 확인

### Phase 2: 분리 계획 수립
- [ ] 분리 대상 파일 우선순위 결정
- [ ] 각 파일별 분리 방식 결정
- [ ] 새로운 디렉토리 구조 설계
- [ ] 의존성 관계 다이어그램 작성

### Phase 3: 분리 실행
- [ ] 새 디렉토리 구조 생성
- [ ] 파일 분리 및 이동
- [ ] import 구문 및 의존성 확인
- [ ] 접근 제어자(public/internal/private) 조정
- [ ] 모든 테스트 실행하여 정상 동작 확인

### Phase 4: 검증 및 정리
- [ ] 빌드 및 테스트 성공 확인
- [ ] 코드 커버리지 유지 확인
- [ ] 문서 링크 및 참조 업데이트
- [ ] 불필요한 파일 정리
- [ ] git commit으로 변경사항 기록

## 🎯 소스 파일 분리 계획 (2025-08-13 업데이트)

### 🚨 즉시 분리 필요 (300줄 이상)

#### 1. YFClient.swift (1151줄) → 기능별 분리
```
현재 구조:
- YFPeriod, YFInterval enum (60줄)
- YFClient 클래스 + 6개 API 메서드 (850줄)
- ChartResponse 관련 구조체 (100줄)
- QuoteSummaryResponse 관련 구조체 (140줄)

분리 계획:
Core/YFEnums.swift (60줄)          # YFPeriod, YFInterval enum
Core/YFClient.swift (200줄)        # 메인 클래스 + 초기화
Core/YFHistoryAPI.swift (150줄)    # fetchHistory, fetchPriceHistory
Core/YFQuoteAPI.swift (100줄)      # fetchQuote (realtime 포함)
Core/YFFinancialsAPI.swift (350줄) # fetchFinancials, fetchBalanceSheet, fetchCashFlow, fetchEarnings
Models/YFChartModels.swift (100줄) # ChartResponse 구조체들
Models/YFQuoteModels.swift (140줄) # QuoteSummaryResponse 구조체들
```

#### 2. YFFinancials.swift (395줄) → 도메인별 분리
```
현재 구조:
- YFFinancials + YFFinancialReport (46줄)
- YFBalanceSheet + YFBalanceSheetReport (52줄)
- YFCashFlow + YFCashFlowReport (121줄)
- YFEarnings + YFEarningsReport (176줄)

분리 계획:
Models/YFFinancials.swift (90줄)   # YFFinancials + YFFinancialReport
Models/YFBalanceSheet.swift (90줄) # YFBalanceSheet + YFBalanceSheetReport  
Models/YFCashFlow.swift (130줄)    # YFCashFlow + YFCashFlowReport
Models/YFEarnings.swift (185줄)    # YFEarnings + YFEarningsReport
```

#### 3. YFSession.swift (326줄) → 책임별 분리
```
현재 구조:
- YFSession 메인 클래스 (100줄)
- CSRF 인증 메서드들 (150줄)
- Cookie 관리 메서드들 (76줄)

분리 계획:
Core/YFSession.swift (150줄)       # 메인 세션 클래스 + 기본 네트워크
Core/YFSessionAuth.swift (100줄)   # CSRF 인증 전용
Core/YFSessionCookie.swift (76줄)  # Cookie 관리 전용
```

### 현재 상태 (2025-08-13 업데이트)

#### 테스트 파일
```
파일명                          라인수    상태
YFCookieManagerTests.swift      341줄    🚨 즉시 분리 필요
YFSessionTests.swift            280줄    🔶 분리 검토 필요
YFRequestBuilderTests.swift     268줄    🔶 분리 검토 필요
QuoteSummaryTests.swift         246줄    ✅ 현재 적정
Parser/* (4개 파일)             각 <200줄 ✅ 분리 완료
Client/* (3개 파일)             각 <130줄 ✅ 분리 완료
Integration/RealAPITests.swift  162줄    ✅ 분리 완료
```

#### 소스 파일
```
파일명                          라인수    상태
YFClient.swift                  1151줄   🚨 즉시 분리 필요
YFFinancials.swift              395줄    🚨 즉시 분리 필요
YFSession.swift                 326줄    🚨 즉시 분리 필요
YFCookieManager.swift           204줄    ✅ 현재 적정
YFRequestBuilder.swift          73줄     ✅ 현재 적정
YFResponseParser.swift          39줄     ✅ 현재 적정
```

#### 문서 파일
```
파일명                          섹션수   상태
phase4-api-integration.md      12개     🔶 분리 검토 필요
phase3-network.md              8개      ✅ 현재 적정
phase2-models.md               7개      ✅ 현재 적정
```

## 📋 분리 실행 계획

### Phase 1: YFClient.swift 분리 (우선순위 1)
1. **YFEnums.swift** 생성 - YFPeriod, YFInterval enum 이동
2. **YFChartModels.swift** 생성 - Chart 관련 구조체 이동  
3. **YFQuoteModels.swift** 생성 - QuoteSummary 관련 구조체 이동
4. **YFHistoryAPI.swift** 생성 - fetchHistory, fetchPriceHistory 메서드
5. **YFQuoteAPI.swift** 생성 - fetchQuote 메서드들
6. **YFFinancialsAPI.swift** 생성 - 재무 관련 4개 메서드
7. **YFClient.swift** 정리 - 메인 클래스 + 초기화만 유지

### Phase 2: YFFinancials.swift 분리 (우선순위 2)
1. **YFFinancials.swift** 정리 - 기본 재무제표만 유지
2. **YFBalanceSheet.swift** 생성 - 대차대조표 모델
3. **YFCashFlow.swift** 생성 - 현금흐름표 모델  
4. **YFEarnings.swift** 생성 - 손익계산서 모델

### Phase 3: YFSession.swift 분리 (우선순위 3)
1. **YFSessionAuth.swift** 생성 - CSRF 인증 메서드들
2. **YFSessionCookie.swift** 생성 - 쿠키 관리 메서드들
3. **YFSession.swift** 정리 - 메인 세션 클래스만 유지

### 분리 순서 (완료된 항목)
1. **~~1순위~~**: ~~YFResponseParserTests.swift → Parser/ 폴더로 분리~~ ✅ 완료
2. **~~2순위~~**: ~~YFClientTests.swift → Client/ 폴더로 분리~~ ✅ 완료

## 📝 유지보수 원칙

### 지속적인 모니터링
- 새로운 코드/테스트/문서 추가 시 적절한 파일 배치
- 정기적인 파일 크기 점검 (250줄 기준)
- 복잡도 메트릭 모니터링
- 테스트 실행 시간 모니터링

### 리팩토링 가이드라인
- 파일 분리는 구조적 변경이므로 Tidy First 원칙 적용
- 분리 작업은 독립된 커밋으로 관리
- 기능 변경과 분리 작업을 혼재하지 않음
- 각 분리 후 전체 테스트 스위트 실행

### 문서 관리
- API 변경 시 관련 문서 즉시 업데이트
- 예제 코드는 실제 테스트 코드와 동기화
- 버전별 변경사항 추적 (CHANGELOG.md)

## 🚀 Best Practices

### 소스코드
- 프로토콜을 통한 의존성 주입
- 확장(Extension)을 통한 기능 분리
- 중첩 타입 최소화
- 명확한 접근 제어자 사용

### 테스트
- Given-When-Then 패턴 사용
- 테스트 더블(Mock, Stub) 활용
- 테스트 fixture 재사용
- 실패 메시지 명확화

### 문서
- 코드 예제 포함
- 다이어그램 활용
- FAQ 섹션 유지
- 버전 호환성 명시