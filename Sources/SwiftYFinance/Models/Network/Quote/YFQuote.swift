import Foundation

// MARK: - Yahoo Finance Quote Models

/// Yahoo Finance Quote API 모델 집합
/// 
/// quoteSummary와 query1 API 응답을 파싱하기 위한 Swift 구조체들을 정의합니다.
/// 모든 필드는 Yahoo Finance API 응답과 1:1 매칭됩니다.

/// Yahoo Finance quoteSummary API 최상위 응답 래퍼
public struct YFQuoteSummaryResponse: Decodable, Sendable {
    
    /// quoteSummary API 데이터 컨테이너
    public let quoteSummary: YFQuoteSummary?
}

/// Yahoo Finance query1 quote API 응답 래퍼
public struct YFQuoteResponse: Decodable, Sendable {
    
    /// Quote 데이터 결과 배열
    public let result: [YFQuote]?
    
    /// API 에러 메시지
    public let error: String?
    
    // MARK: - Custom Decoding
    
    private enum CodingKeys: String, CodingKey {
        case quoteResponse
    }
    
    private enum QuoteResponseKeys: String, CodingKey {
        case result
        case error
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let quoteResponseContainer = try container.nestedContainer(keyedBy: QuoteResponseKeys.self, forKey: .quoteResponse)
        
        self.result = try quoteResponseContainer.decodeIfPresent([YFQuote].self, forKey: .result)
        self.error = try quoteResponseContainer.decodeIfPresent(String.self, forKey: .error)
    }
}

/// quoteSummary API 응답 데이터 컨테이너
/// 
/// 성공 시 result 배열, 실패 시 error 메시지를 포함합니다.
public struct YFQuoteSummary: Decodable, Sendable {
    
    /// Quote 데이터 결과 배열
    public let result: [YFQuoteResult]?
    
    /// API 에러 메시지
    public let error: String?
}


/// 개별 종목의 price + summaryDetail 데이터 컨테이너
/// 
/// Yahoo Finance API가 제공하는 실시간 시세와 상세 분석 정보를 묶어 관리합니다.
public struct YFQuoteResult: Decodable, Sendable {
    
    /// 실시간 시세 및 거래 정보
    public let price: YFQuote?
    
    /// 종목 상세 분석 정보 (PE 비율, 배당률, 52주 최고/최저가 등)
    public let summaryDetail: YFQuoteSummaryDetail?
}

/// 종목의 상세 분석 정보 구조체
/// 
/// 재무 비율, 가격 대역, 거래량 분석, 배당 정보 등 투자 분석 지표들을 포함합니다.
public struct YFQuoteSummaryDetail: Decodable, Sendable {
    
    // MARK: - 호가 정보
    
    /// 매수 잔량
    public let bidSize: Int?
    
    /// 매수 호가
    public let bid: Double?
    
    /// 매도 호가
    public let ask: Double?
    
    /// 매도 잔량
    public let askSize: Int?
    
    // MARK: - 통화 및 시장 정보
    
    /// 거래 통화
    public let currency: String?
    
    /// 환전 원본 통화
    public let fromCurrency: String?
    
    /// 환전 대상 통화
    public let toCurrency: String?
    
    /// 암호화폐 마켓캡 링크
    public let coinMarketCapLink: String?
    
    /// 마지막 거래 시장
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

// MARK: - Modular Quote Models

/**
 기본 종목 정보를 담는 모델입니다.
 
 종목의 식별 정보와 회사명 등 변하지 않는 기본 정보를 포함합니다.
 */
public struct YFQuoteBasicInfo: Decodable, Sendable {
    /// 종목 심볼
    public let symbol: String?
    
    /// 회사 전체명
    public let longName: String?
    
    /// 회사 축약명  
    public let shortName: String?
    
    /// 종목 유형 (예: "EQUITY", "ETF")
    public let quoteType: String?
    
    /// 기초 자산 심볼 (파생상품의 경우)
    public let underlyingSymbol: String?
}

/**
 거래소 및 통화 정보를 담는 모델입니다.
 
 종목이 거래되는 거래소와 통화 관련 정보를 포함합니다.
 */
public struct YFQuoteExchangeInfo: Decodable, Sendable {
    /// 거래소 코드
    public let exchange: String?
    
    /// 거래소 전체명
    public let exchangeName: String?
    
    /// 데이터 지연 시간 (분)
    public let exchangeDataDelayedBy: Int?
    
    /// 거래 통화
    public let currency: String?
    
    /// 통화 심볼
    public let currencySymbol: String?
    
    /// 환전 원본 통화
    public let fromCurrency: String?
    
    /// 환전 대상 통화
    public let toCurrency: String?
}

/**
 현재 시세 정보를 담는 모델입니다.
 
 실시간 가격, 등락률, 시고저 등 핵심 시세 데이터를 포함합니다.
 */
public struct YFQuoteMarketData: Decodable, Sendable {
    /// 현재가 (정규 시장)
    public let regularMarketPrice: Double?
    
    /// 시가 (정규 시장)
    public let regularMarketOpen: Double?
    
    /// 고가 (정규 시장)
    public let regularMarketDayHigh: Double?
    
    /// 저가 (정규 시장)  
    public let regularMarketDayLow: Double?
    
    /// 전일 종가 (정규 시장)
    public let regularMarketPreviousClose: Double?
    
    /// 등락폭 (정규 시장)
    public let regularMarketChange: Double?
    
    /// 등락률 (정규 시장)
    public let regularMarketChangePercent: Double?
}

/**
 거래량 및 시장 상태 정보를 담는 모델입니다.
 
 거래량, 시가총액, 시장 상태 등의 정보를 포함합니다.
 */
public struct YFQuoteVolumeInfo: Decodable, Sendable {
    /// 거래량 (정규 시장)
    public let regularMarketVolume: Int?
    
    /// 3개월 평균 일일 거래량
    public let averageDailyVolume3Month: Int?
    
    /// 10일 평균 일일 거래량
    public let averageDailyVolume10Day: Int?
    
    /// 시가총액
    public let marketCap: Double?
    
    /// 시장 상태 ("REGULAR", "CLOSED", "PRE", "POST")
    public let marketState: String?
}

/**
 장전/장후 거래 정보를 담는 모델입니다.
 
 정규 시장 외 시간대의 거래 정보를 포함합니다.
 */
public struct YFQuoteExtendedHoursData: Decodable, Sendable {
    // MARK: - 장전 거래
    
    /// 장전 거래 가격
    public let preMarketPrice: Double?
    
    /// 장전 거래 변동폭
    public let preMarketChange: Double?
    
    /// 장전 거래 변동률
    public let preMarketChangePercent: Double?
    
    /// 장전 거래 시간
    public let preMarketTime: Int?
    
    /// 장전 거래 데이터 출처
    public let preMarketSource: String?
    
    // MARK: - 장후 거래
    
    /// 장후 거래 가격
    public let postMarketPrice: Double?
    
    /// 장후 거래 변동폭
    public let postMarketChange: Double?
    
    /// 장후 거래 변동률
    public let postMarketChangePercent: Double?
    
    /// 장후 거래 시간
    public let postMarketTime: Int?
    
    /// 장후 거래 데이터 출처
    public let postMarketSource: String?
}

/**
 시간 정보 및 데이터 소스 메타데이터를 담는 모델입니다.
 
 데이터의 업데이트 시간과 출처 정보를 포함합니다.
 */
public struct YFQuoteMetadata: Decodable, Sendable {
    /// 정규 시장 마지막 업데이트 시간
    public let regularMarketTime: Int?
    
    /// 데이터 최대 유효 기간
    public let maxAge: Int?
    
    /// 시세 데이터 출처명
    public let quoteSourceName: String?
    
    /// 정규 시장 데이터 출처
    public let regularMarketSource: String?
    
    /// 마지막 거래 시장
    public let lastMarket: String?
    
    /// 가격 표시 정밀도
    public let priceHint: Int?
}

/**
 모듈형 YFQuote 구조체입니다.
 
 ## 개요
 
 기존 YFQuote의 모든 기능을 유지하면서, 필요한 정보만 선택적으로 디코딩할 수 있도록 
 분류별 모델들로 구성된 복합 구조체입니다.
 
 ## 사용 예제
 
 ```swift
 // 기본 정보만 필요한 경우
 let basicInfo = try JSONDecoder().decode(YFQuoteBasicInfo.self, from: jsonData)
 print("Company: \(basicInfo.longName ?? "Unknown")")
 
 // 시세 정보만 필요한 경우  
 let marketData = try JSONDecoder().decode(YFQuoteMarketData.self, from: jsonData)
 if let price = marketData.regularMarketPrice {
     print("Price: $\(price)")
 }
 
 // 전체 정보가 필요한 경우
 let fullQuote = try JSONDecoder().decode(YFQuote.self, from: jsonData)
 print("Symbol: \(fullQuote.basicInfo.symbol ?? "N/A")")
 print("Price: $\(fullQuote.marketData.regularMarketPrice ?? 0)")
 ```
 
 ## 장점
 
 - **선택적 디코딩**: 필요한 정보만 파싱하여 성능 최적화
 - **타입 안전성**: 각 도메인별 특화된 타입 정의
 - **메모리 효율성**: 불필요한 필드 로딩 방지
 - **모듈화**: 각 정보 그룹의 독립적 관리
 - **하위 호환성**: 기존 YFQuote와 동일한 필드 제공
 */
public struct YFQuote: Decodable, Sendable {
    /// 기본 종목 정보
    public let basicInfo: YFQuoteBasicInfo
    
    /// 거래소 및 통화 정보
    public let exchangeInfo: YFQuoteExchangeInfo
    
    /// 현재 시세 정보
    public let marketData: YFQuoteMarketData
    
    /// 거래량 및 시장 정보
    public let volumeInfo: YFQuoteVolumeInfo
    
    /// 장전/장후 거래 정보
    public let extendedHours: YFQuoteExtendedHoursData
    
    /// 시간 및 메타데이터
    public let metadata: YFQuoteMetadata
    
    // MARK: - Custom Decoding
    
    /// 하나의 JSON 객체에서 모든 분류별 모델을 디코딩합니다
    public init(from decoder: Decoder) throws {
        // 같은 decoder를 사용하여 각 모델을 디코딩
        self.basicInfo = try YFQuoteBasicInfo(from: decoder)
        self.exchangeInfo = try YFQuoteExchangeInfo(from: decoder)
        self.marketData = try YFQuoteMarketData(from: decoder)
        self.volumeInfo = try YFQuoteVolumeInfo(from: decoder)
        self.extendedHours = try YFQuoteExtendedHoursData(from: decoder)
        self.metadata = try YFQuoteMetadata(from: decoder)
    }
}


// MARK: - YFQuote Utility Extensions

extension YFQuote {
    /// 시세 데이터만 필요한 경우의 간소화된 표현
    public var essentialData: (symbol: String?, price: Double?, change: Double?, changePercent: Double?) {
        return (
            symbol: basicInfo.symbol,
            price: marketData.regularMarketPrice,
            change: marketData.regularMarketChange,
            changePercent: marketData.regularMarketChangePercent
        )
    }
    
    /// 시장 상태를 기반으로 한 적절한 가격 정보 반환
    public var currentPrice: Double? {
        switch volumeInfo.marketState {
        case "PRE":
            return extendedHours.preMarketPrice ?? marketData.regularMarketPrice
        case "POST":
            return extendedHours.postMarketPrice ?? marketData.regularMarketPrice
        default:
            return marketData.regularMarketPrice
        }
    }
    
    /// 현재 시세의 전일 대비 변동률 (시간외 거래 포함)
    public var currentChangePercent: Double? {
        switch volumeInfo.marketState {
        case "PRE":
            return extendedHours.preMarketChangePercent ?? marketData.regularMarketChangePercent
        case "POST":
            return extendedHours.postMarketChangePercent ?? marketData.regularMarketChangePercent
        default:
            return marketData.regularMarketChangePercent
        }
    }
    
    /// 시장 상태에 맞는 마지막 업데이트 시간
    public var lastUpdateTime: Date? {
        let timestamp: Int?
        switch volumeInfo.marketState {
        case "PRE":
            timestamp = extendedHours.preMarketTime ?? metadata.regularMarketTime
        case "POST":
            timestamp = extendedHours.postMarketTime ?? metadata.regularMarketTime
        default:
            timestamp = metadata.regularMarketTime
        }
        
        guard let timestamp = timestamp else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
}


