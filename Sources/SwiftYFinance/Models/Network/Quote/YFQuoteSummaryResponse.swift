import Foundation

// MARK: - Yahoo Finance Quote Summary Response

/// Yahoo Finance quoteSummary API 최상위 응답 래퍼
public struct YFQuoteSummaryResponse: Decodable, Sendable {
    
    /// quoteSummary API 데이터 컨테이너
    public let quoteSummary: YFQuoteSummary?
}