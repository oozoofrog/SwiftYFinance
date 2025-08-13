import Foundation

/// 실시간 주식 시세 정보
///
/// Yahoo Finance API에서 제공하는 현재 시장 데이터를 포함합니다.
/// 정규 거래시간, 장전/장후 거래 데이터를 모두 지원합니다.
///
/// ## 포함 데이터
/// - **현재가**: 최신 거래가격
/// - **거래량**: 당일 총 거래량  
/// - **시장 통계**: 시가, 고가, 저가, 전일종가
/// - **시가총액**: 발행주식수 × 현재가
/// - **장외 거래**: 장전/장후 거래 데이터 (해당시)
///
/// ## 사용 예시
/// ```swift
/// let client = YFClient()
/// let quote = try await client.fetchQuote(symbol: "AAPL")
///
/// print("회사명: \(quote.shortName)")
/// print("현재가: $\(quote.regularMarketPrice)")
/// print("거래량: \(quote.regularMarketVolume.formatted())")
/// print("시가총액: $\(quote.marketCap.formatted())")
///
/// // 장후 거래 확인
/// if let postPrice = quote.postMarketPrice {
///     print("장후 거래가: $\(postPrice)")
/// }
/// ```
public struct YFQuote: Codable {
    
    /// 주식 심볼 정보
    public let ticker: YFTicker
    
    /// 정규 시장 현재가 (USD)
    ///
    /// 정규 거래시간 중 최신 거래가격
    public let regularMarketPrice: Double
    
    /// 정규 시장 거래량
    ///
    /// 당일 총 거래된 주식 수
    public let regularMarketVolume: Int
    
    /// 시가총액 (USD)
    ///
    /// 발행주식수 × 현재가로 계산된 시장가치
    public let marketCap: Double
    
    /// 회사명 (단축형)
    ///
    /// Yahoo Finance에서 제공하는 회사 표시명
    public let shortName: String
    
    /// 정규 시장 거래 시각
    ///
    /// 마지막 거래가 발생한 시간 (현지 시간대)
    public let regularMarketTime: Date
    
    /// 정규 시장 시가 (USD)
    ///
    /// 당일 정규 거래시간 시작가격
    public let regularMarketOpen: Double
    
    /// 정규 시장 고가 (USD)
    ///
    /// 당일 정규 거래시간 중 최고가격
    public let regularMarketHigh: Double
    
    /// 정규 시장 저가 (USD)
    ///
    /// 당일 정규 거래시간 중 최저가격
    public let regularMarketLow: Double
    
    /// 전일 종가 (USD)
    ///
    /// 이전 거래일의 마지막 거래가격
    public let regularMarketPreviousClose: Double
    
    /// 실시간 데이터 여부
    ///
    /// true면 실시간 데이터, false면 지연된 데이터
    public let isRealtime: Bool
    
    // MARK: - 장후 거래 데이터
    
    /// 장후 거래가 (USD)
    ///
    /// 정규 거래시간 종료 후의 거래가격 (옵셔널)
    public let postMarketPrice: Double?
    
    /// 장후 거래 시각
    ///
    /// 마지막 장후 거래가 발생한 시간 (옵셔널)
    public let postMarketTime: Date?
    
    /// 장후 거래 변화율 (%)
    ///
    /// 정규 종가 대비 장후 거래가의 변화율 (옵셔널)
    public let postMarketChangePercent: Double?
    
    // MARK: - 장전 거래 데이터
    
    /// 장전 거래가 (USD)
    ///
    /// 정규 거래시간 시작 전의 거래가격 (옵셔널)
    public let preMarketPrice: Double?
    
    /// 장전 거래 시각
    ///
    /// 마지막 장전 거래가 발생한 시간 (옵셔널)
    public let preMarketTime: Date?
    
    /// 장전 거래 변화율 (%)
    ///
    /// 전일 종가 대비 장전 거래가의 변화율 (옵셔널)
    public let preMarketChangePercent: Double?
    
    /// YFQuote 초기화
    ///
    /// 실시간 주식 시세 정보를 생성합니다.
    /// 정규 거래 데이터는 필수이며, 장전/장후 거래 데이터는 선택사항입니다.
    ///
    /// - Parameters:
    ///   - ticker: 주식 심볼
    ///   - regularMarketPrice: 정규 시장 현재가
    ///   - regularMarketVolume: 정규 시장 거래량
    ///   - marketCap: 시가총액
    ///   - shortName: 회사명 (단축형)
    ///   - regularMarketTime: 정규 시장 거래 시각
    ///   - regularMarketOpen: 정규 시장 시가
    ///   - regularMarketHigh: 정규 시장 고가
    ///   - regularMarketLow: 정규 시장 저가
    ///   - regularMarketPreviousClose: 전일 종가
    ///   - isRealtime: 실시간 데이터 여부 (기본값: false)
    ///   - postMarketPrice: 장후 거래가 (옵셔널)
    ///   - postMarketTime: 장후 거래 시각 (옵셔널)
    ///   - postMarketChangePercent: 장후 거래 변화율 (옵셔널)
    ///   - preMarketPrice: 장전 거래가 (옵셔널)
    ///   - preMarketTime: 장전 거래 시각 (옵셔널)
    ///   - preMarketChangePercent: 장전 거래 변화율 (옵셔널)
    public init(
        ticker: YFTicker,
        regularMarketPrice: Double,
        regularMarketVolume: Int,
        marketCap: Double,
        shortName: String,
        regularMarketTime: Date,
        regularMarketOpen: Double,
        regularMarketHigh: Double,
        regularMarketLow: Double,
        regularMarketPreviousClose: Double,
        isRealtime: Bool = false,
        postMarketPrice: Double? = nil,
        postMarketTime: Date? = nil,
        postMarketChangePercent: Double? = nil,
        preMarketPrice: Double? = nil,
        preMarketTime: Date? = nil,
        preMarketChangePercent: Double? = nil
    ) {
        self.ticker = ticker
        self.regularMarketPrice = regularMarketPrice
        self.regularMarketVolume = regularMarketVolume
        self.marketCap = marketCap
        self.shortName = shortName
        self.regularMarketTime = regularMarketTime
        self.regularMarketOpen = regularMarketOpen
        self.regularMarketHigh = regularMarketHigh
        self.regularMarketLow = regularMarketLow
        self.regularMarketPreviousClose = regularMarketPreviousClose
        self.isRealtime = isRealtime
        self.postMarketPrice = postMarketPrice
        self.postMarketTime = postMarketTime
        self.postMarketChangePercent = postMarketChangePercent
        self.preMarketPrice = preMarketPrice
        self.preMarketTime = preMarketTime
        self.preMarketChangePercent = preMarketChangePercent
    }
}