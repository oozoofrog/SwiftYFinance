import Foundation

/// Yahoo Finance API 요청의 rate limiting을 관리하는 싱글톤 actor
/// Python yfinance의 rate limiting 전략을 Swift Concurrency로 포팅
actor YFRateLimiter {
    
    /// 싱글톤 인스턴스
    static let shared = YFRateLimiter()
    
    /// 최대 동시 요청 수
    private let maxConcurrentRequests = 2
    
    /// 최소 요청 간격 (초) 
    private let minimumInterval: TimeInterval = 0.5
    
    /// 현재 실행 중인 요청 수
    private var activeRequests = 0
    
    /// 마지막 요청 시간 추적
    private var lastRequestTime: Date = Date.distantPast
    
    /// 대기 중인 요청들을 위한 continuation 배열
    private var waitingContinuations: [CheckedContinuation<Void, Never>] = []
    
    private init() {}
    
    /// 요청을 rate limiting과 함께 실행
    /// - Parameter operation: 실행할 비동기 작업
    func executeRequest<T: Sendable>(_ operation: @escaping @Sendable () async throws -> T) async rethrows -> T {
        // 요청 실행 권한 획득 대기
        await acquirePermission()
        
        // 최소 간격 보장
        await enforceMinimumInterval()
        
        // 요청 실행 후 권한 해제
        do {
            let result = try await operation()
            releasePermission()
            return result
        } catch {
            releasePermission()
            throw error
        }
    }
    
    /// 요청을 rate limiting과 함께 실행 (반환값 없음)
    /// - Parameter operation: 실행할 비동기 작업
    func executeRequest(_ operation: @escaping @Sendable () async -> Void) async {
        // 요청 실행 권한 획득 대기
        await acquirePermission()
        
        // 최소 간격 보장
        await enforceMinimumInterval()
        
        // 요청 실행 후 권한 해제
        await operation()
        releasePermission()
    }
    
    /// 요청 실행 권한 획득
    private func acquirePermission() async {
        if activeRequests < maxConcurrentRequests {
            activeRequests += 1
            return
        }
        
        // 최대 동시 요청 수 초과 시 대기
        await withCheckedContinuation { continuation in
            waitingContinuations.append(continuation)
        }
        
        activeRequests += 1
    }
    
    /// 요청 실행 권한 해제
    private func releasePermission() {
        activeRequests -= 1
        
        // 대기 중인 요청이 있다면 하나를 깨움
        if !waitingContinuations.isEmpty {
            let continuation = waitingContinuations.removeFirst()
            continuation.resume()
        }
    }
    
    /// 최소 요청 간격을 보장하는 내부 메서드
    private func enforceMinimumInterval() async {
        let currentTime = Date()
        let timeSinceLastRequest = currentTime.timeIntervalSince(lastRequestTime)
        
        if timeSinceLastRequest < minimumInterval {
            let waitTime = minimumInterval - timeSinceLastRequest
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        
        lastRequestTime = Date()
    }
}