import Foundation

// MARK: - Yahoo Finance Quote Summary

/// quoteSummary API 응답 데이터 컨테이너
/// 
/// 성공 시 result 배열, 실패 시 error 메시지를 포함합니다.
public struct YFQuoteSummary: Decodable, Sendable {
    
    /// Quote 데이터 결과 배열
    public let result: [YFQuoteResult]?
    
    /// API 에러 메시지
    public let error: String?
}