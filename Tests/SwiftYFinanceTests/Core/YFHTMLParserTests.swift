import Testing
import Foundation
@testable import SwiftYFinance

struct YFHTMLParserTests {
    
    @Test
    func testExtractCSRFToken() throws {
        let parser = YFHTMLParser()
        
        // 실제 Yahoo 동의 페이지와 유사한 HTML 구조 (간소화)
        let html = """
        <!DOCTYPE html>
        <html>
        <head><title>Yahoo Consent</title></head>
        <body>
            <form>
                <input type="hidden" name="csrfToken" value="A1B2C3D4E5F6G7H8" />
                <input type="hidden" name="sessionId" value="session_12345" />
                <input type="checkbox" name="agree" value="agree" />
                <button type="submit">Accept</button>
            </form>
        </body>
        </html>
        """
        
        let csrfToken = parser.extractCSRFToken(from: html)
        
        #expect(csrfToken == "A1B2C3D4E5F6G7H8")
    }
    
    @Test
    func testExtractSessionId() throws {
        let parser = YFHTMLParser()
        
        let html = """
        <form action="/consent">
            <input name="csrfToken" value="token123" type="hidden">
            <input name="sessionId" value="sess_abcdef" type="hidden">
        </form>
        """
        
        let sessionId = parser.extractSessionId(from: html)
        
        #expect(sessionId == "sess_abcdef")
    }
    
    @Test
    func testExtractConsentTokens() throws {
        let parser = YFHTMLParser()
        
        let html = """
        <div>
            <input name="csrfToken" value="csrf_token_value" />
            <input name="sessionId" value="session_id_value" />
            <input name="other" value="ignore_this" />
        </div>
        """
        
        let tokens = parser.extractConsentTokens(from: html)
        
        #expect(tokens["csrfToken"] == "csrf_token_value")
        #expect(tokens["sessionId"] == "session_id_value")
        #expect(tokens["other"] == nil)
    }
    
    @Test
    func testExtractFromInvalidHTML() throws {
        let parser = YFHTMLParser()
        
        let invalidHTML = """
        <html>
            <body>
                <p>No tokens here</p>
                <input name="username" value="john" />
            </body>
        </html>
        """
        
        let csrfToken = parser.extractCSRFToken(from: invalidHTML)
        let sessionId = parser.extractSessionId(from: invalidHTML)
        
        #expect(csrfToken == nil)
        #expect(sessionId == nil)
    }
    
    @Test
    func testExtractWithDifferentQuotes() throws {
        let parser = YFHTMLParser()
        
        // 단일 따옴표와 이중 따옴표 혼합 테스트
        let html1 = "<input name='csrfToken' value=\"token_with_mixed_quotes\" />"
        let html2 = "<input name=\"sessionId\" value='session_with_mixed_quotes' />"
        
        let csrfToken = parser.extractCSRFToken(from: html1)
        let sessionId = parser.extractSessionId(from: html2)
        
        #expect(csrfToken == "token_with_mixed_quotes")
        #expect(sessionId == "session_with_mixed_quotes")
    }
    
    @Test
    func testExtractWithExtraAttributes() throws {
        let parser = YFHTMLParser()
        
        // 추가 속성이 있는 input 태그 테스트
        let html = """
        <input type="hidden" class="form-control" name="csrfToken" 
               id="csrf" data-test="true" value="complex_token_123" required />
        <input type="hidden" 
               name="sessionId" 
               value="complex_session_456"
               data-expires="3600" />
        """
        
        let tokens = parser.extractConsentTokens(from: html)
        
        #expect(tokens["csrfToken"] == "complex_token_123")
        #expect(tokens["sessionId"] == "complex_session_456")
    }
}