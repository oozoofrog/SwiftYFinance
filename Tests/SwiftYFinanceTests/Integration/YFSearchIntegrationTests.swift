import Testing
import Foundation
@testable import SwiftYFinance

/// 검색 기능 통합 테스트
///
/// 실제 Yahoo Finance API와의 통합을 검증하는 테스트입니다.
/// 네트워크 연결이 필요한 테스트로, 실제 환경에서만 실행됩니다.
@Suite("Search Integration Tests")
struct YFSearchIntegrationTests {
    
    // MARK: - 기본 검색 기능 검증
    
    /// Apple 검색 기능 검증
    @Test("Apple 검색 성공", .enabled(if: shouldRunNetworkTests()))
    func testAppleSearch() async throws {
        let client = YFClient()
        
        let results = try await client.search.find(companyName: "Apple")
        
        #expect(!results.isEmpty)
        
        // Apple Inc.가 결과에 포함되어야 함
        let appleResult = results.first { $0.symbol.contains("AAPL") }
        #expect(appleResult != nil)
        #expect(appleResult?.shortName.contains("Apple") == true)
        #expect(appleResult?.quoteType == .equity)
    }
    
    /// Microsoft 검색 기능 검증
    @Test("Microsoft 검색 성공", .enabled(if: shouldRunNetworkTests()))
    func testMicrosoftSearch() async throws {
        let client = YFClient()
        
        let results = try await client.search.find(companyName: "Microsoft")
        
        #expect(!results.isEmpty)
        
        // Microsoft Corporation이 결과에 포함되어야 함
        let msftResult = results.first { $0.symbol.contains("MSFT") }
        #expect(msftResult != nil)
        #expect(msftResult?.shortName.contains("Microsoft") == true)
        #expect(msftResult?.quoteType == .equity)
    }
    
    /// Tesla 검색 기능 검증
    @Test("Tesla 검색 성공", .enabled(if: shouldRunNetworkTests()))
    func testTeslaSearch() async throws {
        let client = YFClient()
        
        let results = try await client.search.find(companyName: "Tesla")
        
        #expect(!results.isEmpty)
        
        // Tesla Inc.가 결과에 포함되어야 함
        let teslaResult = results.first { $0.symbol.contains("TSLA") }
        #expect(teslaResult != nil)
        #expect(teslaResult?.shortName.contains("Tesla") == true)
        #expect(teslaResult?.quoteType == .equity)
    }
    
    // MARK: - 고급 검색 기능 검증
    
    /// 제한된 결과 수 검증
    @Test("결과 수 제한 검증", .enabled(if: shouldRunNetworkTests()))
    func testLimitedResults() async throws {
        let client = YFClient()
        
        let query = YFSearchQuery(
            term: "tech",
            maxResults: 5,
            quoteTypes: [.equity]
        )
        
        let results = try await client.search.find(query: query)
        
        // 최대 5개 결과만 반환되어야 함
        #expect(results.count <= 5)
        #expect(!results.isEmpty)
        
        // 모든 결과가 equity 타입이어야 함
        for result in results {
            #expect(result.quoteType == .equity)
        }
    }
    
    /// ETF 필터링 검증
    @Test("ETF 필터링 검증", .enabled(if: shouldRunNetworkTests()))
    func testETFFiltering() async throws {
        let client = YFClient()
        
        let query = YFSearchQuery(
            term: "SPY",
            maxResults: 10,
            quoteTypes: [.etf]
        )
        
        let results = try await client.search.find(query: query)
        
        #expect(!results.isEmpty)
        
        // SPY ETF가 결과에 포함되어야 함
        let spyResult = results.first { $0.symbol.contains("SPY") }
        #expect(spyResult != nil)
        
        // 결과 중 ETF가 포함되어야 함 (완전 필터링은 Yahoo API 의존적)
        let hasETF = results.contains { $0.quoteType == .etf }
        #expect(hasETF)
    }
    
    // MARK: - 자동완성 기능 검증
    
    /// 자동완성 제안 검증
    @Test("자동완성 제안 검증", .enabled(if: shouldRunNetworkTests()))
    func testSearchSuggestions() async throws {
        let client = YFClient()
        
        let suggestions = try await client.search.suggestions(prefix: "App")
        
        #expect(!suggestions.isEmpty)
        
        // Apple Inc.가 제안에 포함되어야 함
        let hasApple = suggestions.contains { $0.contains("Apple") }
        #expect(hasApple)
    }
    
    /// 빈 prefix 처리 검증
    @Test("빈 prefix 처리")
    func testEmptyPrefixSuggestions() async throws {
        let client = YFClient()
        
        let emptySuggestions = try await client.search.suggestions(prefix: "")
        let whitespaceSuggestions = try await client.search.suggestions(prefix: "   ")
        
        #expect(emptySuggestions.isEmpty)
        #expect(whitespaceSuggestions.isEmpty)
    }
    
    // MARK: - toTicker 변환 검증
    
    /// 검색 결과를 Ticker로 변환 검증
    @Test("검색 결과 Ticker 변환", .enabled(if: shouldRunNetworkTests()))
    func testSearchResultToTicker() async throws {
        let client = YFClient()
        
        let results = try await client.search.find(companyName: "Apple")
        
        #expect(!results.isEmpty)
        
        let appleResult = results.first { $0.symbol.contains("AAPL") }
        #expect(appleResult != nil)
        
        // Ticker로 변환 가능해야 함
        let ticker = try appleResult!.toTicker()
        #expect(ticker.symbol == appleResult!.symbol)
    }
    
    // MARK: - 캐싱 동작 검증
    
    /// 캐시 동작 검증
    @Test("검색 결과 캐싱 동작", .enabled(if: shouldRunNetworkTests()))
    func testSearchCaching() async throws {
        let client = YFClient()
        
        // 캐시 초기화
        await YFSearchCache.shared.clearAll()
        
        // 첫 번째 검색
        let startTime1 = Date()
        let results1 = try await client.search.find(companyName: "AAPL")
        let duration1 = Date().timeIntervalSince(startTime1)
        
        #expect(!results1.isEmpty)
        
        // 두 번째 검색 (캐시된 결과)
        let startTime2 = Date()
        let results2 = try await client.search.find(companyName: "AAPL")
        let duration2 = Date().timeIntervalSince(startTime2)
        
        #expect(!results2.isEmpty)
        #expect(results1.count == results2.count)
        
        // 캐시된 검색이 더 빨라야 함
        #expect(duration2 < duration1)
        
        // 캐시 통계 확인
        let stats = await YFSearchCache.shared.getStats()
        #expect(stats.totalItems > 0)
    }
    
    // MARK: - 에러 처리 검증
    
    /// 무효한 검색어 에러 검증
    @Test("무효한 검색어 에러")
    func testInvalidSearchQuery() async throws {
        let client = YFClient()
        
        do {
            let query = YFSearchQuery(term: "", maxResults: 10)
            _ = try await client.search.find(query: query)
            #expect(Bool(false), "빈 검색어로 검색이 성공하면 안됨")
        } catch let error as YFError {
            switch error {
            case .invalidParameter:
                // 예상된 에러
                break
            default:
                #expect(Bool(false), "예상하지 않은 에러 타입: \(error)")
            }
        }
    }
}

// MARK: - 헬퍼 함수

/// 네트워크 테스트 실행 여부 결정
/// 
/// 환경 변수나 시스템 상태에 따라 네트워크 테스트 실행을 제어합니다.
/// CI 환경이나 네트워크가 없는 환경에서는 스킵할 수 있습니다.
private func shouldRunNetworkTests() -> Bool {
    // 환경 변수로 제어
    if let skipNetwork = ProcessInfo.processInfo.environment["SKIP_NETWORK_TESTS"] {
        return skipNetwork.lowercased() != "true"
    }
    
    // 기본적으로 실행
    return true
}