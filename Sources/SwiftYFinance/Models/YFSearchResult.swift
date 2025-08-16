import Foundation

/// Yahoo Finance 검색 결과를 나타내는 모델
///
/// 회사명이나 심볼로 검색했을 때 반환되는 개별 검색 결과를 표현합니다.
/// 검색 점수에 따라 관련도가 높은 순서로 정렬됩니다.
///
/// ## 사용 예시
/// ```swift
/// let client = YFClient()
/// let results = try await client.search(companyName: "Apple")
/// 
/// for result in results {
///     print("\(result.symbol): \(result.shortName)")
///     let ticker = try result.toTicker()
/// }
/// ```
public struct YFSearchResult: Codable, Sendable {
    /// 종목 심볼 (예: "AAPL")
    public let symbol: String
    
    /// 짧은 회사명 (예: "Apple Inc.")
    public let shortName: String
    
    /// 전체 회사명 (예: "Apple Inc.") - 옵셔널
    public let longName: String?
    
    /// 거래소명 (예: "NASDAQ")
    public let exchange: String
    
    /// 종목 유형
    public let quoteType: YFQuoteType
    
    /// 검색 관련도 점수 (0.0 ~ 1.0)
    public let score: Double
    
    /// 검색 결과를 YFTicker 객체로 변환
    /// - Returns: 종목 심볼로 생성된 YFTicker 인스턴스
    /// - Throws: 유효하지 않은 심볼인 경우 YFError.invalidSymbol
    public func toTicker() throws -> YFTicker {
        return try YFTicker(symbol: symbol)
    }
    
    /// 초기화
    /// - Parameters:
    ///   - symbol: 종목 심볼
    ///   - shortName: 짧은 회사명
    ///   - longName: 전체 회사명 (옵셔널)
    ///   - exchange: 거래소명
    ///   - quoteType: 종목 유형
    ///   - score: 검색 관련도 점수
    public init(
        symbol: String,
        shortName: String,
        longName: String?,
        exchange: String,
        quoteType: YFQuoteType,
        score: Double
    ) {
        self.symbol = symbol
        self.shortName = shortName
        self.longName = longName
        self.exchange = exchange
        self.quoteType = quoteType
        self.score = score
    }
}

// MARK: - Equatable
extension YFSearchResult: Equatable {
    public static func == (lhs: YFSearchResult, rhs: YFSearchResult) -> Bool {
        return lhs.symbol == rhs.symbol &&
               lhs.shortName == rhs.shortName &&
               lhs.longName == rhs.longName &&
               lhs.exchange == rhs.exchange &&
               lhs.quoteType == rhs.quoteType &&
               abs(lhs.score - rhs.score) < 0.0001
    }
}

// MARK: - Hashable
extension YFSearchResult: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(symbol)
        hasher.combine(shortName)
        hasher.combine(longName)
        hasher.combine(exchange)
        hasher.combine(quoteType)
        hasher.combine(score)
    }
}