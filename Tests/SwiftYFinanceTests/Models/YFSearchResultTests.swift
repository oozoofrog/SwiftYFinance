import Foundation
import Testing
@testable import SwiftYFinance

struct YFSearchResultTests {
    
    @Test("YFSearchResult 기본 초기화")
    func testYFSearchResultBasicInitialization() throws {
        // Red: YFSearchResult가 아직 존재하지 않으므로 이 테스트는 실패할 것
        let searchResult = YFSearchResult(
            symbol: "AAPL",
            shortName: "Apple Inc.",
            longName: "Apple Inc.",
            exchange: "NASDAQ",
            quoteType: .equity,
            score: 0.95
        )
        
        #expect(searchResult.symbol == "AAPL")
        #expect(searchResult.shortName == "Apple Inc.")
        #expect(searchResult.longName == "Apple Inc.")
        #expect(searchResult.exchange == "NASDAQ")
        #expect(searchResult.quoteType == .equity)
        #expect(searchResult.score == 0.95)
    }
    
    @Test("YFSearchResult optional longName 초기화")
    func testYFSearchResultOptionalLongName() throws {
        // Red: longName이 nil인 경우 테스트
        let searchResult = YFSearchResult(
            symbol: "TSLA",
            shortName: "Tesla",
            longName: nil,
            exchange: "NASDAQ",
            quoteType: .equity,
            score: 0.88
        )
        
        #expect(searchResult.symbol == "TSLA")
        #expect(searchResult.shortName == "Tesla")
        #expect(searchResult.longName == nil)
        #expect(searchResult.exchange == "NASDAQ")
        #expect(searchResult.quoteType == .equity)
        #expect(searchResult.score == 0.88)
    }
    
    @Test("YFSearchResult Codable 지원")
    func testYFSearchResultCodable() throws {
        // Red: Codable 프로토콜 지원 테스트
        let original = YFSearchResult(
            symbol: "MSFT",
            shortName: "Microsoft",
            longName: "Microsoft Corporation",
            exchange: "NASDAQ",
            quoteType: .equity,
            score: 0.92
        )
        
        // JSON 인코딩
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        // JSON 디코딩
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(YFSearchResult.self, from: data)
        
        #expect(decoded.symbol == original.symbol)
        #expect(decoded.shortName == original.shortName)
        #expect(decoded.longName == original.longName)
        #expect(decoded.exchange == original.exchange)
        #expect(decoded.quoteType == original.quoteType)
        #expect(decoded.score == original.score)
    }
}