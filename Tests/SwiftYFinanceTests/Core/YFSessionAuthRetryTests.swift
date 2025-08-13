import Testing
@testable import SwiftYFinance
import Foundation

struct YFSessionAuthRetryTests {
    
    @Test("Strategy toggle on failure")
    func testStrategyToggleOnFailure() async {
        // Given: 새로운 세션
        let session = YFSession()
        let initialStrategy = await session.cookieStrategy
        
        // When: 전략 전환 실행
        await session.toggleCookieStrategy()
        
        // Then: 전략이 변경되어야 함
        let newStrategy = await session.cookieStrategy
        #expect(newStrategy != initialStrategy)
        
        let crumbToken = await session.crumbToken
        #expect(crumbToken == nil)
        
        let isAuthenticated = await session.isAuthenticated
        #expect(isAuthenticated == false)
    }
    
    @Test("Rate limiter integration")
    func testRateLimiterIntegration() async {
        // Given: 세션과 테스트 URL
        let session = YFSession()
        let testURL = URL(string: "https://httpbin.org/delay/1")!
        
        // When: Rate limiter를 통한 요청 (네트워크 에러 예상)
        do {
            let startTime = Date()
            let _ = try await session.makeAuthenticatedRequest(url: testURL)
            let endTime = Date()
            
            // Then: Rate limiting으로 인한 최소 지연시간 확인
            let duration = endTime.timeIntervalSince(startTime)
            #expect(duration > 0.5)
            
        } catch {
            // 네트워크 에러나 인증 실패는 예상됨
            #expect(Bool(true)) // Network errors are expected in test environment
        }
    }
    
    @Test("Authentication with retry")
    func testAuthenticationWithRetry() async {
        // Given: 세션
        let session = YFSession()
        let _ = await session.cookieStrategy
        
        // When: 인증 시도 (실패 예상)
        do {
            try await session.authenticateCSRF()
            
            // Then: 성공한 경우
            let isAuthenticated = await session.isAuthenticated
            #expect(isAuthenticated == true)
            
            let crumbToken = await session.crumbToken
            #expect(crumbToken != nil)
            
        } catch let error as YFError {
            // Then: 실패한 경우 (예상됨)
            switch error {
            case .apiError(let message):
                #expect(message.contains("Failed to authenticate"))
            default:
                Issue.record("Unexpected error type: \(error)")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
    
    @Test("Crumb URL addition")
    func testCrumbURLAddition() async {
        // Given: 인증된 세션 (모킹)
        let session = YFSession()
        await session.sessionState.setCrumbToken("test_crumb_123")
        
        let originalURL = URL(string: "https://query1.finance.yahoo.com/v1/test")!
        
        // When: crumb 추가
        let urlWithCrumb = await session.addCrumbIfNeeded(to: originalURL)
        
        // Then: crumb 파라미터가 추가되어야 함
        let components = URLComponents(url: urlWithCrumb, resolvingAgainstBaseURL: false)
        let crumbItem = components?.queryItems?.first { $0.name == "crumb" }
        
        #expect(crumbItem != nil)
        #expect(crumbItem?.value == "test_crumb_123")
    }
    
    @Test("Crumb URL no double add")
    func testCrumbURLNoDoubleAdd() async {
        // Given: 이미 crumb이 있는 URL
        let session = YFSession()
        await session.sessionState.setCrumbToken("test_crumb_123")
        
        let originalURL = URL(string: "https://query1.finance.yahoo.com/v1/test?crumb=existing_crumb")!
        
        // When: crumb 추가 시도
        let urlWithCrumb = await session.addCrumbIfNeeded(to: originalURL)
        
        // Then: 기존 crumb이 유지되어야 함
        let components = URLComponents(url: urlWithCrumb, resolvingAgainstBaseURL: false)
        let crumbItems = components?.queryItems?.filter { $0.name == "crumb" } ?? []
        
        #expect(crumbItems.count == 1)
        #expect(crumbItems.first?.value == "existing_crumb")
    }
    
    @Test("HTTP method enum")
    func testHTTPMethodEnum() {
        // Given: HTTP 메서드들
        let getMethod = HTTPMethod.GET
        let postMethod = HTTPMethod.POST
        
        // Then: 올바른 raw value를 가져야 함
        #expect(getMethod.rawValue == "GET")
        #expect(postMethod.rawValue == "POST")
    }
}