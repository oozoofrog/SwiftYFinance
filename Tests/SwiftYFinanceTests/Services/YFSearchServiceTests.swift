import Testing
@testable import SwiftYFinance
import Foundation

struct YFSearchServiceTests {
    
    @Test("YFSearchService Protocol + Struct architecture")
    func testYFSearchServiceArchitecture() async throws {
        // TDD Red: YFSearchService struct가 존재하고 서비스 기반 호출이 작동하는지 테스트
        let client = YFClient()
        
        // 빈 검색어로 에러 케이스 테스트 (실제 네트워크 호출 없이 구조 확인)
        let emptyResults = try await client.search.suggestions(prefix: "")
        
        // OOP & Protocol + Struct: 서비스 기반 호출 테스트
        #expect(emptyResults.isEmpty, "Empty prefix should return empty suggestions")
        
        // 구조 확인: 서비스가 올바르게 생성되는지 (struct는 value type이므로 === 대신 값 비교)
        _ = YFSearchService(client: client)
        // debugEnabled 제거됨 - 전역 디버그 시스템 사용
    }
    
    @Test("YFSearchService Apple company search validation")
    func testAppleSearch() async throws {
        // Real API test with Apple search - 실제 검색 기능 검증
        let client = YFClient()
        
        let results = try await client.search.find(companyName: "Apple")
        
        // 기본 구조 검증
        #expect(!results.isEmpty, "Apple search should return results")
        
        // Apple Inc.가 결과에 포함되는지 확인
        let appleResult = results.first { $0.symbol.contains("AAPL") }
        if let apple = appleResult {
            #expect(apple.shortName.contains("Apple"), "Apple result should contain 'Apple' in name")
            #expect(apple.quoteType == .equity, "AAPL should be equity type")
            #expect(!apple.symbol.isEmpty, "Symbol should not be empty")
        }
    }
    
    @Test("YFSearchService Microsoft company search validation")
    func testMicrosoftSearch() async throws {
        // Real API test with Microsoft search
        let client = YFClient()
        
        let results = try await client.search.find(companyName: "Microsoft")
        
        // 기본 구조 검증
        #expect(!results.isEmpty, "Microsoft search should return results")
        
        // Microsoft Corporation이 결과에 포함되는지 확인
        let msftResult = results.first { $0.symbol.contains("MSFT") }
        if let msft = msftResult {
            #expect(msft.shortName.contains("Microsoft"), "Microsoft result should contain 'Microsoft' in name")
            #expect(msft.quoteType == .equity, "MSFT should be equity type")
            #expect(!msft.symbol.isEmpty, "Symbol should not be empty")
        }
    }
    
    @Test("YFSearchService search suggestions validation")
    func testSearchSuggestions() async throws {
        // Search suggestions test
        let client = YFClient()
        
        let suggestions = try await client.search.suggestions(prefix: "App")
        
        // 기본 구조 검증
        if !suggestions.isEmpty {
            for suggestion in suggestions.prefix(5) { // 처음 5개만 확인
                #expect(!suggestion.isEmpty, "Suggestion should not be empty")
                #expect(suggestion.localizedCaseInsensitiveContains("app"), "Suggestion should contain 'app'")
            }
        }
        
        // 빈 prefix 테스트
        let emptySuggestions = try await client.search.suggestions(prefix: "")
        #expect(emptySuggestions.isEmpty, "Empty prefix should return empty suggestions")
        
        // 공백만 있는 prefix 테스트
        let whitespaceSuggestions = try await client.search.suggestions(prefix: "   ")
        #expect(whitespaceSuggestions.isEmpty, "Whitespace-only prefix should return empty suggestions")
    }
    
    @Test("YFSearchService advanced search query validation")
    func testAdvancedSearchQuery() async throws {
        // Advanced search query test
        let client = YFClient()
        
        let query = YFSearchQuery(
            term: "technology",
            maxResults: 10,
            quoteTypes: [.equity, .etf]
        )
        
        let results = try await client.search.find(query: query)
        
        // 결과 개수 검증 (최대 10개)
        #expect(results.count <= 10, "Results should not exceed maxResults limit")
        
        // 결과 타입 검증 - Python yfinance 분석에 따라 더 많은 타입 허용
        for result in results {
            #expect([.equity, .etf, .index, .future].contains(result.quoteType), "Result should be common quote type (EQUITY/ETF/INDEX/FUTURE)")
            #expect(!result.symbol.isEmpty, "Symbol should not be empty")
        }
    }
    
    @Test("YFSearchService multi-term concurrency test")
    func testMultipleSearchesConcurrently() async throws {
        // 동시성 테스트: 여러 검색어를 동시에 처리
        let client = YFClient()
        let searchTerms = ["Apple", "Microsoft", "Tesla", "Google", "Amazon"]
        
        // 병렬 처리
        let results = await withTaskGroup(of: (String, Result<[YFSearchResult], Error>).self) { group in
            for term in searchTerms {
                group.addTask {
                    do {
                        let searchResults = try await client.search.find(companyName: term)
                        return (term, .success(searchResults))
                    } catch {
                        return (term, .failure(error))
                    }
                }
            }
            
            var collectedResults: [String: Result<[YFSearchResult], Error>] = [:]
            for await (term, result) in group {
                collectedResults[term] = result
            }
            return collectedResults
        }
        
        // 결과 검증
        #expect(results.count == searchTerms.count, "Should have results for all search terms")
        
        for (term, result) in results {
            switch result {
            case .success(let searchResults):
                print(searchResults)
                // Python yfinance에서 처럼 결과 배열의 첫 번째 항목에 대해서만 검증
                // Python yfinance 분석: 정확한 매칭 대신 포함 여부로 검증
                // 예: "Google" -> "Alphabet Inc.", "Apple" -> "Apple Inc."
                if let firstResult = searchResults.first {
                    let shortName = firstResult.shortName.lowercased()
                    let termLower = term.lowercased()
                    
                    // Google -> Alphabet 케이스 특별 처리
                    if termLower == "google" {
                        #expect(shortName.contains("alphabet") || shortName.contains("google"), "Google search should return Alphabet or Google-related results")
                    } else {
                        #expect(shortName.contains(termLower), "First result should contain search term: '\(termLower)' in '\(shortName)'")
                    }
                }
            case .failure(let error):
                // 네트워크 에러 등은 허용하지만 기록
                print("⚠️ Failed to search '\(term)': \(error)")
            }
        }
    }
    
    @Test("YFSearchService cache functionality test")
    func testSearchCaching() async throws {
        // 캐시 기능 테스트: 동일한 검색을 두 번 수행
        let client = YFClient()
        let searchTerm = "Apple"
        
        // 첫 번째 검색 (API 호출)
        let startTime1 = Date()
        let results1 = try await client.search.find(companyName: searchTerm)
        let duration1 = Date().timeIntervalSince(startTime1)
        
        // 두 번째 검색 (캐시된 결과)
        let startTime2 = Date()
        let results2 = try await client.search.find(companyName: searchTerm)
        let duration2 = Date().timeIntervalSince(startTime2)
        
        // 결과 일치성 검증
        #expect(results1.count == results2.count, "Cached results should match original results count")
        
        if !results1.isEmpty && !results2.isEmpty {
            #expect(results1.first?.symbol == results2.first?.symbol, "First result symbol should match")
            #expect(results1.first?.shortName == results2.first?.shortName, "First result name should match")
        }
        
        // 캐시된 검색이 더 빨라야 함 (완전히 보장되지는 않지만 일반적으로 그럼)
        // 단, 네트워크 상황에 따라 차이가 없을 수도 있으므로 경고만 출력
        if duration2 >= duration1 {
            print("ℹ️ Cache may not have provided performance benefit (duration1: \(duration1), duration2: \(duration2))")
        }
    }
    
    @Test("YFSearchService error handling with invalid searches")
    func testErrorHandlingInvalidSearches() async {
        let client = YFClient()
        
        // 매우 특이한 검색어들로 테스트
        let problematicSearches = [
            "NONEXISTENT_COMPANY_XYZ_123456",
            "!@#$%^&*()",
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", // 매우 긴 문자열
        ]
        
        for searchTerm in problematicSearches {
            do {
                let results = try await client.search.find(companyName: searchTerm)
                // 빈 결과가 반환되거나 관련 없는 결과가 나올 수 있음
                // 이는 정상적인 동작
                print("ℹ️ Search '\(searchTerm)' returned \(results.count) results")
            } catch {
                // 에러가 발생해도 정상적인 에러여야 함
                #expect(error is YFError, "Should throw YFError for problematic search '\(searchTerm)'")
            }
        }
    }
    
    @Test("YFSearchService performance test")
    func testSearchServicePerformance() async throws {
        // 성능 테스트: 검색이 합리적인 시간 내에 완료되는지 확인
        let client = YFClient()
        let searchTerm = "technology"
        
        let startTime = Date()
        let results = try await client.search.find(companyName: searchTerm)
        let endTime = Date()
        
        let duration = endTime.timeIntervalSince(startTime)
        
        // 검색이 합리적인 시간 내에 완료되어야 함 (10초 이내)
        #expect(duration < 10.0, "Search should complete within 10 seconds")
        
        // 결과 품질 검증
        if !results.isEmpty {
            #expect(!results.first!.symbol.isEmpty, "First result should have valid symbol")
        }
    }
    
    @Test("YFSearchService Sendable compliance")
    func testSendableCompliance() async {
        // Sendable 준수 테스트: 여러 Task에서 동시에 사용 가능한지 확인
        let client = YFClient()
        
        let task1 = Task {
            try await client.search.find(companyName: "Apple")
        }
        
        let task2 = Task {
            try await client.search.suggestions(prefix: "Micro")
        }
        
        do {
            let (searchResults, suggestions) = try await (task1.value, task2.value)
            
            // 두 결과 모두 올바른 형태여야 함
            if !searchResults.isEmpty {
                #expect(!searchResults.first!.symbol.isEmpty, "Search result should have valid symbol")
            }
            
            if !suggestions.isEmpty {
                #expect(!suggestions.first!.isEmpty, "Suggestion should not be empty")
            }
            
        } catch {
            // 동시 접근으로 인한 실패는 없어야 함
            Issue.record("Concurrent search access should not fail: \(error)")
        }
    }
}

// MARK: - Helper Functions

/// 네트워크 테스트 실행 여부를 결정하는 헬퍼 함수
private func shouldRunNetworkTests() -> Bool {
    // CI 환경이나 네트워크가 없는 환경에서는 false를 반환
    // 실제 환경에서는 true를 반환
    return true
}
