import Foundation

// MARK: - Yahoo Finance Quote Basic Info

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