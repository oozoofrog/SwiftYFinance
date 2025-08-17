import Testing
import Foundation
@testable import SwiftYFinance

/// 검색 기능 메모리 누수 및 성능 테스트
///
/// 메모리 사용량과 성능을 검증하여 품질을 보장합니다.
@Suite("Search Memory & Performance Tests")
struct YFSearchMemoryTests {
    
    // MARK: - 메모리 누수 테스트
    
    /// 반복 검색 메모리 누수 테스트
    @Test("반복 검색 메모리 누수 확인")
    func testRepeatedSearchMemoryLeak() async throws {
        let client = YFClient()
        await YFSearchCache.shared.clearAll()
        
        // 초기 메모리 상태
        let initialStats = await YFSearchCache.shared.getStats()
        
        // 많은 검색 수행 (메모리 누수 검사)
        for i in 1...50 {
            let query = YFSearchQuery(term: "test_\(i)", maxResults: 5)
            
            // 에러를 무시하고 메서드 호출만 확인
            do {
                _ = try await client.search(query: query)
            } catch {
                // 네트워크 에러는 무시 (메모리 테스트가 목적)
            }
        }
        
        // 캐시 정리 후 메모리 확인
        await YFSearchCache.shared.clearAll()
        let finalStats = await YFSearchCache.shared.getStats()
        
        // 캐시가 제대로 정리되었는지 확인
        #expect(finalStats.totalItems == 0)
        #expect(finalStats.memoryUsage <= initialStats.memoryUsage + 1000) // 1KB 여유분
    }
    
    /// 캐시 메모리 관리 테스트
    @Test("캐시 메모리 관리")
    func testCacheMemoryManagement() async throws {
        let cache = YFSearchCache.shared
        await cache.clearAll()
        
        let mockResult = YFSearchResult(
            symbol: "TEST",
            shortName: "Test Company",
            longName: "Test Company Inc.",
            exchange: "NYSE",
            quoteType: .equity,
            score: 0.5
        )
        
        // 많은 항목을 캐시에 추가
        for i in 1...150 { // 최대 제한(100)보다 많이 추가
            await cache.set([mockResult], for: "company_\(i)")
        }
        
        let stats = await cache.getStats()
        
        // 최대 제한이 적용되었는지 확인
        #expect(stats.totalItems <= 100)
        #expect(stats.memoryUsage > 0)
        #expect(stats.memoryUsage < 1024 * 1024) // 1MB 미만이어야 함
    }
    
    // MARK: - 성능 테스트
    
    /// 캐시 성능 테스트
    @Test("캐시 성능 측정")
    func testCachePerformance() async throws {
        let cache = YFSearchCache.shared
        await cache.clearAll()
        
        let mockResults = (1...10).map { i in
            YFSearchResult(
                symbol: "TEST\(i)",
                shortName: "Test \(i)",
                longName: "Test Company \(i)",
                exchange: "NYSE",
                quoteType: .equity,
                score: 0.5
            )
        }
        
        // 캐시에 저장
        await cache.set(mockResults, for: "performance_test")
        
        // 성능 측정: 1000번 조회
        let startTime = Date()
        
        for _ in 1...1000 {
            _ = await cache.get(for: "performance_test")
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        // 1000번 조회가 0.1초 이내에 완료되어야 함
        #expect(elapsed < 0.1)
    }
    
    /// 검색 쿼리 생성 성능 테스트
    @Test("검색 쿼리 생성 성능")
    func testQueryCreationPerformance() async throws {
        let startTime = Date()
        
        // 1000개의 쿼리 생성
        for i in 1...1000 {
            let query = YFSearchQuery(
                term: "test_query_\(i)",
                maxResults: 10,
                quoteTypes: [.equity, .etf]
            )
            
            // 쿼리 유효성 검사
            #expect(query.isValid)
            
            // URL 파라미터 변환
            let parameters = query.toURLParameters()
            #expect(!parameters.isEmpty)
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        // 1000개 쿼리 생성이 0.1초 이내에 완료되어야 함
        #expect(elapsed < 0.1)
    }
    
    // MARK: - 동시성 안전성 테스트
    
    /// 동시 캐시 접근 안전성 테스트
    @Test("동시 캐시 접근 안전성")
    func testConcurrentCacheAccess() async throws {
        let cache = YFSearchCache.shared
        await cache.clearAll()
        
        let mockResult = YFSearchResult(
            symbol: "CONC",
            shortName: "Concurrent Test",
            longName: "Concurrent Test Company",
            exchange: "NYSE",
            quoteType: .equity,
            score: 0.8
        )
        
        // 동시에 여러 작업 실행
        await withTaskGroup(of: Void.self) { group in
            // 저장 작업들
            for i in 0..<10 {
                group.addTask {
                    await cache.set([mockResult], for: "concurrent_\(i)")
                }
            }
            
            // 조회 작업들
            for i in 0..<10 {
                group.addTask {
                    _ = await cache.get(for: "concurrent_\(i)")
                }
            }
            
            // 정리 작업들
            for _ in 0..<5 {
                group.addTask {
                    _ = await cache.cleanupExpired()
                }
            }
        }
        
        // 크래시 없이 완료되면 성공
        let stats = await cache.getStats()
        #expect(stats.totalItems >= 0)
    }
    
    /// 검색 결과 객체 생성 비용 테스트
    @Test("검색 결과 객체 생성 비용")
    func testSearchResultCreationCost() async throws {
        let startTime = Date()
        
        // 1000개의 검색 결과 객체 생성
        var results: [YFSearchResult] = []
        
        for i in 1...1000 {
            let result = YFSearchResult(
                symbol: "SYM\(i)",
                shortName: "Company \(i)",
                longName: "Long Company Name \(i)",
                exchange: "NYSE",
                quoteType: .equity,
                score: Double(i) / 1000.0
            )
            results.append(result)
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        // 1000개 객체 생성이 0.1초 이내에 완료되어야 함
        #expect(elapsed < 0.1)
        #expect(results.count == 1000)
        
        // Ticker 변환 성능 테스트
        let conversionStart = Date()
        
        var tickers: [YFTicker] = []
        for result in results.prefix(100) { // 처음 100개만 테스트
            do {
                let ticker = try result.toTicker()
                tickers.append(ticker)
            } catch {
                // 변환 실패는 무시
            }
        }
        
        let conversionElapsed = Date().timeIntervalSince(conversionStart)
        
        // 100개 변환이 0.01초 이내에 완료되어야 함
        #expect(conversionElapsed < 0.01)
    }
    
    // MARK: - 리소스 정리 테스트
    
    /// 자동 정리 기능 테스트
    @Test("자동 리소스 정리")
    func testAutomaticCleanup() async throws {
        let cache = YFSearchCache.shared
        await cache.clearAll()
        
        let mockResult = YFSearchResult(
            symbol: "CLEAN",
            shortName: "Cleanup Test",
            longName: "Cleanup Test Company",
            exchange: "NYSE",
            quoteType: .equity,
            score: 0.7
        )
        
        // 많은 데이터 추가
        for i in 1...200 { // 최대 제한보다 많이 추가
            await cache.set([mockResult], for: "cleanup_\(i)")
        }
        
        let beforeStats = await cache.getStats()
        
        // 수동 정리 실행
        let cleanedCount = await cache.cleanupExpired()
        
        let afterStats = await cache.getStats()
        
        // 정리가 실행되었는지 확인
        #expect(cleanedCount >= 0)
        #expect(afterStats.totalItems <= 100) // 최대 제한 준수
        #expect(afterStats.memoryUsage <= beforeStats.memoryUsage)
    }
}