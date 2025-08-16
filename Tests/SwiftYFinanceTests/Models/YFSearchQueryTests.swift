import Foundation
import Testing
@testable import SwiftYFinance

struct YFSearchQueryTests {
    
    @Test("YFSearchQuery 기본값 테스트")
    func testYFSearchQueryDefaultValues() throws {
        // Red: YFSearchQuery 기본값 초기화 테스트
        let query = YFSearchQuery(term: "Apple")
        
        #expect(query.term == "Apple")
        #expect(query.maxResults == 10) // 기본값
        #expect(query.quoteTypes.isEmpty) // 기본값: 빈 배열
    }
    
    @Test("YFSearchQuery 빈 검색어 처리")
    func testYFSearchQueryEmptyTerm() throws {
        // Red: 빈 검색어 처리 테스트
        let query = YFSearchQuery(term: "")
        
        #expect(query.term == "")
        #expect(query.maxResults == 10)
        #expect(query.quoteTypes.isEmpty)
    }
    
    @Test("YFSearchQuery maxResults 유효성 검사")
    func testYFSearchQueryMaxResultsValidation() throws {
        // Red: maxResults 값 범위 테스트
        let validQuery = YFSearchQuery(term: "Microsoft", maxResults: 5)
        #expect(validQuery.maxResults == 5)
        
        let zeroQuery = YFSearchQuery(term: "Tesla", maxResults: 0)
        #expect(zeroQuery.maxResults == 0)
        
        let largeQuery = YFSearchQuery(term: "Google", maxResults: 100)
        #expect(largeQuery.maxResults == 100)
    }
    
    @Test("YFSearchQuery 커스텀 값 테스트")
    func testYFSearchQueryCustomValues() throws {
        // Red: 모든 커스텀 값 설정 테스트
        let customQuery = YFSearchQuery(
            term: "technology",
            maxResults: 25,
            quoteTypes: [.equity, .etf, .mutualFund]
        )
        
        #expect(customQuery.term == "technology")
        #expect(customQuery.maxResults == 25)
        #expect(customQuery.quoteTypes.count == 3)
        #expect(customQuery.quoteTypes.contains(.equity))
        #expect(customQuery.quoteTypes.contains(.etf))
        #expect(customQuery.quoteTypes.contains(.mutualFund))
    }
    
    @Test("YFSearchQuery 단일 quoteType 필터")
    func testYFSearchQuerySingleQuoteType() throws {
        // Red: 단일 종목 유형 필터 테스트
        let equityQuery = YFSearchQuery(
            term: "bank",
            maxResults: 15,
            quoteTypes: [.equity]
        )
        
        #expect(equityQuery.quoteTypes.count == 1)
        #expect(equityQuery.quoteTypes.first == .equity)
    }
    
    @Test("YFSearchQuery 유효성 검사")
    func testYFSearchQueryValidation() throws {
        // Red: isValid 프로퍼티 테스트
        let validQuery = YFSearchQuery(term: "Apple", maxResults: 10)
        #expect(validQuery.isValid == true)
        
        let emptyTermQuery = YFSearchQuery(term: "", maxResults: 10)
        #expect(emptyTermQuery.isValid == false)
        
        let whitespaceQuery = YFSearchQuery(term: "   ", maxResults: 10)
        #expect(whitespaceQuery.isValid == false)
        
        let zeroResultQuery = YFSearchQuery(term: "Tesla", maxResults: 0)
        #expect(zeroResultQuery.isValid == false)
    }
    
    @Test("YFSearchQuery URL 파라미터 변환")
    func testYFSearchQueryURLParameters() throws {
        // Red: toURLParameters() 메서드 테스트
        let basicQuery = YFSearchQuery(term: "Apple")
        let basicParams = basicQuery.toURLParameters()
        
        #expect(basicParams["q"] == "Apple")
        #expect(basicParams["quotesCount"] == "10")
        #expect(basicParams["quotesQueryId"] == nil)
        
        let advancedQuery = YFSearchQuery(
            term: "tech",
            maxResults: 20,
            quoteTypes: [.equity, .etf]
        )
        let advancedParams = advancedQuery.toURLParameters()
        
        #expect(advancedParams["q"] == "tech")
        #expect(advancedParams["quotesCount"] == "20")
        #expect(advancedParams["quotesQueryId"] == "EQUITY,ETF")
    }
}