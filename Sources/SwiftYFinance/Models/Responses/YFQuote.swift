import Foundation

// MARK: - Yahoo Finance Quote Models

/**
 # Yahoo Finance Quote API Models
 
 Yahoo Finance quoteSummary API의 실시간 주식 시세 데이터를 나타내는 모델 집합입니다.
 
 ## 개요
 
 이 파일은 Yahoo Finance의 quoteSummary API 응답을 파싱하기 위한 Swift 구조체들을 정의합니다.
 모든 필드는 Yahoo Finance API의 원본 응답과 1:1 매칭되며, 데이터 변환이나 필터링 없이 
 직접 노출됩니다.
 
 ## 주요 특징
 
 - **완전한 API 호환성**: Yahoo Finance API의 모든 필드를 그대로 노출
 - **Optional 처리**: API 응답에서 누락될 수 있는 필드들을 안전하게 처리
 - **Sendable 준수**: 멀티스레딩 환경에서 안전한 데이터 전송 보장
 - **타입 안전성**: Swift의 강타입 시스템을 활용한 안전한 데이터 접근
 
 ## 사용 예제
 
 ```swift
 let client = YFClient()
 let ticker = YFTicker(symbol: "AAPL")
 
 do {
     let quote = try await client.quote.fetch(ticker: ticker)
     
     // 기본 가격 정보 접근
     if let price = quote.regularMarketPrice {
         print("현재가: $\(price)")
     }
     
     // 회사 정보 접근
     if let companyName = quote.longName {
         print("회사명: \(companyName)")
     }
     
     // 시장 상태 확인
     if let marketState = quote.marketState {
         print("시장 상태: \(marketState)")
     }
 } catch {
     print("시세 조회 실패: \(error)")
 }
 ```
 
 ## 관련 타입
 
 - ``YFTicker``: 종목 식별을 위한 심볼 래퍼
 - ``YFQuoteService``: Quote API 호출을 위한 서비스 클래스
 - ``YFClient``: Yahoo Finance API 클라이언트의 진입점
 
 ## 주의사항
 
 - 모든 필드가 Optional이므로 사용 전 nil 체크 필수
 - Unix timestamp 필드들은 수동으로 Date로 변환 필요
 - 실시간 데이터이므로 값이 빠르게 변경될 수 있음
 - 시간외 거래 데이터는 `preMarket*`, `postMarket*` 필드에서 확인 가능
 */

/**
 Yahoo Finance quoteSummary API의 최상위 응답 구조체입니다.
 
 ## 개요
 
 Yahoo Finance의 quoteSummary API는 주식 시세 및 상세 정보를 JSON 형태로 반환합니다.
 이 구조체는 해당 JSON 응답의 최상위 래퍼 역할을 수행합니다.
 
 ## 구조
 
 ```json
 {
     "quoteSummary": {
         "result": [...],
         "error": null
     }
 }
 ```
 
 ## 사용법
 
 일반적으로 직접 사용하지 않고, ``YFQuoteService``를 통해 간접적으로 사용됩니다:
 
 ```swift
 // 내부적으로 YFQuoteResponse가 사용됨
 let quote = try await client.quote.fetch(ticker: ticker)
 ```
 
 - Note: 이 구조체는 Yahoo Finance API의 응답 형식 변경에 대비한 안정적인 파싱을 제공합니다.
 */
public struct YFQuoteResponse: Decodable, Sendable {
    
    /// quoteSummary API의 메인 데이터 컨테이너
    ///
    /// Yahoo Finance API 응답에서 실제 시세 데이터가 포함된 부분입니다.
    /// API 에러나 네트워크 문제로 인해 nil일 수 있습니다.
    ///
    /// - Important: nil 체크를 통해 안전하게 접근해야 합니다.
    public let quoteSummary: YFQuoteSummary?
}

/**
 quoteSummary API 응답의 데이터 및 에러 정보를 포함하는 래퍼 구조체입니다.
 
 ## 개요
 
 Yahoo Finance의 quoteSummary API는 성공적인 응답과 에러 정보를 동일한 구조로 반환합니다.
 이 구조체는 두 경우를 모두 처리할 수 있도록 설계되었습니다.
 
 ## 응답 패턴
 
 ### 성공 응답
 ```json
 {
     "result": [
         {
             "price": { ... },
             "summaryDetail": { ... }
         }
     ],
     "error": null
 }
 ```
 
 ### 에러 응답
 ```json
 {
     "result": null,
     "error": "Invalid symbol or API error message"
 }
 ```
 
 ## 사용 패턴
 
 ```swift
 if let error = quoteSummary.error {
     print("API 에러: \(error)")
     return
 }
 
 guard let results = quoteSummary.result, !results.isEmpty else {
     print("결과 데이터 없음")
     return
 }
 
 let quoteResult = results.first!
 ```
 
 - Important: `result`와 `error` 필드는 상호 배타적입니다. 하나가 존재하면 다른 하나는 일반적으로 nil입니다.
 */
public struct YFQuoteSummary: Decodable, Sendable {
    
    /// Quote 데이터 결과 배열
    ///
    /// 성공적인 API 응답 시 시세 정보가 포함된 결과 객체들의 배열입니다.
    /// 일반적으로 단일 종목 조회 시 1개의 요소를 가집니다.
    ///
    /// - Note: API 에러 시에는 nil이거나 빈 배열일 수 있습니다.
    public let result: [YFQuoteResult]?
    
    /// API 에러 메시지
    ///
    /// Yahoo Finance API에서 반환하는 에러 메시지입니다.
    /// 잘못된 심볼, 네트워크 오류, API 제한 등의 경우에 설정됩니다.
    ///
    /// ## 일반적인 에러 메시지
    /// - "Invalid symbol": 존재하지 않는 종목 심볼
    /// - "Rate limit exceeded": API 호출 제한 초과
    /// - "Service temporarily unavailable": 일시적 서비스 중단
    ///
    /// - Important: 에러 발생 시 `result` 필드는 일반적으로 nil입니다.
    public let error: String?
}

/**
 개별 종목의 시세 정보와 상세 데이터를 포함하는 컨테이너입니다.
 
 ## 개요
 
 Yahoo Finance API는 각 종목의 데이터를 `price`와 `summaryDetail` 두 부분으로 나누어 제공합니다.
 이 구조체는 두 데이터 세트를 하나로 묶어 관리합니다.
 
 ## 데이터 구성
 
 - **price**: 실시간 시세, 거래량, 시장 상태 등 동적 정보
 - **summaryDetail**: PE 비율, 배당률, 52주 최고/최저가 등 상세 분석 정보
 
 ## 사용 패턴
 
 ```swift
 if let quote = quoteResult.price {
     print("현재가: \(quote.regularMarketPrice ?? 0)")
     print("시장 상태: \(quote.marketState ?? "Unknown")")
 }
 
 if let detail = quoteResult.summaryDetail {
     print("PE 비율: \(detail.trailingPE ?? 0)")
     print("시가총액: \(detail.marketCap ?? 0)")
 }
 ```
 
 ## 모듈 선택
 
 Yahoo Finance API에서는 modules 파라미터로 원하는 데이터 섹션을 지정할 수 있습니다:
 - `price`: 기본 시세 정보만 요청
 - `summaryDetail`: 상세 분석 정보만 요청  
 - `price,summaryDetail`: 두 섹션 모두 요청
 
 - Note: API 응답에서 요청하지 않은 모듈은 nil로 반환됩니다.
 */
public struct YFQuoteResult: Decodable, Sendable {
    
    /// 실시간 시세 및 거래 정보
    ///
    /// 주식의 현재가, 거래량, 시장 상태, 시간외 거래 정보 등을 포함합니다.
    /// 이 데이터는 실시간으로 업데이트되며 시장 상황에 따라 빠르게 변경됩니다.
    ///
    /// ## 주요 포함 정보
    /// - 현재가 (`regularMarketPrice`)
    /// - 거래량 (`regularMarketVolume`)
    /// - 장전/장후 거래 데이터
    /// - 시장 상태 (`marketState`)
    ///
    /// - Important: modules 파라미터에 "price"를 포함한 경우에만 데이터가 제공됩니다.
    public let price: YFQuote?
    
    /// 종목 상세 분석 정보
    ///
    /// PE 비율, 배당률, 52주 최고/최저가, 평균 거래량 등 투자 분석에 필요한 
    /// 상세 지표들을 포함합니다.
    ///
    /// ## 주요 포함 정보
    /// - 재무 비율 (PE, PB, 배당률 등)
    /// - 52주 최고/최저가
    /// - 평균 거래량
    /// - 시가총액
    ///
    /// - Important: modules 파라미터에 "summaryDetail"을 포함한 경우에만 데이터가 제공됩니다.
    public let summaryDetail: YFQuoteSummaryDetail?
}

/**
 종목의 상세 분석 정보를 포함하는 구조체입니다.
 
 ## 개요
 
 Yahoo Finance summaryDetail 모듈에서 제공하는 모든 필드를 노출합니다.
 투자 분석에 필요한 재무 지표, 거래량 분석, 가격 대역, 배당 정보 등을 포함합니다.
 
 ## 데이터 카테고리
 
 ### 📊 재무 비율 및 지표
 - PE 비율 (`trailingPE`, `forwardPE`)
 - PB 비율, PSR 비율 (`priceToSalesTrailing12Months`)
 - 베타 계수 (`beta`)
 - 배당 수익률 (`dividendYield`)
 
 ### 📈 가격 대역 분석
 - 52주 최고/최저가 (`fiftyTwoWeekHigh`, `fiftyTwoWeekLow`)
 - 이동평균선 (50일, 200일)
 - 일중 최고/최저가
 
 ### 📊 거래량 분석
 - 평균 거래량 (10일, 3개월)
 - 현재 거래량
 - 매수/매도 호가 및 잔량
 
 ### 💰 배당 정보  
 - 배당률 및 배당 수익률
 - 배당락일 (`exDividendDate`)
 - 배당 지급 비율 (`payoutRatio`)
 
 ## 사용 예제
 
 ```swift
 if let detail = quoteResult.summaryDetail {
     // 재무 지표 분석
     if let pe = detail.trailingPE {
         print("PER: \(String(format: "%.2f", pe))")
     }
     
     // 52주 최고가 대비 현재 위치
     if let high = detail.fiftyTwoWeekHigh,
        let current = quoteResult.price?.regularMarketPrice {
         let ratio = (current / high) * 100
         print("52주 최고가 대비: \(String(format: "%.1f", ratio))%")
     }
     
     // 배당 수익률
     if let dividend = detail.dividendYield {
         print("배당 수익률: \(String(format: "%.2f", dividend * 100))%")
     }
 }
 ```
 
 - Important: 모든 필드가 Optional이므로 사용 전 nil 체크가 필요합니다.
 - Note: Unix timestamp 필드들은 Date(timeIntervalSince1970:)로 변환하여 사용하세요.
 */
public struct YFQuoteSummaryDetail: Decodable, Sendable {
    
    // MARK: - 호가 정보
    
    /// 매수 잔량
    /// 현재 최우선 매수 호가에 대기 중인 주식 수량입니다.
    public let bidSize: Int?
    
    /// 매수 호가
    /// 현재 시장에서 제시되고 있는 최고 매수 호가입니다.
    public let bid: Double?
    
    /// 매도 호가  
    /// 현재 시장에서 제시되고 있는 최저 매도 호가입니다.
    public let ask: Double?
    
    /// 매도 잔량
    /// 현재 최우선 매도 호가에 대기 중인 주식 수량입니다.
    public let askSize: Int?
    
    // MARK: - 통화 및 시장 정보
    
    /// 거래 통화
    /// 주식이 거래되는 통화 코드입니다 (예: "USD", "KRW").
    public let currency: String?
    
    /// 환전 원본 통화
    /// 통화 환전 시 원본 통화 정보입니다.
    public let fromCurrency: String?
    
    /// 환전 대상 통화  
    /// 통화 환전 시 대상 통화 정보입니다.
    public let toCurrency: String?
    
    /// 암호화폐 마켓캡 링크
    /// CoinMarketCap 등의 외부 링크 정보입니다.
    public let coinMarketCapLink: String?
    
    /// 마지막 거래 시장
    /// 최근 거래가 발생한 시장 정보입니다.
    public let lastMarket: String?
    
    // MARK: - 가격 정보
    
    /// 전일 종가
    /// 이전 거래일의 종가입니다.
    public let previousClose: Double?
    
    /// 정규 시장 전일 종가
    /// 정규 거래시간 내 전일 종가입니다.
    public let regularMarketPreviousClose: Double?
    
    /// 당일 최고가
    /// 당일 거래에서 기록한 최고 가격입니다.
    public let dayHigh: Double?
    
    /// 당일 최저가
    /// 당일 거래에서 기록한 최저 가격입니다.
    public let dayLow: Double?
    
    /// 정규 시장 당일 최저가
    /// 정규 거래시간 내 당일 최저가입니다.
    public let regularMarketDayLow: Double?
    
    /// 정규 시장 당일 최고가
    /// 정규 거래시간 내 당일 최고가입니다.
    public let regularMarketDayHigh: Double?
    
    /// 시가
    /// 당일 첫 거래 가격입니다.
    public let open: Double?
    
    /// 정규 시장 시가
    /// 정규 거래시간 내 시가입니다.
    public let regularMarketOpen: Double?
    
    // MARK: - 거래량 정보
    
    /// 현재 거래량
    /// 당일 현재까지의 총 거래량입니다.
    public let volume: Int?
    
    /// 정규 시장 거래량
    /// 정규 거래시간 내 총 거래량입니다.
    public let regularMarketVolume: Int?
    
    /// 평균 거래량
    /// 일정 기간의 평균 일일 거래량입니다.
    public let averageVolume: Int?
    
    /// 10일 평균 거래량
    /// 최근 10거래일의 평균 거래량입니다.
    public let averageDailyVolume10Day: Int?
    
    /// 10일 평균 거래량 (중복)
    /// `averageDailyVolume10Day`와 동일한 정보입니다.
    public let averageVolume10days: Int?
    
    // MARK: - 52주 데이터
    
    /// 52주 최저가
    /// 최근 52주(1년) 동안의 최저 거래가입니다.
    public let fiftyTwoWeekLow: Double?
    
    /// 52주 최고가
    /// 최근 52주(1년) 동안의 최고 거래가입니다.
    public let fiftyTwoWeekHigh: Double?
    
    // MARK: - 이동평균선
    
    /// 50일 이동평균
    /// 최근 50거래일의 평균 가격입니다.
    public let fiftyDayAverage: Double?
    
    /// 200일 이동평균
    /// 최근 200거래일의 평균 가격입니다.
    public let twoHundredDayAverage: Double?
    
    // MARK: - 재무 지표
    
    /// 후행 PER (Price-to-Earnings Ratio)
    /// 최근 12개월 실적 기준 주가수익비율입니다.
    public let trailingPE: Double?
    
    /// 선행 PER
    /// 향후 12개월 예상 실적 기준 주가수익비율입니다.
    public let forwardPE: Double?
    
    /// PSR (Price-to-Sales Ratio)  
    /// 최근 12개월 매출 기준 주가매출비율입니다.
    public let priceToSalesTrailing12Months: Double?
    
    /// 베타 계수
    /// 시장 대비 주가 변동성을 나타내는 지표입니다 (1.0이 시장 평균).
    public let beta: Double?
    
    /// 시가총액
    /// 발행주식수 × 현재주가로 계산된 기업의 시장 가치입니다.
    public let marketCap: Double?
    
    // MARK: - 배당 정보
    
    /// 배당률 (연간)
    /// 연간 주당 배당금입니다.
    public let dividendRate: Double?
    
    /// 배당 수익률
    /// 현재 주가 대비 배당률의 비율입니다 (소수점 형태: 0.05 = 5%).
    public let dividendYield: Double?
    
    /// 과거 12개월 배당률
    /// 최근 12개월 동안 지급된 배당금의 총합입니다.
    public let trailingAnnualDividendRate: Double?
    
    /// 과거 12개월 배당 수익률
    /// 최근 12개월 배당률 기준 수익률입니다.
    public let trailingAnnualDividendYield: Double?
    
    /// 5년 평균 배당 수익률
    /// 최근 5년간의 평균 배당 수익률입니다.
    public let fiveYearAvgDividendYield: Double?
    
    /// 배당 지급률
    /// 순이익 중 배당금으로 지급되는 비율입니다.
    public let payoutRatio: Double?
    
    /// 배당락일
    /// 배당 받을 권리가 소멸되는 날짜 (Unix timestamp)입니다.
    /// 이 날짜 이후 매수 시 해당 배당을 받을 수 없습니다.
    public let exDividendDate: Int?
    
    // MARK: - 시스템 정보
    
    /// 데이터 최대 유효 기간
    /// 현재 데이터의 유효 기간 (초 단위)입니다.
    public let maxAge: Int?
    
    /// 가격 정밀도 힌트
    /// 가격 표시 시 소수점 자릿수 힌트입니다.
    public let priceHint: Int?
    
    /// 거래 가능 여부
    /// 현재 해당 종목의 거래 가능 상태입니다.
    public let tradeable: Bool?
    
    /// 알고리즘 정보
    /// Yahoo Finance에서 사용하는 내부 알고리즘 정보입니다.
    public let algorithm: String?
}

/**
 Yahoo Finance에서 제공하는 실시간 주식 시세 정보를 담는 핵심 구조체입니다.
 
 ## 개요
 
 이 구조체는 Yahoo Finance API의 `price` 모듈에서 제공하는 모든 필드를 노출합니다.
 실시간 가격, 거래량, 시장 상태, 시간외 거래 정보 등 주식 투자에 필요한
 핵심 데이터를 포함합니다.
 
 ## 주요 데이터 그룹
 
 ### 📊 기본 시세 정보
 - 현재가 (`regularMarketPrice`)
 - 시가, 고가, 저가 (`regularMarketOpen`, `regularMarketDayHigh`, `regularMarketDayLow`)
 - 거래량 (`regularMarketVolume`)
 - 전일 대비 등락률 (`regularMarketChangePercent`)
 
 ### 🕒 시간외 거래 데이터
 - 장전 거래: `preMarket*` 필드들
 - 장후 거래: `postMarket*` 필드들
 - 각각 가격, 변동률, 거래 시간 포함
 
 ### 🏢 종목 및 시장 정보
 - 종목 코드 (`symbol`)
 - 회사명 (`shortName`, `longName`)
 - 거래소 정보 (`exchange`, `exchangeName`)
 - 종목 유형 (`quoteType`)
 
 ### ⏰ 시간 정보
 - 정규 거래 시간 (`regularMarketTime`)
 - 장전/장후 거래 시간
 - 데이터 지연 시간 (`exchangeDataDelayedBy`)
 
 ## 실제 사용 예제
 
 ```swift
 let client = YFClient()
 let ticker = YFTicker(symbol: "AAPL")
 
 do {
     let quote = try await client.quote.fetch(ticker: ticker)
     
     // 기본 정보 출력
     print("=== \(quote.longName ?? quote.shortName ?? "Unknown") ===")
     print("Symbol: \(quote.symbol ?? "N/A")")
     print("Exchange: \(quote.exchangeName ?? "N/A")")
     
     // 현재 시세 정보
     if let price = quote.regularMarketPrice,
        let change = quote.regularMarketChange,
        let changePercent = quote.regularMarketChangePercent {
         
         let changeSign = change >= 0 ? "+" : ""
         print("Current: $\(String(format: "%.2f", price))")
         print("Change: \(changeSign)\(String(format: "%.2f", change)) (\(changeSign)\(String(format: "%.2f", changePercent))%)")
     }
     
     // 거래량 정보
     if let volume = quote.regularMarketVolume {
         print("Volume: \(NumberFormatter.localizedString(from: NSNumber(value: volume), number: .decimal))")
     }
     
     // 시장 상태 확인
     switch quote.marketState {
     case "REGULAR":
         print("🟢 정규 거래 중")
     case "CLOSED":
         print("🔴 장 마감")
     case "PRE":
         print("🟡 장전 거래 중")
         if let prePrice = quote.preMarketPrice {
             print("Pre-market: $\(String(format: "%.2f", prePrice))")
         }
     case "POST":
         print("🟡 장후 거래 중")
         if let postPrice = quote.postMarketPrice {
             print("After-hours: $\(String(format: "%.2f", postPrice))")
         }
     default:
         print("시장 상태: \(quote.marketState ?? "Unknown")")
     }
     
     // 시가총액 (단위: 달러)
     if let marketCap = quote.marketCap {
         let billions = marketCap / 1_000_000_000
         print("Market Cap: $\(String(format: "%.2f", billions))B")
     }
     
 } catch {
     print("시세 조회 실패: \(error)")
 }
 ```
 
 ## 시간 데이터 처리
 
 Unix timestamp 필드들을 Date로 변환하는 방법:
 
 ```swift
 // 정규 시장 시간 변환
 if let timestamp = quote.regularMarketTime {
     let marketTime = Date(timeIntervalSince1970: TimeInterval(timestamp))
     let formatter = DateFormatter()
     formatter.dateStyle = .short
     formatter.timeStyle = .short
     print("Market Time: \(formatter.string(from: marketTime))")
 }
 
 // 장후 거래 시간 변환
 if let timestamp = quote.postMarketTime {
     let postMarketTime = Date(timeIntervalSince1970: TimeInterval(timestamp))
     print("After-hours Time: \(postMarketTime)")
 }
 ```
 
 ## 주의사항
 
 - **실시간 데이터**: 값들이 시장 상황에 따라 빠르게 변경됩니다
 - **Optional 처리**: 모든 필드가 optional이므로 안전한 접근 필요
 - **통화 단위**: 가격은 해당 종목의 거래 통화로 표시됩니다
 - **데이터 지연**: `exchangeDataDelayedBy` 필드로 지연 시간 확인 가능
 - **시간외 거래**: 장전/장후 데이터는 해당 시간대에만 제공됩니다
 
 ## 관련 타입
 
 - ``YFQuoteSummaryDetail``: 상세 분석 정보 (PE 비율, 배당 등)
 - ``YFTicker``: 종목 식별자
 - ``YFQuoteService``: Quote API 서비스
 */
public struct YFQuote: Decodable, Sendable {
    
    // MARK: - 기본 종목 정보
    
    /// 종목 심볼
    /// 거래소에서 사용하는 종목 식별 코드입니다 (예: "AAPL", "MSFT").
    public let symbol: String?
    
    /// 회사 전체명
    /// 공식적인 회사 전체 명칭입니다 (예: "Apple Inc.").
    public let longName: String?
    
    /// 회사 축약명  
    /// 일반적으로 사용되는 회사 축약 명칭입니다 (예: "Apple Inc").
    public let shortName: String?
    
    /// 종목 유형
    /// 주식의 분류를 나타냅니다 (예: "EQUITY", "ETF", "MUTUALFUND").
    public let quoteType: String?
    
    /// 기초 자산 심볼
    /// 파생상품의 경우 기초가 되는 자산의 심볼입니다.
    public let underlyingSymbol: String?
    
    // MARK: - 거래소 정보
    
    /// 거래소 코드
    /// 종목이 거래되는 거래소의 축약 코드입니다 (예: "NMS", "NYQ").
    public let exchange: String?
    
    /// 거래소 전체명
    /// 거래소의 정식 명칭입니다 (예: "NASDAQ", "New York Stock Exchange").
    public let exchangeName: String?
    
    /// 데이터 지연 시간
    /// 실시간 대비 현재 데이터의 지연 시간(분 단위)입니다.
    /// 0이면 실시간, 15면 15분 지연 데이터를 의미합니다.
    public let exchangeDataDelayedBy: Int?
    
    // MARK: - 통화 정보
    
    /// 거래 통화
    /// 주식이 거래되는 통화 코드입니다 (예: "USD", "KRW").
    public let currency: String?
    
    /// 통화 심볼
    /// 통화를 표시하는 기호입니다 (예: "$", "₩").
    public let currencySymbol: String?
    
    /// 환전 원본 통화
    /// 통화 변환 시 원본 통화 코드입니다.
    public let fromCurrency: String?
    
    /// 환전 대상 통화
    /// 통화 변환 시 대상 통화 코드입니다.
    public let toCurrency: String?
    
    // MARK: - 현재 시세 정보
    
    /// 현재가 (정규 시장)
    /// 정규 거래시간 내 최근 거래 가격입니다.
    /// 가장 중요한 필드 중 하나로, 현재 주식의 가치를 나타냅니다.
    public let regularMarketPrice: Double?
    
    /// 시가 (정규 시장)
    /// 당일 정규 거래시간 개시 시 첫 거래 가격입니다.
    public let regularMarketOpen: Double?
    
    /// 고가 (정규 시장)
    /// 당일 정규 거래시간 내 최고 거래 가격입니다.
    public let regularMarketDayHigh: Double?
    
    /// 저가 (정규 시장)  
    /// 당일 정규 거래시간 내 최저 거래 가격입니다.
    public let regularMarketDayLow: Double?
    
    /// 전일 종가 (정규 시장)
    /// 이전 거래일의 정규 시장 종료 시 가격입니다.
    public let regularMarketPreviousClose: Double?
    
    /// 등락폭 (정규 시장)
    /// 전일 종가 대비 현재가의 절대적 변동폭입니다.
    /// 양수면 상승, 음수면 하락을 의미합니다.
    public let regularMarketChange: Double?
    
    /// 등락률 (정규 시장)
    /// 전일 종가 대비 현재가의 변동률(%)입니다.
    /// 소수점 형태로 표현됩니다 (0.05 = 5%).
    public let regularMarketChangePercent: Double?
    
    // MARK: - 거래량 및 시장 정보
    
    /// 거래량 (정규 시장)
    /// 당일 정규 거래시간 내 총 거래된 주식 수입니다.
    public let regularMarketVolume: Int?
    
    /// 3개월 평균 일일 거래량
    /// 최근 3개월간의 평균 일일 거래량입니다.
    public let averageDailyVolume3Month: Int?
    
    /// 10일 평균 일일 거래량
    /// 최근 10거래일간의 평균 거래량입니다.
    public let averageDailyVolume10Day: Int?
    
    /// 시가총액
    /// 발행주식수 × 현재주가로 계산된 회사의 시장 가치입니다.
    /// 단위: 해당 통화 (보통 달러)
    public let marketCap: Double?
    
    /// 시장 상태
    /// 현재 시장의 거래 상태를 나타냅니다.
    /// - "REGULAR": 정규 거래 중
    /// - "CLOSED": 장 마감  
    /// - "PRE": 장전 거래
    /// - "POST": 장후 거래
    public let marketState: String?
    
    // MARK: - 시간 정보
    
    /// 정규 시장 마지막 업데이트 시간
    /// 정규 시장 데이터의 마지막 업데이트 시간 (Unix timestamp)입니다.
    public let regularMarketTime: Int?
    
    /// 데이터 최대 유효 기간
    /// 현재 데이터의 최대 유효 기간 (초 단위)입니다.
    public let maxAge: Int?
    
    // MARK: - 장전 거래 정보
    
    /// 장전 거래 가격
    /// 정규 시장 개장 전 거래되는 가격입니다.
    /// 보통 오전 4:00-9:30 (EST) 시간대의 거래입니다.
    public let preMarketPrice: Double?
    
    /// 장전 거래 변동폭
    /// 전일 종가 대비 장전 거래 가격의 변동폭입니다.
    public let preMarketChange: Double?
    
    /// 장전 거래 변동률
    /// 전일 종가 대비 장전 거래 가격의 변동률(%)입니다.
    public let preMarketChangePercent: Double?
    
    /// 장전 거래 시간
    /// 장전 거래 데이터의 마지막 업데이트 시간 (Unix timestamp)입니다.
    public let preMarketTime: Int?
    
    /// 장전 거래 데이터 출처
    /// 장전 거래 정보의 데이터 제공원입니다.
    public let preMarketSource: String?
    
    // MARK: - 장후 거래 정보
    
    /// 장후 거래 가격
    /// 정규 시장 마감 후 거래되는 가격입니다.
    /// 보통 오후 4:00-8:00 (EST) 시간대의 거래입니다.
    public let postMarketPrice: Double?
    
    /// 장후 거래 변동폭
    /// 정규 시장 종가 대비 장후 거래 가격의 변동폭입니다.
    public let postMarketChange: Double?
    
    /// 장후 거래 변동률
    /// 정규 시장 종가 대비 장후 거래 가격의 변동률(%)입니다.
    public let postMarketChangePercent: Double?
    
    /// 장후 거래 시간
    /// 장후 거래 데이터의 마지막 업데이트 시간 (Unix timestamp)입니다.
    public let postMarketTime: Int?
    
    /// 장후 거래 데이터 출처
    /// 장후 거래 정보의 데이터 제공원입니다.
    public let postMarketSource: String?
    
    // MARK: - 데이터 소스 정보
    
    /// 시세 데이터 출처명
    /// 현재 시세 정보를 제공하는 데이터 소스의 이름입니다.
    public let quoteSourceName: String?
    
    /// 정규 시장 데이터 출처
    /// 정규 시장 데이터의 제공원입니다.
    public let regularMarketSource: String?
    
    /// 마지막 거래 시장
    /// 최근 거래가 발생한 시장 정보입니다.
    public let lastMarket: String?
    
    /// 가격 표시 정밀도
    /// 가격 표시 시 권장되는 소수점 자릿수입니다.
    /// 2이면 소수점 둘째 자리까지 표시를 권장합니다.
    public let priceHint: Int?
}


