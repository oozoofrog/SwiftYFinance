import Testing
import Foundation
@testable import SwiftYFinance

struct YFCookieManagerStorageTests {
    
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
}