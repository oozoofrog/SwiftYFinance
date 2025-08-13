import Testing
import Foundation
@testable import SwiftYFinance

struct YFCookieManagerExtractionTests {
    
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
}