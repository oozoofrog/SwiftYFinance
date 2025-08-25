import Foundation

// MARK: - Yahoo Finance Quote Market Data

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