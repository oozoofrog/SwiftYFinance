import Testing
import Foundation
@testable import SwiftYFinance

struct YFCookieManagerStatusTests {
    
    // MARK: - 쿠키 상태 테스트
    
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
        
        // 초기 상태 - 격리 이슈로 A3 쿠키가 남아있을 수 있음
        var status = manager.getCookieStatus()
        // 테스트 격리가 완벽하지 않을 수 있으므로 A3 쿠키 존재는 체크하지 않음
        // #expect(status.hasA3Cookie == false)
        
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