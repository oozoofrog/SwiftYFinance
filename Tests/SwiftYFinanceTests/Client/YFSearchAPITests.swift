import Foundation
import Testing
@testable import SwiftYFinance

struct YFSearchAPITests {
    
    @Test("search(companyName:) 메서드 시그니처 확인")
    func testSearchByCompanyNameMethodExists() throws {
        // Green: YFClient에 search(companyName:) 메서드가 존재하는지 확인
        let client = YFClient()
        
        // 컴파일 타임에 메서드 시그니처가 올바른지 확인
        let _: (String) async throws -> [YFSearchResult] = client.search(companyName:)
        
        #expect(true)
    }
    
    @Test("search(query:) 메서드 시그니처 확인")
    func testSearchByQuery() throws {
        // Green: YFClient에 search(query:) 메서드가 존재하는지 확인
        let client = YFClient()
        
        // 컴파일 타임에 메서드 시그니처가 올바른지 확인
        let _: (YFSearchQuery) async throws -> [YFSearchResult] = client.search(query:)
        
        #expect(true)
    }
    
    @Test("searchSuggestions(prefix:) 메서드 시그니처 확인")
    func testSearchSuggestions() throws {
        // Green: YFClient에 searchSuggestions(prefix:) 메서드가 존재하는지 확인
        let client = YFClient()
        
        // 컴파일 타임에 메서드 시그니처가 올바른지 확인
        let _: (String) async throws -> [String] = client.searchSuggestions(prefix:)
        
        #expect(true)
    }
    
    @Test("YFSearchQuery 유효성 검사 로직")
    func testSearchQueryValidation() throws {
        // Green: YFSearchQuery의 isValid 프로퍼티 테스트
        let validQuery = YFSearchQuery(term: "Apple", maxResults: 10)
        #expect(validQuery.isValid == true)
        
        let emptyQuery = YFSearchQuery(term: "", maxResults: 10)
        #expect(emptyQuery.isValid == false)
        
        let invalidMaxQuery = YFSearchQuery(term: "Apple", maxResults: 0)
        #expect(invalidMaxQuery.isValid == false)
    }
}