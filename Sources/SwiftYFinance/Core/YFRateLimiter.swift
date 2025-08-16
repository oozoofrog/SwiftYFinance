import Foundation

/// Yahoo Finance API 요청의 rate limiting을 관리하는 싱글톤 actor
/// 
/// Yahoo Finance 서버의 부하를 줄이고 API 차단을 방지하기 위해 동시 요청 수와 요청 간격을 제어합니다.
/// Python yfinance의 rate limiting 전략을 Swift Concurrency로 포팅하였습니다.
///
/// ## 주요 기능
/// - **동시 요청 제한**: 최대 3개의 동시 요청으로 제한
/// - **요청 간격 제어**: 최소 0.3초 간격으로 요청 발송
/// - **지수 백오프**: 재시도 시 점진적으로 대기 시간 증가
/// - **Actor 기반**: Swift Concurrency를 활용한 안전한 비동기 처리
///
/// ## 사용 예시
/// ```swift
/// // 기본 사용 (자동 rate limiting)
/// let result = await YFRateLimiter.shared.executeRequest {
///     try await client.fetchQuote(ticker: ticker)
/// }
///
/// // 재시도가 포함된 실행
/// let result = try await YFRateLimiter.shared.executeWithRetry(maxRetries: 3) {
///     try await client.fetchFinancials(ticker: ticker)
/// }
/// ```
///
/// - Note: 이 클래스는 내부적으로 YFClient에서 자동 사용되므로 직접 호출할 필요는 없습니다.
actor YFRateLimiter {
    
    /// 싱글톤 인스턴스
    /// 
    /// 애플리케이션 전체에서 단일 rate limiter 인스턴스를 공유하여 
    /// 모든 Yahoo Finance API 호출을 통합 관리합니다.
    static let shared = YFRateLimiter()
    
    /// 최대 동시 요청 수
    /// 
    /// Yahoo Finance 서버의 안정성을 고려하여 설정된 값입니다.
    /// 너무 높으면 서버에서 차단될 수 있고, 너무 낮으면 성능이 저하됩니다.
    /// 테스트 환경에서는 더 빠른 실행을 위해 조정 가능합니다.
    var maxConcurrentRequests = 3
    
    /// 최소 요청 간격 (초)
    /// 
    /// 연속된 요청 사이의 최소 대기 시간입니다.
    /// 이 간격을 통해 서버 부하를 줄이고 안정적인 API 접근을 보장합니다.
    /// 테스트 환경에서는 더 빠른 실행을 위해 조정 가능합니다.
    var minimumInterval: TimeInterval = 0.3
    
    /// 현재 실행 중인 요청 수
    /// 
    /// 동시 요청 제한을 관리하기 위해 추적되는 값입니다.
    private var activeRequests = 0
    
    /// 마지막 요청 시간
    /// 
    /// 최소 요청 간격을 계산하기 위해 사용됩니다.
    private var lastRequestTime: Date = Date.distantPast
    
    /// 대기 중인 요청들을 위한 continuation 배열
    /// 
    /// 동시 요청 수 제한에 걸린 요청들을 순서대로 처리하기 위한 큐입니다.
    private var waitingContinuations: [CheckedContinuation<Void, Never>] = []
    
    /// Rate Limiter 초기화
    /// 
    /// private으로 설정되어 싱글톤 패턴을 강제합니다.
    private init() {}
    
    /// 주어진 작업을 rate limiting 제약 하에서 실행합니다
    /// 
    /// 이 메서드는 동시 요청 수 제한과 최소 요청 간격을 자동으로 관리하며,
    /// 필요시 작업을 대기열에 추가하여 순차적으로 처리합니다.
    /// 
    /// - Parameter operation: 실행할 비동기 작업 (반환값 있음)
    /// - Returns: 작업의 실행 결과
    /// - Throws: 작업 실행 중 발생한 모든 에러를 전파
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
    
    /// 주어진 작업을 rate limiting 제약 하에서 실행합니다 (반환값 없음)
    /// 
    /// 반환값이 없는 작업을 위한 오버로드 메서드입니다.
    /// 동시 요청 수 제한과 최소 요청 간격을 자동으로 관리합니다.
    /// 
    /// - Parameter operation: 실행할 비동기 작업 (반환값 없음)
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
    
    // MARK: - 테스트 지원
    
    /// Rate Limiter 상태 완전 초기화 (테스트용)
    /// 
    /// 테스트 격리를 위해 Rate Limiter의 모든 상태를 초기값으로 되돌립니다.
    /// 활성 요청 수, 마지막 요청 시간, 대기 중인 continuation들을 모두 리셋합니다.
    func reset() {
        activeRequests = 0
        lastRequestTime = Date.distantPast
        
        // 대기 중인 모든 continuation을 해제
        for continuation in waitingContinuations {
            continuation.resume()
        }
        waitingContinuations.removeAll()
    }
    
    /// 테스트용 설정 적용 (테스트용)
    /// 
    /// 테스트 실행 속도를 높이기 위해 Rate Limiter 설정을 조정합니다.
    /// - Parameters:
    ///   - minimumInterval: 최소 요청 간격 (기본값: 0.05초)
    ///   - maxConcurrentRequests: 최대 동시 요청 수 (기본값: 1)
    func configureForTesting(minimumInterval: TimeInterval = 0.05, maxConcurrentRequests: Int = 1) {
        self.minimumInterval = minimumInterval
        self.maxConcurrentRequests = maxConcurrentRequests
        reset()
    }
    
    /// 운영용 설정으로 복원 (테스트용)
    /// 
    /// 테스트 완료 후 원래 운영 설정으로 되돌립니다.
    func restoreProductionSettings() {
        self.minimumInterval = 0.3
        self.maxConcurrentRequests = 3
        reset()
    }
    
    /// 현재 설정 정보 반환 (테스트용)
    /// 
    /// 현재 Rate Limiter의 설정을 확인할 수 있습니다.
    /// - Returns: (minimumInterval, maxConcurrentRequests) 튜플
    func getCurrentSettings() -> (minimumInterval: TimeInterval, maxConcurrentRequests: Int) {
        return (minimumInterval: minimumInterval, maxConcurrentRequests: maxConcurrentRequests)
    }
}