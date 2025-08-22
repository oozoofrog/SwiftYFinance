import Foundation

/// Yahoo Finance 종목 유형을 나타내는 열거형
///
/// 검색 및 필터링에 사용되는 다양한 금융 상품 유형을 정의합니다.
/// Yahoo Finance API에서 사용하는 quoteType 필드와 호환됩니다.
public enum YFQuoteType: String, CaseIterable, Codable, Sendable {
    /// 주식 (Equity)
    case equity = "EQUITY"
    
    /// 상장지수펀드 (Exchange Traded Fund)
    case etf = "ETF"
    
    /// 뮤추얼펀드 (Mutual Fund)
    case mutualFund = "MUTUALFUND"
    
    /// 지수 (Index)
    case index = "INDEX"
    
    /// 선물 (Future)
    case future = "FUTURE"
    
    /// 통화 (Currency)
    case currency = "CURRENCY"
    
    /// 암호화폐 (Cryptocurrency)
    case cryptocurrency = "CRYPTOCURRENCY"
    
    /// 옵션 (Option)
    case option = "OPTION"
}

// MARK: - Equatable, Hashable
extension YFQuoteType: Equatable, Hashable {}

// MARK: - CustomStringConvertible
extension YFQuoteType: CustomStringConvertible {
    /// 사용자 친화적인 설명
    public var description: String {
        switch self {
        case .equity:
            return "주식"
        case .etf:
            return "ETF"
        case .mutualFund:
            return "뮤추얼펀드"
        case .index:
            return "지수"
        case .future:
            return "선물"
        case .currency:
            return "통화"
        case .cryptocurrency:
            return "암호화폐"
        case .option:
            return "옵션"
        }
    }
}