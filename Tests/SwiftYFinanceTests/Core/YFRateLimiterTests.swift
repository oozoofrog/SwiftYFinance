import Testing
@testable import SwiftYFinance
import Foundation

struct YFRateLimiterTests {
    
    @Test("Rate limiter singleton")
    func testRateLimiterSingleton() {
        // Given: Rate limiter 인스턴스들
        let limiter1 = YFRateLimiter.shared
        let limiter2 = YFRateLimiter.shared
        
        // Then: 동일한 인스턴스여야 함
        #expect(limiter1 === limiter2)
    }
    
    @Test("Concurrent request limiting")
    func testConcurrentRequestLimiting() async {
        // Given: Rate limiter
        let limiter = YFRateLimiter.shared
        let requestCount = 5
        
        // When: 5개의 동시 요청 시도 
        let startTime = Date()
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<requestCount {
                group.addTask {
                    await limiter.executeRequest {
                        // 요청 시뮬레이션 (100ms)
                        try? await Task.sleep(nanoseconds: 100_000_000)
                    }
                }
            }
        }
        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)
        
        // Then: 병렬 처리 + 간격 제어로 충분한 시간이 걸려야 함
        // 최대 2개 동시, 각 100ms + 500ms 간격 = 최소 1.0초 이상
        #expect(totalTime > 1.0)
    }
    
    @Test("Request interval minimum")
    func testRequestIntervalMinimum() async {
        // Given: Rate limiter (Phase 4.5.3 네트워크 최적화)
        let limiter = YFRateLimiter.shared
        let minimumInterval: TimeInterval = 0.3 // 300ms (0.5 → 0.3초로 단축)
        
        // When: 연속된 두 요청의 시간 측정
        let firstRequestTime = Date()
        
        await limiter.executeRequest {
            // 첫 번째 요청
        }
        
        await limiter.executeRequest {
            // 두 번째 요청
        }
        
        let secondRequestTime = Date()
        let actualInterval = secondRequestTime.timeIntervalSince(firstRequestTime)
        
        // Then: 최소 간격이 보장되어야 함
        #expect(actualInterval >= minimumInterval - 0.1)
    }
    
    @Test("Thread safety")
    func testThreadSafety() async {
        // Given: Rate limiter
        let limiter = YFRateLimiter.shared
        let expectedCount = 10
        
        // When: 여러 스레드에서 동시에 접근
        let results = await withTaskGroup(of: Int.self) { group in
            for i in 0..<expectedCount {
                group.addTask {
                    return await limiter.executeRequest {
                        return i + 1  // 각 태스크마다 고유값 반환
                    }
                }
            }
            
            var collectedResults: [Int] = []
            for await result in group {
                collectedResults.append(result)
            }
            return collectedResults
        }
        
        // Then: 모든 요청이 안전하게 처리되어야 함
        #expect(results.count == expectedCount)
        #expect(results.sorted() == Array(1...expectedCount))
    }
}