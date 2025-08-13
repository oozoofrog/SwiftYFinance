import XCTest
@testable import SwiftYFinance

final class YFSessionSeparationTests: XCTestCase {
    
    func testYFSessionFileExists() {
        // Red: 분리된 YFSession.swift 파일이 존재해야 함
        let session = YFSession()
        XCTAssertNotNil(session)
        XCTAssertNotNil(session.baseURL)
    }
    
    func testYFSessionAuthFileExists() {
        // Red: 분리된 YFSessionAuth.swift 파일이 존재해야 함
        let session = YFSession()
        
        // CSRF 인증 메서드가 접근 가능해야 함
        Task {
            do {
                try await session.authenticateCSRF()
            } catch {
                // 에러가 발생할 수 있지만 메서드 자체는 존재해야 함
                XCTAssertTrue(error is YFError)
            }
        }
    }
    
    func testYFSessionCookieFileExists() {
        // Red: 분리된 YFSessionCookie.swift 파일이 존재해야 함  
        let session = YFSession()
        
        // User-Agent 관련 메서드가 접근 가능해야 함
        let userAgent = session.defaultHeaders["User-Agent"]
        XCTAssertNotNil(userAgent)
        XCTAssertTrue(userAgent!.contains("Chrome"))
    }
}