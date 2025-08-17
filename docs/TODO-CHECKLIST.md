# SwiftYFinance TODO Checklist

SwiftYFinance 프로젝트의 미완성 기능들을 정리한 체크리스트입니다. 모든 항목은 현재 적절한 에러 처리로 안정화되어 있으며, 향후 단계적 구현이 가능합니다.

## 📊 TODO 현황 요약

- **총 TODO 항목**: 8개
- **카테고리**: 2개 (Options API, Advanced Financials API)
- **현재 상태**: 모든 항목이 "not yet completed" 에러로 안정화
- **테스트 영향**: 없음 (254개 테스트 모두 통과)

---

## 🔴 Category 1: Options Trading API

### 📁 파일: `Sources/SwiftYFinance/Core/YFOptionsAPI.swift`

#### ☐ 1. 옵션 체인 조회 API 구현
- **라인**: 28
- **메서드**: `fetchOptionsChain(ticker:expiry:) -> YFOptionsChain`
- **설명**: 특정 종목의 옵션 체인 데이터를 조회하는 기능
- **yfinance 참조**: 
  - **파일**: `yfinance-reference/yfinance/ticker.py:87`
  - **메서드**: `option_chain(date=None, tz=None)`
  - **내부 메서드**: `_download_options(date=None)` (line 46)
  - **API 엔드포인트**: `{BASE_URL}/v7/finance/options/{ticker}?date={date}`
- **TDD 구현 단계**:
  
  **🔴 Red (테스트 작성)**:
  - [ ] `testFetchOptionsChainValidSymbol()` - AAPL 옵션 체인 조회 테스트
  - [ ] `testFetchOptionsChainInvalidSymbol()` - 잘못된 심볼 에러 테스트 
  - [ ] `testFetchOptionsChainNoOptions()` - 옵션이 없는 종목 테스트
  - [ ] `testOptionsChainDataStructure()` - calls/puts/underlying 구조 검증
  
  **🟢 Green (최소 구현)**:
  - [ ] YFOptionsChain 모델 설계 (calls, puts, underlying)
  - [ ] Yahoo Finance API 엔드포인트 (`/v7/finance/options/{symbol}`)
  - [ ] 기본 JSON 파싱 (`optionChain.result[0]`)
  - [ ] 에러 처리 (YFError.apiError, YFError.parsingError)
  
  **🟡 Refactor (코드 정리)**:
  - [ ] `_options2df()` 등가 로직 구현 (contractSymbol, strike, lastPrice)
  - [ ] 만료일 타임스탬프 파싱 최적화 (`expirationDates` 배열)
  - [ ] DocC 문서화 완성
  - [ ] 파일 크기 확인 및 필요시 분리

#### ☐ 2. 특정 만기일 옵션 체인 조회
- **라인**: 40  
- **메서드**: `fetchOptionsChain(ticker:expiry:) -> OptionsChain`
- **설명**: 특정 만기일의 옵션 체인만 조회하는 기능
- **yfinance 참조**: 
  - **파일**: `yfinance-reference/yfinance/ticker.py:87`
  - **메서드**: `option_chain(date=None, tz=None)` - date 파라미터 사용
  - **검증 로직**: line 93-96 (만기일 존재 여부 확인)
  - **에러 처리**: `ValueError` when date not in expirations
- **TDD 구현 단계**:
  
  **🔴 Red (테스트 작성)**:
  - [ ] `testFetchOptionsChainSpecificExpiry()` - 특정 만기일 조회 테스트
  - [ ] `testFetchOptionsChainInvalidExpiry()` - 잘못된 만기일 에러 테스트
  - [ ] `testOptionsChainExpiryValidation()` - 만료일 검증 로직 테스트
  
  **🟢 Green (최소 구현)**:
  - [ ] OptionsChain vs YFOptionsChain 모델 차이점 정의
  - [ ] 만기일 파라미터 처리 (date → timestamp 변환)
  - [ ] 만료일 검증 로직 (yfinance ValueError 패턴)
  
  **🟡 Refactor (코드 정리)**:
  - [ ] `_expirations` 딕셔너리 활용 패턴 구현
  - [ ] 에러 메시지 개선 및 현지화
  - [ ] 중복 코드 제거 및 공통 로직 추출

#### ☐ 3. 옵션 만기일 목록 조회
- **라인**: 51
- **메서드**: `getOptionsExpirationDates(ticker:) -> [Date]`
- **설명**: 특정 종목의 모든 옵션 만기일 목록을 조회
- **yfinance 참조**: 
  - **파일**: `yfinance-reference/yfinance/ticker.py:309`
  - **프로퍼티**: `options` (returns tuple of expiration dates)
  - **내부 로직**: `_expirations.keys()` (line 312)
  - **데이터 소스**: `_download_options()` → `expirationDates` 배열
  - **날짜 형식**: Unix timestamp → `%Y-%m-%d` 문자열 (line 55)
- **TDD 구현 단계**:
  
  **🔴 Red (테스트 작성)**:
  - [ ] `testGetOptionsExpirationDatesValidSymbol()` - AAPL 만료일 목록 테스트
  - [ ] `testGetOptionsExpirationDatesInvalidSymbol()` - 잘못된 심볼 에러
  - [ ] `testOptionsExpirationDatesFormat()` - 날짜 형식 검증 테스트
  - [ ] `testOptionsExpirationDatesCaching()` - 캐싱 동작 테스트
  
  **🟢 Green (최소 구현)**:
  - [ ] API 엔드포인트 활용 (`/v7/finance/options/{symbol}`)
  - [ ] 기본 날짜 파싱 (Unix timestamp → Date)
  - [ ] `expirationDates` 배열 추출
  
  **🟡 Refactor (코드 정리)**:
  - [ ] 날짜 형식 표준화 (`_pd.Timestamp(exp, unit='s')` 패턴)
  - [ ] `_expirations` 딕셔너리 캐싱 구현
  - [ ] 초기 로딩 로직 최적화 (`_download_options()` 패턴)
  - [ ] 메모리 효율성 개선

---

## 🔵 Category 2: Advanced Financial Analysis API

### 📁 파일: `Sources/SwiftYFinance/Core/YFFinancialsAdvancedAPI.swift`

#### ☐ 4. 분기별 재무제표 조회
- **라인**: 20
- **메서드**: `fetchQuarterlyFinancials(ticker:) -> YFQuarterlyFinancials`
- **설명**: 분기별 상세 재무제표 데이터 조회
- **yfinance 참조**: 
  - **파일**: `yfinance-reference/yfinance/ticker.py:229`
  - **프로퍼티**: `quarterly_financials`, `quarterly_income_stmt`, `quarterly_balance_sheet`
  - **내부 호출**: `get_income_stmt(freq='quarterly')`, `get_balance_sheet(freq='quarterly')`
  - **API 엔드포인트**: `fundamentals-timeseries/v1/finance/timeseries/{symbol}` (line 127 in fundamentals.py)
  - **데이터 구조**: pandas DataFrame with quarterly columns
- **TDD 구현 단계**:
  
  **🔴 Red (테스트 작성)**:
  - [ ] `testFetchQuarterlyFinancialsValidSymbol()` - AAPL 분기 재무제표 테스트
  - [ ] `testQuarterlyFinancialsDataStructure()` - 분기별 컬럼 구조 검증
  - [ ] `testQuarterlyVsYearlyFinancials()` - 연간/분기 데이터 차이 테스트
  - [ ] `testQuarterlyFinancialsTimeSeries()` - 시계열 데이터 형식 검증
  
  **🟢 Green (최소 구현)**:
  - [ ] YFQuarterlyFinancials 모델 설계 (quarterly columns)
  - [ ] fundamentals-timeseries API 연동 (`freq='quarterly'`)
  - [ ] 기본 분기 데이터 파싱
  - [ ] 기존 YFFinancials와 차이점 정의
  
  **🟡 Refactor (코드 정리)**:
  - [ ] 시계열 데이터 처리 최적화 (`time_series` 구조)
  - [ ] 중복 로직 제거 (yearly와 공통 부분)
  - [ ] 캐싱 전략 구현
  - [ ] 파일 크기 관리 (필요시 분리)

#### ☐ 5. 재무 비율 계산
- **라인**: 29
- **메서드**: `calculateFinancialRatios(ticker:) -> YFFinancialRatios`
- **설명**: P/E, P/B, ROE 등 주요 재무 비율 계산
- **yfinance 참조**: 
  - **파일**: 기존 재무 데이터를 활용한 계산 (직접 API 없음)
  - **데이터 소스**: `get_income_stmt()`, `get_balance_sheet()`, `get_quote()`
  - **계산 베이스**: 손익계산서 + 대차대조표 + 현재가격 조합
  - **참조 패턴**: pandas DataFrame 기반 비율 계산
- **TDD 구현 단계**:
  
  **🔴 Red (테스트 작성)**:
  - [ ] `testCalculateFinancialRatiosValidSymbol()` - AAPL 재무 비율 계산 테스트
  - [ ] `testFinancialRatiosCalculations()` - 개별 비율 계산 정확성 테스트
  - [ ] `testFinancialRatiosZeroDivision()` - 0으로 나누기 에러 처리 테스트
  - [ ] `testFinancialRatiosDataIntegration()` - 기존 데이터 통합 테스트
  
  **🟢 Green (최소 구현)**:
  - [ ] YFFinancialRatios 모델 설계 (P/E, P/B, ROE, ROA 등)
  - [ ] 기존 YFClient 메서드 조합 (fetchFinancials + fetchQuote)
  - [ ] 기본 비율 계산 로직
  - [ ] nil/zero 분모 안전 처리
  
  **🟡 Refactor (코드 정리)**:
  - [ ] 재무 비율 계산 공식 최적화:
    - [ ] P/E Ratio (regularMarketPrice / EPS)
    - [ ] P/B Ratio (marketCap / totalStockholderEquity)
    - [ ] ROE (netIncome / totalStockholderEquity)
    - [ ] ROA (netIncome / totalAssets)
    - [ ] Debt-to-Equity Ratio (totalDebt / totalStockholderEquity)
    - [ ] Current Ratio (currentAssets / currentLiabilities)
  - [ ] 계산 로직 단순화 및 성능 개선
  - [ ] 에러 처리 강화

#### ☐ 6. 성장 지표 계산
- **라인**: 38
- **메서드**: `calculateGrowthMetrics(ticker:) -> YFGrowthMetrics`
- **설명**: 매출 성장률, 이익 성장률 등 성장 지표 계산
- **yfinance 참조**: 
  - **파일**: `yfinance-reference/yfinance/base.py:391`
  - **메서드**: `get_growth_estimates(as_dict=False)`
  - **데이터 구조**: Index: 0q +1q 0y +1y +5y -5y, Columns: stock industry sector index
  - **내부 소스**: `self._analysis.growth_estimates`
  - **계산 방식**: 기간별 성장률 추정치 (분기/연간)
- **TDD 구현 단계**:
  
  **🔴 Red (테스트 작성)**:
  - [ ] `testCalculateGrowthMetricsValidSymbol()` - AAPL 성장 지표 계산 테스트
  - [ ] `testGrowthMetricsTimeframeStructure()` - 0q/+1q/0y/+1y/+5y 구조 테스트
  - [ ] `testGrowthRateCalculations()` - 개별 성장률 계산 정확성 테스트
  - [ ] `testGrowthMetricsOutlierHandling()` - 이상치 처리 테스트
  
  **🟢 Green (최소 구현)**:
  - [ ] YFGrowthMetrics 모델 설계 (0q, +1q, 0y, +1y, +5y 구조)
  - [ ] 기본 성장률 계산 알고리즘 (기존 재무 데이터 기반)
  - [ ] 시계열 비교 로직 (연도별/분기별)
  
  **🟡 Refactor (코드 정리)**:
  - [ ] 성장률 계산 최적화:
    - [ ] Revenue Growth Rate (연도별/분기별)
    - [ ] Earnings Growth Rate
    - [ ] EPS Growth Rate  
    - [ ] Free Cash Flow Growth
  - [ ] `_analysis` 패턴 활용 개선
  - [ ] 이상치 처리 및 검증 강화
  - [ ] 캐싱 및 성능 최적화

#### ☐ 7. 재무 건전성 평가
- **라인**: 47
- **메서드**: `assessFinancialHealth(ticker:) -> YFFinancialHealth`
- **설명**: 재무 안정성과 건전성을 종합 평가
- **yfinance 참조**: 
  - **파일**: 직접 API 없음, 기존 재무 데이터 조합 계산
  - **데이터 소스**: `get_balance_sheet()`, `get_income_stmt()`, `get_cash_flow()`
  - **계산 베이스**: 대차대조표 + 손익계산서 + 현금흐름표 조합
  - **패턴**: 재무 비율들의 종합 분석 및 점수화
- **TDD 구현 단계**:
  
  **🔴 Red (테스트 작성)**:
  - [ ] `testAssessFinancialHealthValidSymbol()` - AAPL 재무 건전성 평가 테스트
  - [ ] `testFinancialHealthScoring()` - 점수화/등급화 시스템 테스트
  - [ ] `testFinancialHealthRatios()` - 개별 건전성 지표 계산 테스트
  - [ ] `testFinancialHealthRiskAssessment()` - 위험도 평가 로직 테스트
  
  **🟢 Green (최소 구현)**:
  - [ ] YFFinancialHealth 모델 설계 (점수, 등급, 세부 지표)
  - [ ] 기본 건전성 평가 알고리즘 (재무 비율 조합)
  - [ ] 점수화 시스템 (0-100 또는 A-F 등급)
  
  **🟡 Refactor (코드 정리)**:
  - [ ] 건전성 지표 계산 최적화:
    - [ ] Debt-to-Equity 분석 (totalDebt / totalStockholderEquity)
    - [ ] Interest Coverage Ratio (operatingIncome / interestExpense)
    - [ ] Quick Ratio ((currentAssets - inventory) / currentLiabilities)
    - [ ] Working Capital 분석 (currentAssets - currentLiabilities)
  - [ ] 위험도 평가 로직 개선 (복합 지표 기반)
  - [ ] 알고리즘 가중치 조정 및 최적화

#### ☐ 8. 산업 비교 분석
- **라인**: 56
- **메서드**: `compareToIndustry(ticker:) -> YFIndustryComparison`
- **설명**: 동일 산업 내 다른 기업들과의 비교 분석
- **yfinance 참조**: 
  - **파일**: `yfinance-reference/yfinance/base.py:391` (growth_estimates)
  - **데이터 구조**: Columns: stock, industry, sector, index (line 394)
  - **산업 데이터**: `industry` 컬럼에서 산업 평균 제공
  - **비교 기준**: stock vs industry vs sector vs index
  - **활용 패턴**: 성장 추정치에서 산업/섹터 비교 데이터 추출
- **TDD 구현 단계**:
  
  **🔴 Red (테스트 작성)**:
  - [ ] `testCompareToIndustryValidSymbol()` - AAPL 산업 비교 분석 테스트
  - [ ] `testIndustryComparisonStructure()` - stock/industry/sector 구조 테스트
  - [ ] `testIndustryClassificationLogic()` - 산업 분류 체계 테스트
  - [ ] `testIndustryBenchmarking()` - 벤치마킹 지표 계산 테스트
  
  **🟢 Green (최소 구현)**:
  - [ ] YFIndustryComparison 모델 설계 (stock vs industry vs sector)
  - [ ] 기본 산업 분류 체계 (growth_estimates 기반)
  - [ ] 기본 벤치마킹 계산
  
  **🟡 Refactor (코드 정리)**:
  - [ ] 산업 비교 지표 최적화:
    - [ ] 산업 평균 P/E (industry 컬럼 데이터 활용)
    - [ ] 산업 평균 성장률 (growth_estimates industry 값)
    - [ ] 섹터 비교 분석 (sector 컬럼 데이터)
  - [ ] 동일 산업 기업 식별 로직 개선
  - [ ] 비교 결과 데이터 구조 최적화 (상대적 위치 표시)
  - [ ] 성능 및 정확도 개선

---

## 🛠️ 구현 우선순위 권장사항

### Phase A: 고우선순위 (기본 기능 확장)
1. **옵션 만기일 목록 조회** (#3) - 다른 옵션 기능의 기반
2. **재무 비율 계산** (#5) - 기존 데이터 활용 가능
3. **분기별 재무제표 조회** (#4) - 기존 API 패턴 확장

### Phase B: 중우선순위 (분석 기능)
4. **성장 지표 계산** (#6) - 재무 비율 기반으로 구현
5. **재무 건전성 평가** (#7) - 종합 분석 기능

### Phase C: 저우선순위 (고급 기능)
6. **옵션 체인 조회** (#1, #2) - 복잡한 외부 API 의존성
7. **산업 비교 분석** (#8) - 외부 데이터 소스 필요

---

## 📋 TDD & Tidy First 구현 가이드라인

### TDD 원칙 (Red → Green → Refactor)
각 TODO 항목은 반드시 다음 사이클을 따라야 합니다:

#### 🔴 Red: 실패하는 테스트 작성
- [ ] **테스트 우선 작성**: 기능 구현 전에 실패하는 테스트 작성
- [ ] **Swift Testing 프레임워크** 사용 (`@Test`, `#expect`)
- [ ] **명확한 테스트명**: `test[기능명][조건]` 형식 (예: `testFetchOptionsChainValidSymbol`)
- [ ] **실제 API 데이터** 활용 (Mock 사용 금지)
- [ ] **에러 케이스 테스트** 포함 (`#expect(throws:)`)

#### 🟢 Green: 최소한의 코드로 테스트 통과
- [ ] **최소 구현**: 테스트를 통과시키는 가장 간단한 코드
- [ ] **기존 패턴 활용**: YFClient 확장, YFSession 활용
- [ ] **에러 처리**: 적절한 YFError 타입 사용
- [ ] **타입 안전성**: Swift 6.1 기능 활용

#### 🟡 Refactor: 코드 정리 및 개선
- [ ] **구조 개선**: 중복 제거, 명확한 이름, 단일 책임
- [ ] **파일 크기 관리**: 250줄 초과 시 분리 검토
- [ ] **DocC 문서화**: 공개 API에 완전한 문서 주석
- [ ] **성능 최적화**: 필요시 캐싱, 동시성 개선

### Tidy First 원칙 (구조 변경과 기능 변경 분리)

#### 커밋 규칙
- **[Tidy]**: 구조 변경만 (리팩토링, 파일 분리, 이름 변경)
- **[Test]**: 테스트 추가 또는 수정
- **[Feature]**: 새로운 기능 구현
- **[Fix]**: 버그 수정

#### 작업 순서
1. **구조 정리** ([Tidy] 커밋) - 기존 코드가 지저분하면 먼저 정리
2. **테스트 작성** ([Test] 커밋) - 실패하는 테스트 작성
3. **기능 구현** ([Feature] 커밋) - 테스트를 통과시키는 구현
4. **재정리** ([Tidy] 커밋) - 필요시 추가 구조 개선

### 아키텍처 일관성
- [ ] **관심사 분리**: 모델 = 순수 데이터, 클라이언트 = API 로직
- [ ] **의존성 단방향**: 모델 → 클라이언트 → 세션
- [ ] **프로토콜 지향**: 테스트 가능한 설계
- [ ] **에러 처리 일관성**: YFError 타입 통일

### 파일 크기 및 복잡도 관리
- [ ] **250줄 기준**: 초과 시 분리 검토
- [ ] **300줄 강제**: 반드시 분리
- [ ] **테스트 파일**: 15개 메서드 초과 시 분리
- [ ] **확장 패턴**: API별 확장 파일 활용

### 테스트 요구사항
- [ ] **단위 테스트**: 각 메서드별 독립 테스트
- [ ] **통합 테스트**: 실제 API 연동 검증
- [ ] **에러 처리 테스트**: 모든 예외 상황 커버
- [ ] **성능 테스트**: 응답 시간 및 메모리 사용량

---

## 📈 TDD 구현 완료 체크리스트

각 TODO 완료 시 다음 TDD & Tidy First 원칙을 확인하세요:

### 🔴 Red Phase 완료 확인
- [ ] **실패하는 테스트 작성 완료**: 모든 테스트가 초기에 실패함을 확인
- [ ] **테스트 명명 규칙**: `test[기능명][조건]` 형식 준수
- [ ] **Swift Testing 사용**: `@Test`, `#expect`, `#expect(throws:)` 활용
- [ ] **실제 API 데이터**: Mock 사용 금지, 실제 Yahoo Finance API 활용

### 🟢 Green Phase 완료 확인  
- [ ] **최소 구현**: 테스트를 통과시키는 가장 간단한 코드 작성
- [ ] **모든 테스트 통과**: 새로 작성된 테스트와 기존 테스트 모두 통과
- [ ] **기존 패턴 활용**: YFClient 확장, YFSession 활용, YFError 일관성
- [ ] **컴파일 에러 없음**: Swift 6.1 호환성 확인

### 🟡 Refactor Phase 완료 확인
- [ ] **코드 품질 개선**: 중복 제거, 명확한 이름, 단일 책임 원칙
- [ ] **파일 크기 관리**: 250줄 초과 시 분리, 300줄 강제 분리
- [ ] **DocC 문서화**: 모든 공개 API에 완전한 문서 주석
- [ ] **성능 최적화**: 필요시 캐싱, 동시성 개선

### Tidy First 커밋 확인
- [ ] **[Tidy] 커밋**: 구조 변경만 포함, 기능 변경 없음
- [ ] **[Test] 커밋**: 테스트 추가/수정만 포함
- [ ] **[Feature] 커밋**: 새로운 기능 구현만 포함
- [ ] **커밋 분리**: 구조 변경과 기능 변경 절대 혼합 금지

### 최종 검증
- [ ] **전체 테스트 스위트 통과**: 254개 기존 테스트 + 새 테스트 모두 통과
- [ ] **빌드 성공**: Warning 없는 깨끗한 빌드
- [ ] **문서 업데이트**: plan.md 및 관련 문서 업데이트
- [ ] **코드 리뷰**: 팀 리뷰 또는 셀프 리뷰 완료

---

## 📞 참고 자료

### yfinance-reference 핵심 파일들
- **Options API**: `yfinance-reference/yfinance/ticker.py` (lines 46-112, 309-312)
- **Advanced Financials**: `yfinance-reference/yfinance/base.py` (lines 391-500)
- **Fundamentals API**: `yfinance-reference/yfinance/scrapers/fundamentals.py` (line 127)
- **Quarterly Data**: `yfinance-reference/yfinance/ticker.py` (lines 229-258)

### 개발 가이드라인
- **개발 원칙**: `docs/development-principles.md`
- **TDD 가이드라인**: plan.md의 workflow 섹션
- **기존 API 패턴**: `Sources/SwiftYFinance/Core/YF*API.swift` 파일들

### Yahoo Finance API 엔드포인트
- **Options**: `/v7/finance/options/{symbol}?date={timestamp}`
- **Fundamentals**: `/ws/fundamentals-timeseries/v1/finance/timeseries/{symbol}`
- **Growth Data**: Analysis 모듈 활용 (기존 데이터 기반 계산)

---

*마지막 업데이트: 2025-08-17*  
*현재 프로젝트 상태: Phase 1-9 완료, 254개 테스트 통과*