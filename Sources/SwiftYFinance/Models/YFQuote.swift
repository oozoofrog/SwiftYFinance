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
public struct YFQuote {
    
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
        self.postMarketPrice = postMarketPrice
        self.postMarketTime = postMarketTime
        self.postMarketChangePercent = postMarketChangePercent
        self.preMarketPrice = preMarketPrice
        self.preMarketTime = preMarketTime
        self.preMarketChangePercent = preMarketChangePercent
    }
}

// MARK: - Decodable Implementation for quoteSummary API

extension YFQuote: Decodable {
    
    /// quoteSummary API 응답을 위한 CodingKeys
    ///
    /// YFQuote가 quoteSummary API 응답 구조를 직접 이해하도록 합니다.
    /// Python yfinance의 Quote 클래스처럼 API 응답을 직접 처리합니다.
    private enum CodingKeys: String, CodingKey {
        case quoteSummary
    }
    
    /// quoteSummary 컨테이너 CodingKeys
    private enum QuoteSummaryKeys: String, CodingKey {
        case result, error
    }
    
    /// result 배열 내부 CodingKeys
    private enum ResultKeys: String, CodingKey {
        case price, summaryDetail
    }
    
    /// price 데이터 CodingKeys
    private enum PriceKeys: String, CodingKey {
        case shortName
        case regularMarketPrice, regularMarketVolume, marketCap
        case regularMarketTime, regularMarketOpen
        case regularMarketDayHigh, regularMarketDayLow
        case regularMarketPreviousClose
        case postMarketPrice, postMarketTime, postMarketChangePercent
        case preMarketPrice, preMarketTime, preMarketChangePercent
    }
    
    /// quoteSummary API 응답으로부터 YFQuote 디코딩
    ///
    /// Yahoo Finance quoteSummary API의 중첩된 JSON 구조를 직접 파싱합니다.
    /// Python yfinance Quote 클래스와 유사한 접근 방식입니다.
    ///
    /// - Parameter decoder: JSON 디코더
    /// - Throws: 디코딩 실패 시 DecodingError
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let quoteSummaryContainer = try container.nestedContainer(keyedBy: QuoteSummaryKeys.self, forKey: .quoteSummary)
        
        // 에러 응답 확인
        if let errorContainer = try? quoteSummaryContainer.nestedContainer(keyedBy: ErrorKeys.self, forKey: .error) {
            let errorDescription = try errorContainer.decode(String.self, forKey: .description)
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "API Error: \(errorDescription)"
            ))
        }
        
        // result 배열 처리
        var resultArray = try quoteSummaryContainer.nestedUnkeyedContainer(forKey: .result)
        let resultContainer = try resultArray.nestedContainer(keyedBy: ResultKeys.self)
        
        // price 데이터 파싱
        let priceContainer = try resultContainer.nestedContainer(keyedBy: PriceKeys.self, forKey: .price)
        
        // 필수 데이터 추출
        let shortName = try priceContainer.decodeIfPresent(String.self, forKey: .shortName)
        let regularMarketPrice = try priceContainer.decodeIfPresent(Double.self, forKey: .regularMarketPrice) ?? 0.0
        let regularMarketVolume = try priceContainer.decodeIfPresent(Int.self, forKey: .regularMarketVolume) ?? 0
        let marketCap = try priceContainer.decodeIfPresent(Double.self, forKey: .marketCap) ?? 0.0
        let regularMarketTimeStamp = try priceContainer.decodeIfPresent(Int.self, forKey: .regularMarketTime) ?? 0
        let regularMarketOpen = try priceContainer.decodeIfPresent(Double.self, forKey: .regularMarketOpen) ?? 0.0
        let regularMarketHigh = try priceContainer.decodeIfPresent(Double.self, forKey: .regularMarketDayHigh) ?? 0.0
        let regularMarketLow = try priceContainer.decodeIfPresent(Double.self, forKey: .regularMarketDayLow) ?? 0.0
        let regularMarketPreviousClose = try priceContainer.decodeIfPresent(Double.self, forKey: .regularMarketPreviousClose) ?? 0.0
        
        // 시간외 거래 데이터 (옵셔널)
        let postMarketPrice = try priceContainer.decodeIfPresent(Double.self, forKey: .postMarketPrice)
        let postMarketTimeStamp = try priceContainer.decodeIfPresent(Int.self, forKey: .postMarketTime)
        let postMarketChangePercent = try priceContainer.decodeIfPresent(Double.self, forKey: .postMarketChangePercent)
        let preMarketPrice = try priceContainer.decodeIfPresent(Double.self, forKey: .preMarketPrice)
        let preMarketTimeStamp = try priceContainer.decodeIfPresent(Int.self, forKey: .preMarketTime)
        let preMarketChangePercent = try priceContainer.decodeIfPresent(Double.self, forKey: .preMarketChangePercent)
        
        // ticker는 디코딩에서 얻을 수 없으므로, 이는 서비스에서 별도 처리 필요
        // 임시로 빈 ticker 생성 (서비스에서 올바른 ticker로 교체됨)
        let ticker = YFTicker(symbol: shortName ?? "UNKNOWN")
        
        // YFQuote 초기화
        self.init(
            ticker: ticker,
            regularMarketPrice: regularMarketPrice,
            regularMarketVolume: regularMarketVolume,
            marketCap: marketCap,
            shortName: shortName ?? ticker.symbol,
            regularMarketTime: Date(timeIntervalSince1970: TimeInterval(regularMarketTimeStamp)),
            regularMarketOpen: regularMarketOpen,
            regularMarketHigh: regularMarketHigh,
            regularMarketLow: regularMarketLow,
            regularMarketPreviousClose: regularMarketPreviousClose,
            postMarketPrice: postMarketPrice,
            postMarketTime: postMarketTimeStamp != nil ? Date(timeIntervalSince1970: TimeInterval(postMarketTimeStamp!)) : nil,
            postMarketChangePercent: postMarketChangePercent,
            preMarketPrice: preMarketPrice,
            preMarketTime: preMarketTimeStamp != nil ? Date(timeIntervalSince1970: TimeInterval(preMarketTimeStamp!)) : nil,
            preMarketChangePercent: preMarketChangePercent
        )
    }
    
    
    /// ticker를 올바른 값으로 업데이트하는 헬퍼 메서드
    internal func withCorrectTicker(_ ticker: YFTicker) -> YFQuote {
        return YFQuote(
            ticker: ticker,
            regularMarketPrice: self.regularMarketPrice,
            regularMarketVolume: self.regularMarketVolume,
            marketCap: self.marketCap,
            shortName: self.shortName,
            regularMarketTime: self.regularMarketTime,
            regularMarketOpen: self.regularMarketOpen,
            regularMarketHigh: self.regularMarketHigh,
            regularMarketLow: self.regularMarketLow,
            regularMarketPreviousClose: self.regularMarketPreviousClose,
            postMarketPrice: self.postMarketPrice,
            postMarketTime: self.postMarketTime,
            postMarketChangePercent: self.postMarketChangePercent,
            preMarketPrice: self.preMarketPrice,
            preMarketTime: self.preMarketTime,
            preMarketChangePercent: self.preMarketChangePercent
        )
    }
    
    /// 에러 CodingKeys
    private enum ErrorKeys: String, CodingKey {
        case code, description
    }
}

