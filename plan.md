# SwiftYFinance 포팅 계획

## 프로젝트 개요
Python yfinance 라이브러리를 Swift로 TDD 방식으로 포팅

## 프로젝트 구조
```
Sources/SwiftYFinance/
├── SwiftYFinance.swift     # 메인 패키지 파일
├── Models/                  # 데이터 모델
│   ├── YFError.swift       # 에러 타입 정의
│   ├── YFFinancials.swift  # 재무제표 모델 (Balance Sheet, Cash Flow, Earnings 포함)
│   ├── YFHistoricalData.swift # 히스토리 데이터 모델
│   ├── YFPrice.swift       # 가격 데이터 모델
│   ├── YFQuote.swift       # 실시간 시세 모델
│   └── YFTicker.swift      # 주식 심볼 모델
└── Core/                    # 핵심 로직
    ├── YFClient.swift      # 메인 API 클라이언트
    ├── YFRequestBuilder.swift # HTTP 요청 빌더
    ├── YFResponseParser.swift # JSON 응답 파서
    └── YFSession.swift     # 네트워크 세션 관리
```

## 작업 원칙
- ✅ TDD (Red → Green → Refactor)
- ✅ Tidy First (구조 변경과 동작 변경 분리)
- ✅ 한 번에 하나의 테스트만 작업
- ✅ 테스트 통과를 위한 최소 코드만 구현
- ✅ 각 단계(체크 리스트 1) 완료시 plan.md 업데이트 후 git commit 실행
- ✅ **참조 기반 학습**: 각 테스트 작성 전 yfinance-reference/ 폴더의 Python 코드 참조
- ✅ **실제 데이터 구조 확인**: Python yfinance로 실제 API 응답 구조 파악 후 Swift 모델 설계

## Phase 1: 기본 구조 설정 ✅ 완료
### 🔄 재검토 체크리스트:
- [x] Swift Package 초기화 재검토
  - 📚 참조: yfinance-reference/setup.py 패키지 구조
  - 🔍 확인사항: Package.swift 의존성, Swift 버전
- [x] 기본 테스트 환경 설정 재검토
  - 📚 참조: yfinance-reference/tests/ 폴더 구조
  - 🔍 확인사항: Swift Testing 프레임워크 설정
- [x] 폴더 구조 재구성 완료 ✅ 2025-08-13
  - Models/ 폴더: 데이터 모델 파일 6개
  - Core/ 폴더: 핵심 로직 파일 4개

## Phase 2: Pure Data Model ✅ 완료
### 🔄 재검토 체크리스트:

#### YFTicker 기본 구조 → YFTickerTests.swift
- [x] testTickerInitWithSymbol 재검토 - 심볼로 Ticker 생성
  - 📚 참조: yfinance-reference/yfinance/ticker.py:Ticker.__init__()
  - 🔍 확인사항: 심볼 검증, 대소문자 처리
- [x] testTickerSymbolValidation 재검토 - 유효하지 않은 심볼 처리
  - 📚 참조: yfinance-reference/yfinance/base.py 심볼 검증 로직
- [x] testTickerDescription 재검토 - Ticker 설명 문자열
  - 📚 참조: yfinance-reference/yfinance/ticker.py:Ticker.__repr__()

#### YFPrice 모델 → YFPriceTests.swift
- [x] testPriceInitWithValues 재검토 - 가격 데이터 초기화
  - 📚 참조: yfinance-reference/yfinance/scrapers/history.py 가격 데이터 구조
  - 🔍 확인사항: Open, High, Low, Close, Volume 필드
- [x] testPriceComparison 재검토 - 가격 비교 연산
  - 📚 참조: pandas DataFrame 비교 연산 참조
- [x] testPriceCodable 재검토 - JSON 인코딩/디코딩
  - 🔍 확인사항: Date 형식, Decimal 정밀도 처리

#### YFHistoricalData 모델 → YFHistoricalDataTests.swift
- [x] testHistoricalDataInit 재검토 - 히스토리 데이터 초기화
  - 📚 참조: yfinance-reference/yfinance/base.py:get_history() 반환 구조
- [x] testHistoricalDataDateRange 재검토 - 날짜 범위 검증
  - 📚 참조: yfinance-reference/tests/test_ticker.py history 관련 테스트
- [x] testHistoricalDataEmpty 재검토 - 빈 데이터 처리
  - 🔍 확인사항: 빈 DataFrame 처리 방식

## Phase 3: Network Layer 🚨 재검토 필요
### 🚨 문제점
- **기본 구조만 구현됨**: URLSession 설정, URL 생성, JSON 파싱 클래스만 존재
- **실제 사용되지 않음**: YFClient에서 전혀 활용하지 않음
- **모킹 데이터만 반환**: 실제 네트워크 호출 없음

### 🔄 재검토 체크리스트:

#### YFSession → YFSessionTests.swift
- [x] testSessionInit 재검토 - 세션 초기화 ✅ 기본 구조만 완료
  - 📚 참조: yfinance-reference/yfinance/base.py:TickerBase.__init__() 세션 설정
  - 🚨 **재작업 필요**: YFClient에서 실제 사용하도록 통합
- [x] testSessionDefaultHeaders 재검토 - 기본 헤더 설정 ✅ 기본 구조만 완료
  - 📚 참조: yfinance-reference/yfinance/shared.py default headers
  - 🚨 **재작업 필요**: 실제 Yahoo Finance 헤더 요구사항 확인
- [x] testSessionProxy 재검토 - 프록시 설정 ✅ 기본 구조만 완료
  - 📚 참조: yfinance-reference/yfinance/data.py proxy 설정

#### YFRequest Builder → YFRequestBuilderTests.swift
- [x] testRequestBuilderBaseURL 재검토 - 기본 URL 생성 ✅ 기본 구조만 완료
  - 📚 참조: yfinance-reference/yfinance/const.py:_BASE_URL_
  - 🚨 **재작업 필요**: 실제 Yahoo Finance 엔드포인트 확인
- [x] testRequestBuilderQueryParams 재검토 - 쿼리 파라미터 추가 ✅ 기본 구조만 완료
  - 📚 참조: yfinance-reference/yfinance/scrapers/*.py 쿼리 파라미터 구성
  - 🚨 **재작업 필요**: 실제 chart API 필수 파라미터 확인
- [x] testRequestBuilderHeaders 재검토 - 헤더 추가 ✅ 기본 구조만 완료
  - 📚 참조: yfinance-reference/yfinance/shared.py headers 설정

#### YFResponse Parser → YFResponseParserTests.swift
- [x] testResponseParserValidJSON 재검토 - 유효한 JSON 파싱 ✅ 기본 구조만 완료
  - 📚 참조: yfinance-reference/yfinance/scrapers/fundamentals.py JSON 파싱
  - 🚨 **재작업 필요**: 실제 Yahoo chart JSON 구조 파싱
- [x] testResponseParserInvalidJSON 재검토 - 잘못된 JSON 처리 ✅ 기본 구조만 완료
  - 📚 참조: yfinance-reference/yfinance/exceptions.py 에러 처리
- [x] testResponseParserErrorHandling 재검토 - 에러 응답 처리 ✅ 기본 구조만 완료
  - 🔍 확인사항: HTTP 상태 코드, 타임아웃 처리

### 🎯 **Phase 3 완성을 위한 추가 작업**:
Phase 4.1에서 실제 API 구현하면서 Phase 3의 **재작업 필요** 항목들도 함께 완성됩니다.

## Phase 4: API Integration (현재 작업 중) 🔄
### ✅ 완료된 작업 재검토 체크리스트:

#### Price History → YFClientTests.swift
- [x] testFetchPriceHistory1Day 재검토 - 1일 데이터 조회
  - 📚 참조: yfinance-reference/yfinance/base.py:get_history() period='1d'
  - 🔍 확인사항: period 파라미터, interval 설정
- [x] testFetchPriceHistory1Week 재검토 - 1주 데이터 조회
  - 📚 참조: yfinance-reference/tests/test_ticker.py history 테스트들
- [x] testFetchPriceHistoryCustomRange 재검토 - 사용자 지정 범위
  - 📚 참조: yfinance-reference/yfinance/base.py start/end date 처리
- [x] testFetchPriceHistoryInvalidSymbol 재검토 - 잘못된 심볼 처리
  - 📚 참조: yfinance-reference/yfinance/exceptions.py:YFInvalidSymbolError
- [x] testFetchPriceHistoryEmptyResult 재검토 - 빈 결과 처리
  - 🔍 확인사항: 빈 DataFrame 반환 시 처리

#### Quote Data → YFClientTests.swift
- [x] testFetchQuoteBasic 재검토 - 기본 시세 조회
  - 📚 참조: yfinance-reference/yfinance/scrapers/quote.py
  - 🔍 확인사항: regularMarketPrice, volume, marketCap 필드
- [x] testFetchQuoteRealtime 재검토 - 실시간 시세 조회
  - 📚 참조: yfinance-reference/yfinance/base.py:get_info() 실시간 데이터
- [x] testFetchQuoteAfterHours 재검토 - 시간외 거래 데이터
  - 🔍 확인사항: preMarketPrice, postMarketPrice 필드

#### Fundamental Data → YFClientTests.swift (완료된 부분)
- [x] testFetchFinancials 재검토 - 재무제표 조회
  - 📚 참조: yfinance-reference/yfinance/base.py:get_financials()
  - 🔍 확인사항: annualReports, totalRevenue, netIncome 필드
- [x] testFetchBalanceSheet 재검토 - 대차대조표 조회
  - 📚 참조: yfinance-reference/yfinance/base.py:get_balance_sheet()
  - 🔍 확인사항: totalAssets, totalLiabilities, stockholderEquity

#### Fundamental Data → YFClientTests.swift (완료된 부분)
- [x] testFetchCashFlow 재검토 - 현금흐름표 조회 ✅ 새로 구현 완료
  - 📚 참조: yfinance-reference/tests/test_ticker.py:test_cash_flow()
  - 📊 데이터 구조: yfinance-reference/yfinance/const.py:'cash-flow' 키
  - 🔍 확인사항: Operating Cash Flow, Net PPE Purchase And Sale, Free Cash Flow 등
  - 🆕 **새로운 모델**: YFCashFlow, YFCashFlowReport (DoCC 주석 포함, Codable 지원)

#### Fundamental Data → YFClientTests.swift (완료된 부분)
- [x] testFetchEarnings 재검토 - 실적 데이터 조회 ✅ 새로 구현 완료
  - 📚 참조: yfinance-reference/tests/test_ticker.py:test_earnings*()
  - 📊 데이터 구조: earnings, quarterly_earnings, earnings_estimate 프로퍼티
  - 🆕 **새로운 모델**: YFEarnings, YFEarningsReport, YFEarningsEstimate (DoCC 주석 포함, Codable 지원)

### 🚧 Phase 4 확장: 고해상도 데이터 & 애널리스트 분석

#### High-Resolution Data → YFClientTests.swift
- [x] testFetchHistoryWithInterval1Min - 1분 간격 데이터 조회 ✅ 완료
  - 📚 참조: yfinance-reference/yfinance/scrapers/history.py interval 처리
  - 🔍 확인사항: interval='1m', period='1d' 조합 지원
- [x] testFetchHistoryWithInterval5Min - 5분 간격 데이터 조회 ✅ 완료
  - 📚 참조: yfinance-reference/tests/test_ticker.py interval 테스트
- [ ] testFetchHistoryWithInterval1Hour - 1시간 간격 데이터 조회
  - 🔍 확인사항: 고해상도 데이터 용량 제한 처리
- [ ] testFetchHistoryIntervalValidation - interval 유효성 검증
  - 📚 참조: yfinance-reference/yfinance/const.py:_VALID_INTERVALS_

#### Analyst Analysis Data → YFClientTests.swift
- [ ] testFetchEarningsEstimate - 실적 전망 조회
  - 📚 참조: yfinance-reference/yfinance/scrapers/analysis.py:earnings_estimate
  - 📊 데이터 구조: earningsTrend 모듈의 earningsEstimate 섹션
  - 🆕 **새로운 모델**: YFEarningsEstimateData (DoCC 주석 포함, Codable 지원)
- [ ] testFetchRevenueEstimate - 매출 전망 조회
  - 📚 참조: yfinance-reference/yfinance/scrapers/analysis.py:revenue_estimate
  - 🆕 **새로운 모델**: YFRevenueEstimateData
- [ ] testFetchEPSTrend - EPS 추이 조회
  - 📚 참조: yfinance-reference/yfinance/scrapers/analysis.py:eps_trend
  - 🆕 **새로운 모델**: YFEPSTrendData
- [ ] testFetchEPSRevisions - EPS 수정 조회
  - 📚 참조: yfinance-reference/yfinance/scrapers/analysis.py:eps_revisions
  - 🆕 **새로운 모델**: YFEPSRevisionsData
- [ ] testFetchAnalystPriceTargets - 애널리스트 목표주가 조회
  - 📚 참조: yfinance-reference/yfinance/scrapers/analysis.py:analyst_price_targets
  - 📊 데이터 구조: financialData 모듈의 target* 필드들
  - 🆕 **새로운 모델**: YFAnalystPriceTargets
- [ ] testFetchEarningsHistory - 실적 이력 조회
  - 📚 참조: yfinance-reference/yfinance/scrapers/analysis.py:earnings_history
  - 🆕 **새로운 모델**: YFEarningsHistoryData
- [ ] testFetchGrowthEstimates - 성장률 전망 조회
  - 📚 참조: yfinance-reference/yfinance/scrapers/analysis.py:growth_estimates
  - 📊 데이터 구조: industryTrend, sectorTrend, indexTrend 비교
  - 🆕 **새로운 모델**: YFGrowthEstimatesData

### 🚧 다음 작업 대기:
Phase 4 확장 완료 후 Phase 5 Advanced Features 진행

## Phase 5: Advanced Features (YFMultipleTickersTests.swift, YFDownloadTests.swift, YFSearchTests.swift)
### Multiple Tickers → YFMultipleTickersTests.swift
- [ ] testMultipleTickersInit - 여러 종목 초기화
  - 📚 참조: yfinance-reference/yfinance/tickers.py:Tickers 클래스
- [ ] testMultipleTickersConcurrent - 동시 요청 처리
  - 📚 참조: yfinance-reference/yfinance/multi.py:download() 함수
- [ ] testMultipleTickersPartialFailure - 부분 실패 처리

### Download Function → YFDownloadTests.swift
- [ ] testDownloadSingleTicker - 단일 종목 다운로드
  - 📚 참조: yfinance-reference/yfinance/__init__.py:download() 함수
- [ ] testDownloadMultipleTickers - 여러 종목 다운로드
- [ ] testDownloadWithInterval - 인터벌 설정 다운로드
- [ ] testDownloadProgressCallback - 진행률 콜백

### Search & Lookup → YFSearchTests.swift
- [ ] testSearchByKeyword - 키워드 검색
  - 📚 참조: yfinance-reference/yfinance/search.py
- [ ] testSearchWithFilters - 필터 적용 검색
- [ ] testLookupBySymbol - 심볼로 조회
  - 📚 참조: yfinance-reference/yfinance/lookup.py
- [ ] testLookupByISIN - ISIN으로 조회

## Phase 6: WebSocket (YFWebSocketTests.swift)
- [ ] testWebSocketConnection - 연결 설정
  - 📚 참조: yfinance-reference/yfinance/live.py
- [ ] testWebSocketSubscribe - 구독 기능
- [ ] testWebSocketUnsubscribe - 구독 해제
- [ ] testWebSocketReconnect - 재연결 처리
- [ ] testWebSocketMessageParsing - 메시지 파싱

## Phase 7: Domain Models (YFSectorTests.swift, YFIndustryTests.swift, YFMarketTests.swift)
### Sector → YFSectorTests.swift
- [ ] testSectorInit - 섹터 초기화
  - 📚 참조: yfinance-reference/yfinance/domain/sector.py
- [ ] testSectorTickersList - 섹터 내 종목 목록
- [ ] testSectorPerformance - 섹터 성과 데이터

### Industry → YFIndustryTests.swift
- [ ] testIndustryInit - 산업 초기화
  - 📚 참조: yfinance-reference/yfinance/domain/industry.py
- [ ] testIndustryTickersList - 산업 내 종목 목록
- [ ] testIndustryComparison - 산업 비교

### Market → YFMarketTests.swift
- [ ] testMarketInit - 시장 초기화
  - 📚 참조: yfinance-reference/yfinance/domain/market.py
- [ ] testMarketSummary - 시장 요약
- [ ] testMarketTrending - 인기 종목

## Phase 8: Screener (YFScreenerTests.swift)
- [ ] testScreenerQueryBuilder - 쿼리 빌더
  - 📚 참조: yfinance-reference/yfinance/screener/query.py
- [ ] testScreenerEquityFilter - 주식 필터
  - 📚 참조: yfinance-reference/yfinance/screener/screener.py
- [ ] testScreenerFundFilter - 펀드 필터
- [ ] testScreenerExecute - 스크리너 실행
- [ ] testScreenerPredefinedQueries - 사전 정의 쿼리

## Phase 9: Utilities (YFCacheTests.swift, YFDateUtilTests.swift, YFErrorHandlingTests.swift)
### Cache → YFCacheTests.swift
- [ ] testCacheStore - 캐시 저장
  - 📚 참조: yfinance-reference/yfinance/cache.py
- [ ] testCacheRetrieve - 캐시 조회
- [ ] testCacheExpiration - 캐시 만료
- [ ] testCacheClear - 캐시 삭제

### Date Utilities → YFDateUtilTests.swift
- [ ] testDateParsing - 날짜 파싱
  - 📚 참조: yfinance-reference/yfinance/utils.py:dateutil 관련 함수들
- [ ] testDateFormatting - 날짜 포매팅
- [ ] testTimezoneHandling - 시간대 처리

### Error Handling → YFErrorHandlingTests.swift
- [ ] testNetworkError - 네트워크 에러
  - 📚 참조: yfinance-reference/yfinance/exceptions.py
- [ ] testParsingError - 파싱 에러
- [ ] testValidationError - 검증 에러
- [ ] testRateLimitError - Rate limit 에러

## Phase 10: Performance & Optimization (YFPerformanceTests.swift)
- [ ] testConcurrentRequests - 동시 요청 성능
  - 📚 참조: yfinance-reference/yfinance/multi.py의 ThreadPoolExecutor 사용
- [ ] testLargeDatasetParsing - 대용량 데이터 파싱
- [ ] testMemoryUsage - 메모리 사용량
- [ ] testCachePerformance - 캐시 성능

## 진행 상태
- 전체 테스트: 36/116 (36개 테스트 모두 통과 ✅)
- 완료된 Phase: 2/10 (Phase 1: 기본 구조, Phase 2: 데이터 모델)
- 현재 작업 중: Phase 4.1 - Network Layer 실제 구현 (모킹 → 실제 API 전환)
- 🚨 **중요**: 모든 기존 테스트는 모킹 데이터 사용 중, 실제 API 구현 필요
- ✅ **폴더 구조 재구성 완료** (2025-08-13): Models/, Core/ 분리

## 다음 작업
🚨 **최우선: 실제 API 구현 전환!**

### 현재 우선순위: Phase 4.1 - Network Layer 실제 구현
1. **YFRequestBuilder 실제 구현** ✅ 완료
   - 📚 **참조 단계**: yfinance-reference/yfinance/const.py:_BASE_URL_ 분석
   - 🔍 **API 구조 확인**: Yahoo Finance chart API 엔드포인트 파악
   - 🛠️ **실제 URL 생성**: query2.finance.yahoo.com 기반 URL 구성
   - ✅ **TDD 구현**: 기존 테스트 유지, 실제 구현으로 교체

### 다음 작업 (최우선):
1. **YFSession 실제 HTTP 요청 구현** (긴급)
   - testSessionRealRequest 작성 및 구현
   - 실제 Yahoo Finance API 호출 테스트
2. **YFResponseParser 실제 JSON 파싱** (긴급)
   - testParseChartResponse 작성 및 구현
   - 실제 Yahoo Finance 응답 파싱
3. **fetchPriceHistory 실제 API 연동** (중요)
   - 모킹 제거, 실제 데이터 반환

## 🚨 중요: 실제 API 구현 전환 계획

### ⚠️ 현재 문제점
- **모든 YFClient 메서드가 모킹 데이터** 사용 중
- 실제 Yahoo Finance API 호출 **전혀 없음**
- 테스트는 통과하지만 **가짜 데이터**만 반환

### 🎯 실제 API 구현 단계별 계획

#### Phase 4.1: Network Layer 실제 구현 (우선순위 1)

##### YFRequestBuilder 실제 구현 → YFRequestBuilderTests.swift
- [x] testRequestBuilderChartURL - Yahoo Finance chart API URL 생성 ✅ 완료
  - 📚 참조: yfinance-reference/yfinance/const.py:_BASE_URL_
  - 🎯 목표: `https://query2.finance.yahoo.com/v8/finance/chart/{symbol}` 구성
- [x] testRequestBuilderWithInterval - interval 파라미터 추가 ✅ 완료
  - 📚 참조: yfinance-reference/yfinance/scrapers/history.py interval 처리
  - 🔍 확인사항: interval=1m, range=1d, includePrePost, events 쿼리 파라미터
- [x] testRequestBuilderWithPeriod - period 파라미터 추가 ✅ 완료
  - 📚 참조: yfinance-reference/yfinance/scrapers/history.py period 처리
  - 🔍 확인사항: range vs period1/period2 방식, 모든 유효 period 테스트
- [x] testRequestBuilderHeaders - 실제 User-Agent 헤더 설정 ✅ 완료
  - 📚 참조: yfinance-reference/yfinance/const.py USER_AGENTS
  - 🎯 구현: Mozilla/Chrome User-Agent로 Yahoo Finance 호환성 확보
  - 🔍 검증: 다양한 헤더 조합 및 브라우저 패턴 테스트

##### YFSession 실제 구현 → YFSessionTests.swift  
- [x] testSessionRealRequest - 실제 HTTP 요청 처리 ✅ 완료
  - 📚 참조: yfinance-reference/yfinance/data.py HTTP 요청
  - 🎯 목표: URLSession으로 실제 네트워크 호출
  - ✅ 구현완료: Yahoo Finance API 호출 성공 (0.434초)
- [x] testSessionErrorHandling - 네트워크 에러 처리 ✅ 완료
  - 📚 참조: yfinance-reference/yfinance/exceptions.py
  - 🔍 확인사항: 타임아웃, 404, 403, 500 등 HTTP 에러
  - ✅ 구현완료: 다양한 에러 상황 처리 테스트 (0.426초)
- [ ] testSessionUserAgent - User-Agent 헤더 설정
  - 📚 참조: yfinance-reference/yfinance/shared.py
  - 🔍 확인사항: Yahoo Finance 호환 User-Agent

##### YFResponseParser 실제 구현 → YFResponseParserTests.swift
- [ ] testParseChartResponse - 실제 Yahoo chart JSON 파싱
  - 📚 참조: yfinance-reference/yfinance/scrapers/history.py 파싱 로직
  - 🎯 목표: 실제 Yahoo JSON → YFPrice 배열 변환
- [ ] testParseTimestamps - Unix timestamp 변환
  - 📚 참조: yfinance-reference/yfinance/scrapers/history.py 시간 처리
  - 🔍 확인사항: timezone 처리, Date 변환
- [ ] testParseOHLCV - OHLCV 데이터 추출
  - 📚 참조: yfinance-reference/yfinance/scrapers/history.py OHLC 처리
  - 🔍 확인사항: open, high, low, close, volume 필드 매핑
- [ ] testParseErrorResponse - Yahoo 에러 응답 처리
  - 📚 참조: yfinance-reference/yfinance/exceptions.py
  - 🔍 확인사항: 잘못된 심볼, API 에러 메시지 파싱

#### Phase 4.2: API 통합 실제 구현 (우선순위 2)

##### fetchPriceHistory 실제 구현 → YFClientTests.swift
- [ ] testFetchPriceHistoryRealAPI - 실제 API 연동으로 전환
  - 📚 참조: yfinance-reference/yfinance/base.py:get_history()
  - 🎯 목표: 모킹 제거, 실제 AAPL 데이터 반환
  - 🔍 확인사항: 기존 테스트 모두 통과 (testFetchPriceHistory1Day 등)
- [ ] testFetchHistoryWithInterval1MinReal - 1분 간격 실제 데이터
  - 📚 참조: yfinance-reference 실제 1분 데이터 응답 구조
  - 🎯 목표: 390개 실제 데이터포인트 반환
- [ ] testFetchHistoryWithInterval5MinReal - 5분 간격 실제 데이터
  - 📚 참조: yfinance-reference 실제 5분 데이터 응답 구조
  - 🎯 목표: 78개 실제 데이터포인트 반환

##### 다른 API들 순차 전환
- [ ] testFetchQuoteRealAPI - fetchQuote 실제 구현
- [ ] testFetchFinancialsRealAPI - fetchFinancials 실제 구현
- [ ] testFetchBalanceSheetRealAPI - fetchBalanceSheet 실제 구현
- [ ] testFetchCashFlowRealAPI - fetchCashFlow 실제 구현
- [ ] testFetchEarningsRealAPI - fetchEarnings 실제 구현

### 🛠️ TDD 접근법
- **기존 테스트 유지**: 테스트 코드는 변경하지 않음
- **구현만 교체**: 모킹 → 실제 API 호출
- **단계별 전환**: 한 번에 하나씩, TDD 사이클 유지

## 작업 절차 (A + B 혼합 방향성)
1. **참조 분석**: yfinance-reference/ 폴더에서 해당 기능의 Python 구현 및 테스트 확인
2. **실제 데이터 확인**: Python yfinance 실행하여 실제 API 응답 구조 파악
3. **Swift 모델 설계**: 파악한 데이터 구조 기반으로 Swift 모델 정의
4. **TDD 구현**: 실패하는 테스트 → **실제 API 구현** → 리팩토링
5. **검증**: 구현된 기능이 Python yfinance와 동일한 결과 반환하는지 확인
