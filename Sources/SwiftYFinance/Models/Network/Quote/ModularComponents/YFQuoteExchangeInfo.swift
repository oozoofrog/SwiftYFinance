import Foundation

// MARK: - Yahoo Finance Quote Exchange Info

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