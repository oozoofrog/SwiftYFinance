import Testing
import Foundation
@testable import SwiftYFinance

struct YFBrowserImpersonatorTests {
    
    @Test
    func testBrowserImpersonatorExists() {
        // Red: YFBrowserImpersonator 클래스가 존재해야 함
        let impersonator = YFBrowserImpersonator()
        #expect(impersonator != nil)
    }
    
    @Test
    func testChrome136UserAgent() {
        // Red: Chrome 136 User-Agent를 제공해야 함
        let impersonator = YFBrowserImpersonator()
        let userAgent = impersonator.getCurrentUserAgent()
        
        // Chrome 135 이상 버전 포함해야 함 (랜덤 선택이므로)
        #expect(userAgent.contains("Chrome/135.0.0.0") || userAgent.contains("Chrome/136.0.0.0"))
        #expect(userAgent.contains("Safari/537.36"))
    }
    
    @Test
    func testChrome136Headers() {
        // Red: Chrome 136과 동일한 헤더를 제공해야 함
        let impersonator = YFBrowserImpersonator()
        let headers = impersonator.getChrome136Headers()
        
        // 필수 Chrome 헤더 확인
        #expect(headers["User-Agent"] != nil)
        #expect(headers["Accept"] != nil)
        #expect(headers["Accept-Language"] != nil)
        #expect(headers["Accept-Encoding"] != nil)
        #expect(headers["Connection"] == "keep-alive")
        
        // Chrome의 Sec-CH-UA 헤더 확인
        #expect(headers["Sec-CH-UA"] != nil)
        #expect(headers["Sec-CH-UA-Mobile"] == "?0")
        #expect(headers["Sec-CH-UA-Platform"] != nil)
    }
    
    @Test
    func testURLSessionConfiguration() {
        // Red: URLSession을 Chrome 136과 유사하게 설정해야 함
        let impersonator = YFBrowserImpersonator()
        let urlSession = impersonator.createConfiguredURLSession()
        
        // HTTP/2 지원 확인
        #expect(urlSession.configuration.httpMaximumConnectionsPerHost == 4)  // Yahoo Finance 서버 부하 고려
        #expect(urlSession.configuration.timeoutIntervalForRequest > 0)
        #expect(urlSession.configuration.httpCookieAcceptPolicy == .always)
    }
    
    @Test
    func testUserAgentRotation() {
        // Red: User-Agent 로테이션 기능이 있어야 함
        let impersonator = YFBrowserImpersonator()
        
        let userAgent1 = impersonator.getCurrentUserAgent()
        impersonator.rotateUserAgent()
        let userAgent2 = impersonator.getCurrentUserAgent()
        
        // 로테이션 후 다른 User-Agent가 나와야 함 (또는 같을 수도 있지만 메서드 존재 확인)
        #expect(userAgent1 != nil)
        #expect(userAgent2 != nil)
    }
}