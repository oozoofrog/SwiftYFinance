import Foundation

// MARK: - Yahoo Finance Quote Summary Detail

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