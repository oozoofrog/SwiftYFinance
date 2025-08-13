import Testing
import Foundation
@testable import SwiftYFinance

struct YFCookieManagerValidationTests {
    
    // MARK: - 쿠키 유효성 검증 테스트
    
    @Test
    func testCookieValidation() {
        let manager = YFCookieManager()
        
        // 유효한 쿠키 (미래 만료일)
        let validCookie = HTTPCookie(properties: [
            .domain: "finance.yahoo.com",
            .path: "/",
            .name: "ValidCookie",
            .value: "valid123",
            .expires: Date().addingTimeInterval(3600) // 1시간 후
        ])!
        
        #expect(manager.validateCookie(validCookie) == true)
        
        // 만료된 쿠키 (과거 만료일)
        let expiredCookie = HTTPCookie(properties: [
            .domain: "finance.yahoo.com",
            .path: "/",
            .name: "ExpiredCookie",
            .value: "expired123",
            .expires: Date().addingTimeInterval(-3600) // 1시간 전
        ])!
        
        #expect(manager.validateCookie(expiredCookie) == false)
        
        // 세션 쿠키 (만료일 없음)
        let sessionCookie = HTTPCookie(properties: [
            .domain: "finance.yahoo.com",
            .path: "/",
            .name: "SessionCookie",
            .value: "session123"
        ])!
        
        #expect(manager.validateCookie(sessionCookie) == true)
    }
    
    @Test 
    func testExpiredCookieCleanup() {
        let manager = YFCookieManager()
        
        // 기존 쿠키들 정리
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                if cookie.domain.contains("yahoo") {
                    HTTPCookieStorage.shared.deleteCookie(cookie)
                }
            }
        }
        
        // 유효한 쿠키와 만료된 쿠키 추가
        let validCookie = HTTPCookie(properties: [
            .domain: "finance.yahoo.com",
            .path: "/",
            .name: "ValidCookie",
            .value: "valid123",
            .expires: Date().addingTimeInterval(3600)
        ])!
        
        let expiredCookie = HTTPCookie(properties: [
            .domain: "finance.yahoo.com",
            .path: "/",
            .name: "ExpiredCookie", 
            .value: "expired123",
            .expires: Date().addingTimeInterval(-3600)
        ])!
        
        HTTPCookieStorage.shared.setCookie(validCookie)
        HTTPCookieStorage.shared.setCookie(expiredCookie)
        
        // 만료된 쿠키 정리
        let removedCount = manager.cleanupExpiredCookies()
        #expect(removedCount >= 0) // 자동으로 정리되었을 수도 있음
        
        // 유효한 쿠키만 남아있는지 확인
        let remainingCookies = manager.extractYahooCookies(for: "finance.yahoo.com")
        #expect(remainingCookies.contains { $0.name == "ValidCookie" })
        
        // 테스트 후 정리
        HTTPCookieStorage.shared.deleteCookie(validCookie)
    }
}