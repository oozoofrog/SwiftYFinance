import Foundation

/// Yahoo Finance 검색 쿼리를 구성하는 모델
///
/// 검색어, 결과 개수 제한, 종목 유형 필터 등 다양한 검색 조건을 설정할 수 있습니다.
/// 기본값들이 설정되어 있어 간단한 검색부터 고급 검색까지 지원합니다.
///
/// ## 사용 예시
/// ```swift
/// // 기본 검색
/// let simpleQuery = YFSearchQuery(term: "Apple")
/// 
/// // 고급 검색
/// let advancedQuery = YFSearchQuery(
///     term: "tech", 
///     maxResults: 20,
///     quoteTypes: [.equity, .etf]
/// )
/// ```
public struct YFSearchQuery: Sendable {
    /// 검색어
    public let term: String
    
    /// 최대 결과 개수 (기본값: 10)
    public let maxResults: Int
    
    /// 필터링할 종목 유형들 (기본값: 빈 배열 - 모든 유형)
    public let quoteTypes: [YFQuoteType]
    
    /// 초기화
    /// - Parameters:
    ///   - term: 검색어
    ///   - maxResults: 최대 결과 개수 (기본값: 10)
    ///   - quoteTypes: 필터링할 종목 유형들 (기본값: 빈 배열)
    public init(
        term: String,
        maxResults: Int = 10,
        quoteTypes: [YFQuoteType] = []
    ) {
        self.term = term
        self.maxResults = maxResults
        self.quoteTypes = quoteTypes
    }
}

// MARK: - Equatable
extension YFSearchQuery: Equatable {
    public static func == (lhs: YFSearchQuery, rhs: YFSearchQuery) -> Bool {
        return lhs.term == rhs.term &&
               lhs.maxResults == rhs.maxResults &&
               lhs.quoteTypes == rhs.quoteTypes
    }
}

// MARK: - Hashable
extension YFSearchQuery: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(term)
        hasher.combine(maxResults)
        hasher.combine(quoteTypes)
    }
}

// MARK: - Validation
extension YFSearchQuery {
    /// 검색 쿼리의 유효성을 검사합니다
    /// - Returns: 유효한 쿼리인 경우 true
    public var isValid: Bool {
        return !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               maxResults > 0
    }
    
    /// URL 쿼리 파라미터로 변환합니다
    /// - Returns: URL 쿼리 파라미터 딕셔너리
    public func toURLParameters() -> [String: String] {
        var parameters: [String: String] = [
            "q": term,
            "quotesCount": String(maxResults)
        ]
        
        if !quoteTypes.isEmpty {
            let typeStrings = quoteTypes.map { $0.rawValue }
            parameters["quotesQueryId"] = typeStrings.joined(separator: ",")
        }
        
        return parameters
    }
}