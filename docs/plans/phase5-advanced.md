# Phase 5: Advanced Features

## 🎯 목표
Yahoo Finance의 고급 기능들을 Swift로 구현하여 완전한 금융 데이터 API 라이브러리 완성

## 📋 구현 계획

### 5.1 Options Trading API ✅ 완료 (2025-08-13)
**목표**: 옵션 체인, 만기일, 행사가격 등 옵션 거래 데이터 조회

#### 구현 사항
- [x] YFOptions 모델 생성
- [x] 옵션 체인 조회 API (`fetchOptionsChain`)
- [x] 만기일 목록 조회 (`getExpirationDates`)
- [x] Call/Put 옵션 데이터 파싱
- [x] Greeks (Delta, Gamma, Theta, Vega) 계산

#### 테스트 케이스
- [x] `testFetchOptionsChain` - 기본 옵션 체인 조회
- [x] `testOptionsExpirationDates` - 만기일 목록 확인
- [x] `testOptionsChainWithExpiry` - 특정 만기일 체인 조회
- [x] `testOptionsGreeks` - Greeks 계산 정확성
- [x] `testOptionsInvalidSymbol` - 에러 처리

#### 구현 파일
- `Sources/SwiftYFinance/Models/YFOptions.swift` - 옵션 모델
- `Sources/SwiftYFinance/Core/YFOptionsAPI.swift` - API 구현
- `Tests/SwiftYFinanceTests/Client/OptionsDataTests.swift` - 테스트

#### Python 참조 구현 (실제 확인됨)
- `yfinance-reference/yfinance/ticker.py:46-109` - option_chain() 메서드
- `yfinance-reference/yfinance/const.py:2` - _BASE_URL_ 정의  
- API 엔드포인트: `https://query2.finance.yahoo.com/v7/finance/options/{ticker}`
- 데이터 필드: contractSymbol, strike, lastPrice, bid, ask, volume, openInterest, impliedVolatility

### 5.2 Fundamentals API (상세) ✅ 완료 (2025-08-13)
**목표**: 기존 재무제표 API 확장 - 분기별 데이터, 비율 분석 등

#### 구현 사항
- [x] 분기별 재무제표 조회 (`fetchQuarterlyFinancials`)
- [x] 재무 비율 계산 (P/E, P/B, ROE, ROA 등) (`calculateFinancialRatios`)
- [x] 성장률 계산 (YoY, QoQ) (`calculateGrowthMetrics`)
- [x] 산업 평균 대비 비교 (`compareToIndustry`)
- [x] 재무 건전성 지표 (`assessFinancialHealth`)

#### 테스트 케이스
- [x] `testFetchQuarterlyFinancials` - 분기별 데이터
- [x] `testFinancialRatios` - 비율 계산
- [x] `testGrowthMetrics` - 성장 지표
- [x] `testFinancialHealthMetrics` - 재무 건전성
- [x] `testIndustryComparison` - 산업 비교
- [x] `testAdvancedFinancialsInvalidSymbol` - 에러 처리
- [x] `testFinancialDataConsistency` - 데이터 일관성

#### 구현 파일
- `Sources/SwiftYFinance/Models/YFFinancialsAdvanced.swift` - 고급 재무 모델
- `Sources/SwiftYFinance/Core/YFFinancialsAdvancedAPI.swift` - API 구현
- `Tests/SwiftYFinanceTests/Client/FundamentalsAdvancedTests.swift` - 테스트

#### Python 참조 구현 (실제 확인됨)
- `yfinance-reference/yfinance/scrapers/fundamentals.py:127` - fundamentals-timeseries API
- API 엔드포인트: `https://query2.finance.yahoo.com/ws/fundamentals-timeseries/v1/finance/timeseries/{symbol}`
- 데이터 필드: income, balance-sheet, cash-flow (yearly/quarterly/trailing)

### 5.3 Screening API ✅ 완료 (2025-08-13)
**목표**: 조건에 맞는 종목 검색 및 필터링

#### 구현 사항
- [x] YFScreener 빌더 클래스 생성
- [x] 필터 조건 시스템 (시가총액, 가격, 재무비율 등)
- [x] 정렬 옵션 (시가총액, 거래량, 수익률 등)
- [x] 섹터/산업별 필터링
- [x] 커스텀 조건 조합 (Fluent API)
- [x] 사전 정의된 스크리너 (Day Gainers, Losers 등)
- [x] 페이지네이션 지원

#### 테스트 케이스
- [x] `testBasicScreening` - 기본 스크리닝 (시가총액, 지역, 가격)
- [x] `testScreeningWithSorting` - 정렬 기능
- [x] `testSectorFiltering` - 섹터별 필터
- [x] `testFinancialRatiosFiltering` - 재무 비율 필터 (P/E, ROE)
- [x] `testPredefinedScreeners` - 사전 정의된 스크리너
- [x] `testComplexQuery` - 복합 조건 조합
- [x] `testScreeningPagination` - 페이지네이션
- [x] `testInvalidScreenerError` - 에러 처리

#### 구현 파일
- `Sources/SwiftYFinance/Models/YFScreener.swift` - 스크리너 빌더 및 모델
- `Sources/SwiftYFinance/Core/YFScreeningAPI.swift` - API 구현
- `Tests/SwiftYFinanceTests/Client/ScreeningTests.swift` - 테스트

#### Python 참조 구현 (실제 확인됨)
- `yfinance-reference/yfinance/screener/screener.py:54` - screen() 메인 함수
- `yfinance-reference/yfinance/screener/query.py` - QueryBase 클래스
- API 엔드포인트: `https://query1.finance.yahoo.com/v1/finance/screener`
- 사전 정의 엔드포인트: `https://query1.finance.yahoo.com/v1/finance/screener/predefined/saved`

### 5.4 News API ✅ 완료 (2025-08-13)
**목표**: 종목 관련 뉴스 및 분석 리포트 통합

#### 구현 사항
- [x] YFNews 모델 생성 (뉴스 기사, 감성 분석, 이미지 정보)
- [x] 뉴스 피드 조회 (`fetchNews`)
- [x] 뉴스 카테고리 분류 (속보, 실적, 분석, 보도자료 등)
- [x] 감성 분석 (긍정/부정/중립, 점수, 신뢰도)
- [x] 관련 종목 연결
- [x] 날짜 범위 필터링
- [x] 다중 종목 뉴스 조회
- [x] 이미지 및 메타데이터 지원

#### 테스트 케이스
- [x] `testFetchBasicNews` - 기본 뉴스 조회
- [x] `testFetchNewsWithLimit` - 개수 제한 조회
- [x] `testFetchNewsByCategory` - 카테고리별 조회
- [x] `testNewsSentimentAnalysis` - 감성 분석
- [x] `testRelatedStocksInNews` - 관련 종목
- [x] `testNewsFiltering` - 날짜 범위 필터링
- [x] `testNewsCategories` - 카테고리 분류
- [x] `testInvalidTickerNews` - 에러 처리
- [x] `testNewsImageHandling` - 이미지 처리

#### 구현 파일
- `Sources/SwiftYFinance/Models/YFNews.swift` - 뉴스 모델 및 감성 분석
- `Sources/SwiftYFinance/Core/YFNewsAPI.swift` - API 구현
- `Tests/SwiftYFinanceTests/Client/NewsTests.swift` - 테스트

#### Python 참조 구현 (실제 확인됨)
- `yfinance-reference/yfinance/base.py:663` - get_news() 메서드
- API 엔드포인트: `https://finance.yahoo.com/xhr/ncp?queryRef={queryRef}&serviceKey=ncp_fin`
- 쿼리 참조: newsAll, latestNews, pressRelease
- 데이터 필드: title, summary, link, publishedDate, source, category

### 5.5 Technical Indicators
**목표**: 기술적 분석 지표 계산

#### 구현 사항
- [ ] 이동평균 (SMA, EMA)
- [ ] RSI (Relative Strength Index)
- [ ] MACD (Moving Average Convergence Divergence)
- [ ] 볼린저 밴드
- [ ] 스토캐스틱

#### 테스트 케이스
- [ ] `testMovingAverages` - 이동평균 계산
- [ ] `testRSICalculation` - RSI 정확성
- [ ] `testMACDSignals` - MACD 신호
- [ ] `testBollingerBands` - 밴드 계산

## 🛠 구현 우선순위

1. **Phase 5.1**: Options Trading API (가장 수요 높음)
2. **Phase 5.2**: Fundamentals API 확장
3. **Phase 5.3**: Screening API
4. **Phase 5.4**: News API
5. **Phase 5.5**: Technical Indicators

## 📊 성공 지표

- 각 API별 테스트 커버리지 95% 이상
- Python yfinance와 동일한 데이터 반환
- 응답 시간 2초 이내
- 에러 처리 및 재시도 로직 완비

## 🔄 구현 방법론

### TDD 원칙 준수
1. **Red**: 실패하는 테스트 작성
2. **Green**: 최소 코드로 테스트 통과
3. **Refactor**: 코드 품질 개선

### 참조 구현 분석

#### Python yfinance 참조 파일
```bash
# Phase 5.1 - Options Trading API
yfinance-reference/yfinance/ticker.py
- option_chain() 메서드: 옵션 체인 조회 로직
- options 속성: 만기일 목록

yfinance-reference/yfinance/scrapers/options.py  
- OptionChain 클래스: 옵션 데이터 파싱
- _download_options(): API 호출 및 응답 처리
- _process_options(): 데이터 정규화

# Phase 5.2 - Fundamentals API
yfinance-reference/yfinance/scrapers/fundamentals.py
- get_financials(): 재무제표 상세 조회
- get_balance_sheet(): 대차대조표
- get_cash_flow(): 현금흐름표
- get_income_stmt(): 손익계산서

# Phase 5.3 - Screening API  
yfinance-reference/yfinance/screener/screener.py
- Screener 클래스: 스크리닝 로직
- get_screeners(): 사전 정의 스크리너
- _fetch_and_parse(): 결과 파싱

# Phase 5.4 - News API
yfinance-reference/yfinance/ticker.py
- news 속성: 뉴스 조회
yfinance-reference/yfinance/scrapers/news.py
- get_news(): 뉴스 데이터 파싱

# Phase 5.5 - Technical Indicators
yfinance-reference/yfinance/scrapers/analysis.py
- get_analysis(): 기술적 분석 데이터
- get_recommendations(): 애널리스트 추천
```

#### 주요 참조 포인트
1. **API 엔드포인트**: `base.py`의 `_BASE_URL_` 상수들
2. **데이터 구조**: 각 scraper 클래스의 `_parse_json()` 메서드
3. **에러 처리**: `utils.py`의 예외 처리 패턴
4. **Rate Limiting**: `data.py`의 재시도 로직

## 📅 예상 일정

- Phase 5.1: 2일 (Options API)
- Phase 5.2: 1일 (Fundamentals 확장)
- Phase 5.3: 2일 (Screening)
- Phase 5.4: 1일 (News)
- Phase 5.5: 2일 (Technical Indicators)

**총 예상 기간**: 8일

## ⚠️ 주의사항

1. **API Rate Limiting**: Yahoo Finance 제한 준수
2. **데이터 정확성**: Python yfinance와 교차 검증
3. **성능 최적화**: 대량 데이터 처리시 메모리 관리
4. **에러 처리**: 네트워크 오류, 데이터 없음 등 처리

---

**📅 Created**: 2025-08-13
**🔄 Status**: Ready to Start
**✅ Next Step**: Phase 5.1 Options Trading API 구현 시작