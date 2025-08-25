import Foundation

// MARK: - Yahoo Finance Quote Metadata

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