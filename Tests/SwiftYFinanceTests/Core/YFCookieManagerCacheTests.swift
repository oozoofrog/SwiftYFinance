import Testing
import Foundation
@testable import SwiftYFinance

struct YFCookieManagerCacheTests {
    
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
}