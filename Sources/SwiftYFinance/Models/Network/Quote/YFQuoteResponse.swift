import Foundation

// MARK: - Yahoo Finance Quote Response

/// Yahoo Finance query1 quote API 응답 래퍼
public struct YFQuoteResponse: Decodable, Sendable {
    
    /// Quote 데이터 결과 배열
    public let result: [YFQuote]?
    
    /// API 에러 메시지
    public let error: String?
    
    // MARK: - Custom Decoding
    
    private enum CodingKeys: String, CodingKey {
        case quoteResponse
    }
    
    private enum QuoteResponseKeys: String, CodingKey {
        case result
        case error
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let quoteResponseContainer = try container.nestedContainer(keyedBy: QuoteResponseKeys.self, forKey: .quoteResponse)
        
        self.result = try quoteResponseContainer.decodeIfPresent([YFQuote].self, forKey: .result)
        self.error = try quoteResponseContainer.decodeIfPresent(String.self, forKey: .error)
    }
}