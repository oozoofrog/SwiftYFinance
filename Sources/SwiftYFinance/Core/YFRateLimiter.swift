import Foundation

/// Yahoo Finance API 요청의 rate limiting을 관리하는 싱글톤 actor
/// Python yfinance의 rate limiting 전략을 Swift Concurrency로 포팅
/// Phase 4.5.3: 네트워크 계층 최적화로 재시도 전략 강화
actor YFRateLimiter {
    
    /// 싱글톤 인스턴스
    static let shared = YFRateLimiter()
    
    /// 최대 동시 요청 수 (Phase 4.5.3: Yahoo Finance 서버 안정성 고려)
    private let maxConcurrentRequests = 3  // 2 → 3으로 증가 (네트워크 최적화로 인한 여유)
    
    /// 최소 요청 간격 (초) - Phase 4.5.3: 응답 속도 향상으로 간격 단축
    private let minimumInterval: TimeInterval = 0.3  // 0.5 → 0.3초로 단축
    
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
    
    /// 최소 요청 간격을 보장하는 내부 메서드 (Phase 4.5.3 강화)
    private func enforceMinimumInterval() async {
        let currentTime = Date()
        let timeSinceLastRequest = currentTime.timeIntervalSince(lastRequestTime)
        
        if timeSinceLastRequest < minimumInterval {
            let waitTime = minimumInterval - timeSinceLastRequest
            // Phase 4.5.3: 더 정밀한 sleep 제어
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        
        lastRequestTime = Date()
    }
    
    // MARK: - Phase 4.5.3: 재시도 전략 강화 메서드
    
    /// 지수 백오프와 지터를 적용한 재시도 실행
    /// - Parameters:
    ///   - operation: 실행할 작업
    ///   - maxRetries: 최대 재시도 횟수 (기본값: 3)
    ///   - baseDelay: 기본 지연 시간 (기본값: 1초)
    /// - Returns: 작업 결과
    func executeWithRetry<T: Sendable>(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                return try await executeRequest(operation)
            } catch {
                lastError = error
                
                // 마지막 시도가 아닌 경우에만 재시도
                if attempt < maxRetries {
                    // 지수 백오프 + 지터 적용
                    let delay = baseDelay * pow(2.0, Double(attempt)) + Double.random(in: 0...0.5)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // 모든 재시도 실패 시 마지막 에러 throw
        throw lastError!
    }
}