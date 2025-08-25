import Foundation

// MARK: - Yahoo Finance Quote Volume Info

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