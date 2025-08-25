import Foundation

// MARK: - Yahoo Finance Quote Extended Hours Data

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