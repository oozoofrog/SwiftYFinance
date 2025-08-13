import Testing
@testable import SwiftYFinance

struct YFSessionSeparationTests {
    
    @Test("YFSession file exists")
    func testYFSessionFileExists() {
        // Red: 분리된 YFSession.swift 파일이 존재해야 함
        let session = YFSession()
        #expect(session != nil)
        #expect(session.baseURL != nil)
    }
    
    @Test("YFSessionAuth file exists")
    func testYFSessionAuthFileExists() async {
        // Red: 분리된 YFSessionAuth.swift 파일이 존재해야 함
        let session = YFSession()
        
        // CSRF 인증 메서드가 접근 가능해야 함
        do {
            try await session.authenticateCSRF()
        } catch {
            // 에러가 발생할 수 있지만 메서드 자체는 존재해야 함
            #expect(error is YFError)
        }
    }
    
    @Test("YFSessionCookie file exists")
    func testYFSessionCookieFileExists() {
        // Red: 분리된 YFSessionCookie.swift 파일이 존재해야 함  
        let session = YFSession()
        
        // User-Agent 관련 메서드가 접근 가능해야 함
        let userAgent = session.defaultHeaders["User-Agent"]
        #expect(userAgent != nil)
        #expect(userAgent!.contains("Chrome"))
    }
}