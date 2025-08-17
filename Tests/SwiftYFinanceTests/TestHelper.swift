import Foundation
import Testing
@testable import SwiftYFinance

/// 테스트 격리를 위한 공통 유틸리티
/// 
/// Swift Testing 환경에서 테스트 간 상태 간섭을 방지하기 위한 정리 및 초기화 기능을 제공합니다.
/// 모킹 없이 실제 시스템을 사용하되 각 테스트마다 깨끗한 환경을 보장합니다.
///
/// ## 주요 기능
/// - **쿠키 정리**: Yahoo 관련 쿠키 완전 제거
/// - **세션 초기화**: YFSession 상태 리셋
/// - **Rate Limiter 설정**: 테스트용 빠른 설정
///
/// ## 사용 예시
/// ```swift
/// @Test
/// func testSomething() async throws {
///     await TestHelper.setUp()
///     defer { await TestHelper.tearDown() }
///     
///     // 테스트 로직
/// }
/// ```
struct TestHelper {
    
    // MARK: - 테스트 환경 설정
    
    /// 테스트 시작 전 환경 초기화
    /// 
    /// 모든 공유 상태를 초기화하여 테스트 격리를 보장합니다.
    static func setUp() async {
        await clearAllYahooCookies()
        await resetRateLimiterForTesting()
        // Rate Limiter 초기화는 비동기로 처리
    }
    
    /// 테스트 종료 후 정리
    /// 
    /// 테스트에서 생성된 상태를 정리하여 다음 테스트에 영향을 주지 않도록 합니다.
    static func tearDown() async {
        await clearAllYahooCookies()
        await restoreRateLimiterSettings()
    }
    
    // MARK: - 쿠키 정리
    
    /// Yahoo Finance 관련 모든 쿠키 제거
    /// 
    /// HTTPCookieStorage.shared에서 Yahoo 도메인과 관련된 모든 쿠키를 찾아 제거합니다.
    /// 테스트 격리의 핵심 기능으로, 이전 테스트의 인증 상태가 다음 테스트에 영향을 주지 않도록 합니다.
    static func clearAllYahooCookies() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                guard let cookies = HTTPCookieStorage.shared.cookies else {
                    continuation.resume()
                    return
                }
                
                let yahooCookies = cookies.filter { cookie in
                    cookie.domain.contains("yahoo") || 
                    cookie.domain.contains("finance") ||
                    cookie.name == "A3"
                }
                
                for cookie in yahooCookies {
                    HTTPCookieStorage.shared.deleteCookie(cookie)
                }
                
                continuation.resume()
            }
        }
    }
    
    /// 특정 도메인의 쿠키만 제거
    /// - Parameter domain: 제거할 쿠키의 도메인
    static func clearCookies(for domain: String) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                guard let cookies = HTTPCookieStorage.shared.cookies else {
                    continuation.resume()
                    return
                }
                
                let targetCookies = cookies.filter { cookie in
                    cookie.domain.contains(domain)
                }
                
                for cookie in targetCookies {
                    HTTPCookieStorage.shared.deleteCookie(cookie)
                }
                
                continuation.resume()
            }
        }
    }
    
    // MARK: - Rate Limiter 설정
    
    /// 테스트용 빠른 Rate Limiter 설정
    /// 
    /// 테스트 실행 속도를 높이기 위해 Rate Limiter의 간격을 짧게 설정합니다.
    static func resetRateLimiterForTesting() async {
        let rateLimiter = YFRateLimiter.shared
        
        // 테스트용 빠른 설정 적용
        await rateLimiter.configureForTesting(minimumInterval: 0.05, maxConcurrentRequests: 1)
    }
    
    /// 원래 Rate Limiter 설정 복원
    static func restoreRateLimiterSettings() async {
        let rateLimiter = YFRateLimiter.shared
        
        // 운영용 설정으로 복원
        await rateLimiter.restoreProductionSettings()
    }
    
    // MARK: - 세션 초기화
    
    /// YFSession 상태 완전 초기화
    /// - Parameter session: 초기화할 세션 인스턴스
    static func resetSession(_ session: YFSession) async {
        // 세션의 resetState 메서드 호출 (구현 예정)
        await session.resetState()
    }
    
    /// 새로운 깨끗한 YFSession 생성
    /// - Returns: 초기화된 새로운 세션 인스턴스
    static func createCleanSession() -> YFSession {
        return YFSession()
    }
    
    // MARK: - 네트워크 테스트 헬퍼
    
    /// 네트워크 연결 상태 확인
    /// - Returns: 네트워크 연결 가능 여부
    static func isNetworkAvailable() async -> Bool {
        do {
            let url = URL(string: "https://finance.yahoo.com")!
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    /// 테스트용 짧은 타임아웃으로 네트워크 요청
    /// - Parameters:
    ///   - url: 요청할 URL
    ///   - timeout: 타임아웃 시간 (기본 5초)
    /// - Returns: 응답 데이터와 HTTPURLResponse
    static func quickNetworkRequest(to url: URL, timeout: TimeInterval = 5.0) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        return (data, httpResponse)
    }
    
    // MARK: - 테스트 상태 검증
    
    /// 테스트 환경이 깨끗한지 검증
    /// - Returns: 검증 결과와 상세 정보
    static func validateCleanEnvironment() async -> (isClean: Bool, details: String) {
        var issues: [String] = []
        
        // 쿠키 상태 확인
        if let cookies = HTTPCookieStorage.shared.cookies {
            let yahooCookies = cookies.filter { $0.domain.contains("yahoo") }
            if !yahooCookies.isEmpty {
                issues.append("Yahoo cookies found: \(yahooCookies.count)")
            }
        }
        
        // Rate Limiter 상태 확인
        let rateLimiter = YFRateLimiter.shared
        let settings = await rateLimiter.getCurrentSettings()
        if settings.minimumInterval > 0.1 {
            issues.append("Rate limiter not in test mode: \(settings.minimumInterval)s")
        }
        
        let isClean = issues.isEmpty
        let details = isClean ? "Environment is clean" : "Issues: \(issues.joined(separator: ", "))"
        
        return (isClean: isClean, details: details)
    }
}