import Testing
import Foundation
@testable import SwiftYFinance

struct YFCookieManagerTests {
    
    // MARK: - A3 쿠키 추출 테스트
    
    @Test
    func testA3CookieExtraction() {
        // 공유 쿠키 스토리지 사용 (실제 환경)
        let manager = YFCookieManager()
        
        // 기존 yahoo 쿠키들 정리
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                if cookie.domain.contains("yahoo") {
                    HTTPCookieStorage.shared.deleteCookie(cookie)
                }
            }
        }
        
        // A3 쿠키가 없는 경우
        #expect(manager.extractA3Cookie() == nil)
        #expect(manager.hasValidA3Cookie() == false)
        
        // Mock A3 쿠키 생성
        let a3Cookie = HTTPCookie(properties: [
            .domain: "finance.yahoo.com",
            .path: "/",
            .name: "A3",
            .value: "test_a3_value_12345",
            .secure: "TRUE",
            .expires: Date().addingTimeInterval(3600) // 1시간 후 만료
        ])!
        
        HTTPCookieStorage.shared.setCookie(a3Cookie)
        
        // A3 쿠키 추출 확인
        let extractedCookie = manager.extractA3Cookie()
        #expect(extractedCookie?.name == "A3")
        #expect(extractedCookie?.domain == "finance.yahoo.com")
        #expect(extractedCookie?.value == "test_a3_value_12345")
        #expect(manager.hasValidA3Cookie() == true)
        
        // 테스트 후 정리
        HTTPCookieStorage.shared.deleteCookie(a3Cookie)
    }
    
    @Test
    func testYahooCookieFiltering() {
        let manager = YFCookieManager()
        
        // 기존 쿠키들 정리
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        
        // 다양한 쿠키들 추가
        let yahooCookie = HTTPCookie(properties: [
            .domain: "finance.yahoo.com",
            .path: "/",
            .name: "SessionId",
            .value: "session123"
        ])!
        
        let consentCookie = HTTPCookie(properties: [
            .domain: "consent.yahoo.com", 
            .path: "/",
            .name: "ConsentId",
            .value: "consent456"
        ])!
        
        let otherCookie = HTTPCookie(properties: [
            .domain: "google.com",
            .path: "/",
            .name: "GoogleId",
            .value: "google789"
        ])!
        
        HTTPCookieStorage.shared.setCookie(yahooCookie)
        HTTPCookieStorage.shared.setCookie(consentCookie)
        HTTPCookieStorage.shared.setCookie(otherCookie)
        
        // Yahoo 쿠키 필터링 테스트
        let yahooCookies = manager.extractYahooCookies(for: "finance.yahoo.com")
        #expect(yahooCookies.count >= 1)
        #expect(yahooCookies.contains { $0.name == "SessionId" })
        
        // Finance 쿠키 필터링 (consent 제외)
        let financeCookies = manager.filterFinanceCookies()
        #expect(financeCookies.count >= 1)
        #expect(financeCookies.contains { $0.domain == "finance.yahoo.com" })
        
        // 테스트 후 정리
        HTTPCookieStorage.shared.deleteCookie(yahooCookie)
        HTTPCookieStorage.shared.deleteCookie(consentCookie)
        HTTPCookieStorage.shared.deleteCookie(otherCookie)
    }
    
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
        #expect(removedCount >= 1)
        
        // 유효한 쿠키만 남아있는지 확인
        let remainingCookies = manager.extractYahooCookies(for: "finance.yahoo.com")
        #expect(remainingCookies.contains { $0.name == "ValidCookie" })
        
        // 테스트 후 정리
        HTTPCookieStorage.shared.deleteCookie(validCookie)
    }
    
    // MARK: - 메모리 캐시 테스트
    
    @Test
    func testCookieCaching() {
        let manager = YFCookieManager()
        
        let testCookie = HTTPCookie(properties: [
            .domain: "finance.yahoo.com",
            .path: "/",
            .name: "TestCookie",
            .value: "test123"
        ])!
        
        // 쿠키 캐싱
        manager.cacheCookie(testCookie, for: .basic)
        
        // 캐시에서 조회
        let cached = manager.getCachedCookie(strategy: .basic, domain: "finance.yahoo.com", name: "TestCookie")
        #expect(cached?.cookie.name == "TestCookie")
        #expect(cached?.cookie.value == "test123")
        
        // 전략별 캐시 조회
        let basicCookies = manager.getCachedCookies(for: .basic)
        #expect(basicCookies.count == 1)
        #expect(basicCookies.first?.name == "TestCookie")
        
        let csrfCookies = manager.getCachedCookies(for: .csrf)
        #expect(csrfCookies.count == 0)
    }
    
    @Test
    func testCacheClear() {
        let manager = YFCookieManager()
        
        let basicCookie = HTTPCookie(properties: [
            .domain: "finance.yahoo.com",
            .path: "/",
            .name: "BasicCookie",
            .value: "basic123"
        ])!
        
        let csrfCookie = HTTPCookie(properties: [
            .domain: "finance.yahoo.com",
            .path: "/",
            .name: "CSRFCookie", 
            .value: "csrf123"
        ])!
        
        manager.cacheCookie(basicCookie, for: .basic)
        manager.cacheCookie(csrfCookie, for: .csrf)
        
        // 특정 전략 캐시 초기화
        manager.clearCache(for: .basic)
        
        #expect(manager.getCachedCookies(for: .basic).count == 0)
        #expect(manager.getCachedCookies(for: .csrf).count == 1)
        
        // 전체 캐시 초기화
        manager.clearCache()
        
        #expect(manager.getCachedCookies(for: .basic).count == 0)
        #expect(manager.getCachedCookies(for: .csrf).count == 0)
    }
    
    // MARK: - HTTPCookieStorage 연동 테스트
    
    @Test
    func testA3CookieSetting() {
        let manager = YFCookieManager()
        
        // 기존 A3 쿠키들 정리
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                if cookie.domain.contains("yahoo") && cookie.name == "A3" {
                    HTTPCookieStorage.shared.deleteCookie(cookie)
                }
            }
        }
        
        let a3Cookie = HTTPCookie(properties: [
            .domain: "finance.yahoo.com",
            .path: "/",
            .name: "A3",
            .value: "a3_test_value",
            .secure: "TRUE"
        ])!
        
        // A3 쿠키 설정
        manager.setA3Cookie(a3Cookie)
        
        // HTTPCookieStorage에서 확인
        let extractedCookie = manager.extractA3Cookie()
        #expect(extractedCookie?.name == "A3")
        #expect(extractedCookie?.value == "a3_test_value")
        
        // 캐시에서도 확인
        let csrfCookies = manager.getCachedCookies(for: .csrf)
        #expect(csrfCookies.contains { $0.name == "A3" })
        
        // 테스트 후 정리
        HTTPCookieStorage.shared.deleteCookie(a3Cookie)
        manager.clearCache(for: .csrf)
    }
    
    @Test
    func testCookieStatus() {
        let manager = YFCookieManager()
        
        // 기존 쿠키들 정리
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                if cookie.domain.contains("yahoo") {
                    HTTPCookieStorage.shared.deleteCookie(cookie)
                }
            }
        }
        manager.clearCache()
        
        // 초기 상태
        var status = manager.getCookieStatus()
        #expect(status.hasA3Cookie == false)
        
        // 쿠키들 추가
        let a3Cookie = HTTPCookie(properties: [
            .domain: "finance.yahoo.com",
            .path: "/",
            .name: "A3",
            .value: "a3_value",
            .expires: Date().addingTimeInterval(3600)
        ])!
        
        let sessionCookie = HTTPCookie(properties: [
            .domain: "finance.yahoo.com",
            .path: "/",
            .name: "SessionId",
            .value: "session_value"
        ])!
        
        HTTPCookieStorage.shared.setCookie(a3Cookie)
        HTTPCookieStorage.shared.setCookie(sessionCookie)
        manager.cacheCookie(a3Cookie, for: .csrf)
        
        // 업데이트된 상태 확인
        status = manager.getCookieStatus()
        #expect(status.hasA3Cookie == true)
        #expect(status.a3CookieValid == true)
        #expect(status.yahooCookies >= 2)
        #expect(status.validCookies >= 2)
        #expect(status.cachedCookies == 1)
        
        // 테스트 후 정리
        HTTPCookieStorage.shared.deleteCookie(a3Cookie)
        HTTPCookieStorage.shared.deleteCookie(sessionCookie)
        manager.clearCache()
    }
}