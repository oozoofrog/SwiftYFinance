# SwiftYFinance 포팅 계획

## 프로젝트 개요
Python yfinance 라이브러리를 Swift로 TDD 방식으로 포팅

## 개발 원칙
- ✅ TDD (Red → Green → Refactor)
- ✅ Tidy First (구조 변경과 동작 변경 분리)
- ✅ 한 번에 하나의 테스트만 작업
- ✅ 테스트 통과를 위한 최소 코드만 구현
- ✅ 각 단계 완료시 plan.md 업데이트 후 git commit 실행
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

## Phase 3: Network Layer ✅ 완료
### 🔄 재검토 체크리스트:

#### YFSession → YFSessionTests.swift
- [ ] testSessionInit 재검토 - 세션 초기화
  - 📚 참조: yfinance-reference/yfinance/base.py:TickerBase.__init__() 세션 설정
  - 🔍 확인사항: URLSession 설정, User-Agent 헤더
- [ ] testSessionDefaultHeaders 재검토 - 기본 헤더 설정
  - 📚 참조: yfinance-reference/yfinance/shared.py default headers
- [ ] testSessionProxy 재검토 - 프록시 설정
  - 📚 참조: yfinance-reference/yfinance/data.py proxy 설정

#### YFRequest Builder → YFRequestBuilderTests.swift
- [ ] testRequestBuilderBaseURL 재검토 - 기본 URL 생성
  - 📚 참조: yfinance-reference/yfinance/const.py:_BASE_URL_
  - 🔍 확인사항: query.finance.yahoo.com 기본 URL
- [ ] testRequestBuilderQueryParams 재검토 - 쿼리 파라미터 추가
  - 📚 참조: yfinance-reference/yfinance/scrapers/*.py 쿼리 파라미터 구성
- [ ] testRequestBuilderHeaders 재검토 - 헤더 추가
  - 📚 참조: yfinance-reference/yfinance/shared.py headers 설정

#### YFResponse Parser → YFResponseParserTests.swift
- [ ] testResponseParserValidJSON 재검토 - 유효한 JSON 파싱
  - 📚 참조: yfinance-reference/yfinance/scrapers/fundamentals.py JSON 파싱
- [ ] testResponseParserInvalidJSON 재검토 - 잘못된 JSON 처리
  - 📚 참조: yfinance-reference/yfinance/exceptions.py 에러 처리
- [ ] testResponseParserErrorHandling 재검토 - 에러 응답 처리
  - 🔍 확인사항: HTTP 상태 코드, 타임아웃 처리

## Phase 4: API Integration (현재 작업 중) 🔄
### ✅ 완료된 작업 재검토 체크리스트:

#### Price History → YFClientTests.swift
- [ ] testFetchPriceHistory1Day 재검토 - 1일 데이터 조회
  - 📚 참조: yfinance-reference/yfinance/base.py:get_history() period='1d'
  - 🔍 확인사항: period 파라미터, interval 설정
- [ ] testFetchPriceHistory1Week 재검토 - 1주 데이터 조회
  - 📚 참조: yfinance-reference/tests/test_ticker.py history 테스트들
- [ ] testFetchPriceHistoryCustomRange 재검토 - 사용자 지정 범위
  - 📚 참조: yfinance-reference/yfinance/base.py start/end date 처리
- [ ] testFetchPriceHistoryInvalidSymbol 재검토 - 잘못된 심볼 처리
  - 📚 참조: yfinance-reference/yfinance/exceptions.py:YFInvalidSymbolError
- [ ] testFetchPriceHistoryEmptyResult 재검토 - 빈 결과 처리
  - 🔍 확인사항: 빈 DataFrame 반환 시 처리

#### Quote Data → YFClientTests.swift
- [ ] testFetchQuoteBasic 재검토 - 기본 시세 조회
  - 📚 참조: yfinance-reference/yfinance/scrapers/quote.py
  - 🔍 확인사항: regularMarketPrice, volume, marketCap 필드
- [ ] testFetchQuoteRealtime 재검토 - 실시간 시세 조회
  - 📚 참조: yfinance-reference/yfinance/base.py:get_info() 실시간 데이터
- [ ] testFetchQuoteAfterHours 재검토 - 시간외 거래 데이터
  - 🔍 확인사항: preMarketPrice, postMarketPrice 필드

#### Fundamental Data → YFClientTests.swift (완료된 부분)
- [ ] testFetchFinancials 재검토 - 재무제표 조회
  - 📚 참조: yfinance-reference/yfinance/base.py:get_financials()
  - 🔍 확인사항: annualReports, totalRevenue, netIncome 필드
- [ ] testFetchBalanceSheet 재검토 - 대차대조표 조회
  - 📚 참조: yfinance-reference/yfinance/base.py:get_balance_sheet()
  - 🔍 확인사항: totalAssets, totalLiabilities, stockholderEquity

### 🚧 현재 작업 중인 항목:
- [ ] testFetchCashFlow - 현금흐름표 조회
  - 📚 참조: yfinance-reference/tests/test_ticker.py:test_cash_flow()
  - 📊 데이터 구조: yfinance-reference/yfinance/const.py:'cash-flow' 키
  - 🔍 확인사항: Operating Cash Flow, Net PPE Purchase And Sale, Free Cash Flow 등
- [ ] testFetchEarnings - 실적 데이터 조회
  - 📚 참조: yfinance-reference/tests/test_ticker.py:test_earnings*()
  - 📊 데이터 구조: earnings, quarterly_earnings 프로퍼티

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
- 전체 테스트: 30/88
- 완료된 Phase: 3/10
- 현재 작업 중: Phase 4 - API Integration

## 다음 작업
1. **testFetchCashFlow - 현금흐름표 조회**
   - 📚 **참조 단계**: yfinance-reference/tests/test_ticker.py:test_cash_flow() 분석
   - 🔍 **데이터 구조 확인**: Python yfinance로 실제 cash flow 데이터 구조 파악
   - 🛠️ **Swift 모델 설계**: YFCashFlow 구조체/클래스 정의
   - ✅ **TDD 구현**: Red → Green → Refactor 사이클 진행

## 작업 절차 (A + B 혼합 방향성)
1. **참조 분석**: yfinance-reference/ 폴더에서 해당 기능의 Python 구현 및 테스트 확인
2. **실제 데이터 확인**: Python yfinance 실행하여 실제 API 응답 구조 파악
3. **Swift 모델 설계**: 파악한 데이터 구조 기반으로 Swift 모델 정의
4. **TDD 구현**: 실패하는 테스트 → 최소 구현 → 리팩토링
5. **검증**: 구현된 기능이 Python yfinance와 동일한 결과 반환하는지 확인
