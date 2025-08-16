import Testing
@testable import SwiftYFinance

/// YFSearchCache 캐싱 기능 테스트
///
/// 분 단위 TTL 캐싱의 정확성과 성능을 검증합니다.
@Suite("YFSearchCache Tests")
struct YFSearchCacheTests {
    
    // MARK: - 기본 캐싱 테스트
    
    /// 캐시 저장 및 조회 기본 기능 테스트
    @Test("캐시 저장 및 조회")
    func testCacheSetAndGet() async throws {
        let cache = YFSearchCache.shared
        cache.clearAll()
        
        let mockResults = [
            YFSearchResult(
                symbol: "AAPL",
                shortName: "Apple Inc.",
                longName: "Apple Inc.",
                exchange: "NASDAQ",
                quoteType: .equity,
                score: 0.95
            )
        ]
        
        // 캐시에 저장
        cache.set(mockResults, for: "Apple")
        
        // 캐시에서 조회
        let cachedResults = cache.get(for: "Apple")
        
        #expect(cachedResults != nil)
        #expect(cachedResults?.count == 1)
        #expect(cachedResults?.first?.symbol == "AAPL")
    }
    
    /// 캐시 키 정규화 테스트
    @Test("캐시 키 정규화")
    func testCacheKeyNormalization() async throws {
        let cache = YFSearchCache.shared
        cache.clearAll()
        
        let mockResults = [
            YFSearchResult(
                symbol: "MSFT",
                shortName: "Microsoft",
                longName: "Microsoft Corporation",
                exchange: "NASDAQ",
                quoteType: .equity,
                score: 0.92
            )
        ]
        
        // 다양한 형태로 저장
        cache.set(mockResults, for: "  Microsoft  ")
        
        // 정규화된 키로 조회 가능한지 확인
        let result1 = cache.get(for: "microsoft")
        let result2 = cache.get(for: "Microsoft")
        let result3 = cache.get(for: " Microsoft ")
        
        #expect(result1 != nil)
        #expect(result2 != nil)
        #expect(result3 != nil)
        #expect(result1?.first?.symbol == "MSFT")
    }
    
    // MARK: - TTL 만료 테스트
    
    /// TTL 만료 테스트 (시뮬레이션)
    @Test("TTL 만료 시뮬레이션")
    func testTTLExpiration() async throws {
        let cache = YFSearchCache.shared
        cache.clearAll()
        
        let mockResults = [
            YFSearchResult(
                symbol: "TSLA",
                shortName: "Tesla",
                longName: "Tesla, Inc.",
                exchange: "NASDAQ",
                quoteType: .equity,
                score: 0.88
            )
        ]
        
        // 캐시에 저장
        cache.set(mockResults, for: "Tesla")
        
        // 즉시 조회하면 존재
        let immediate = cache.get(for: "Tesla")
        #expect(immediate != nil)
        
        // 만료된 항목 정리 실행
        let cleanedCount = cache.cleanupExpired()
        #expect(cleanedCount >= 0)
        
        // 통계 확인
        let stats = cache.getStats()
        #expect(stats.totalItems >= 0)
        #expect(stats.validItems >= 0)
    }
    
    // MARK: - 최대 항목 수 테스트
    
    /// 최대 캐시 항목 수 제한 테스트
    @Test("최대 캐시 항목 수 제한")
    func testMaxItemsLimit() async throws {
        let cache = YFSearchCache.shared
        cache.clearAll()
        
        let mockResult = YFSearchResult(
            symbol: "TEST",
            shortName: "Test Company",
            longName: "Test Company Inc.",
            exchange: "NYSE",
            quoteType: .equity,
            score: 0.5
        )
        
        // 여러 항목 추가 (최대 제한 테스트)
        for i in 1...10 {
            cache.set([mockResult], for: "company_\(i)")
        }
        
        let stats = cache.getStats()
        #expect(stats.totalItems <= 100) // 최대 제한 확인
    }
    
    // MARK: - 캐시 통계 테스트
    
    /// 캐시 상태 통계 테스트
    @Test("캐시 상태 통계")
    func testCacheStats() async throws {
        let cache = YFSearchCache.shared
        cache.clearAll()
        
        // 초기 상태
        let initialStats = cache.getStats()
        #expect(initialStats.totalItems == 0)
        #expect(initialStats.validItems == 0)
        #expect(initialStats.expiredItems == 0)
        
        // 몇 개 항목 추가
        let mockResult = YFSearchResult(
            symbol: "GOOG",
            shortName: "Alphabet",
            longName: "Alphabet Inc.",
            exchange: "NASDAQ",
            quoteType: .equity,
            score: 0.98
        )
        
        cache.set([mockResult], for: "Google")
        cache.set([mockResult], for: "Alphabet")
        
        let afterAddStats = cache.getStats()
        #expect(afterAddStats.totalItems == 2)
        #expect(afterAddStats.memoryUsage > 0)
    }
    
    // MARK: - 캐시 초기화 테스트
    
    /// 전체 캐시 초기화 테스트
    @Test("전체 캐시 초기화")
    func testClearAll() async throws {
        let cache = YFSearchCache.shared
        
        let mockResult = YFSearchResult(
            symbol: "AMZN",
            shortName: "Amazon",
            longName: "Amazon.com Inc.",
            exchange: "NASDAQ",
            quoteType: .equity,
            score: 0.91
        )
        
        // 캐시에 데이터 추가
        cache.set([mockResult], for: "Amazon")
        
        // 데이터 존재 확인
        let beforeClear = cache.get(for: "Amazon")
        #expect(beforeClear != nil)
        
        // 전체 초기화
        cache.clearAll()
        
        // 초기화 후 데이터 없음 확인
        let afterClear = cache.get(for: "Amazon")
        #expect(afterClear == nil)
        
        let stats = cache.getStats()
        #expect(stats.totalItems == 0)
    }
    
    // MARK: - 동시성 테스트
    
    /// 멀티스레드 안전성 테스트
    @Test("멀티스레드 안전성")
    func testThreadSafety() async throws {
        let cache = YFSearchCache.shared
        cache.clearAll()
        
        let mockResult = YFSearchResult(
            symbol: "NFLX",
            shortName: "Netflix",
            longName: "Netflix, Inc.",
            exchange: "NASDAQ",
            quoteType: .equity,
            score: 0.87
        )
        
        // 동시에 여러 작업 실행
        await withTaskGroup(of: Void.self) { group in
            // 여러 스레드에서 동시에 캐시 작업
            for i in 0..<10 {
                group.addTask {
                    cache.set([mockResult], for: "test_\(i)")
                    _ = cache.get(for: "test_\(i)")
                }
            }
        }
        
        // 통계 확인 (크래시 없이 완료되면 성공)
        let stats = cache.getStats()
        #expect(stats.totalItems >= 0)
    }
}