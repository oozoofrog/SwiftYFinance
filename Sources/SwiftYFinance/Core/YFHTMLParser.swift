import Foundation

/// Yahoo Finance HTML 응답에서 필요한 데이터를 추출하는 파서
/// yfinance-reference/yfinance/data.py의 BeautifulSoup 로직을 Swift로 구현
class YFHTMLParser {
    
    /// HTML에서 CSRF 토큰을 추출
    /// - Parameter html: HTML 문자열
    /// - Returns: CSRF 토큰 값 또는 nil
    /// - SeeAlso: yfinance-reference/yfinance/data.py:_get_cookie_csrf() BeautifulSoup 파싱
    func extractCSRFToken(from html: String) -> String? {
        // <input name="csrfToken" value="TOKEN_VALUE"> 패턴 검색
        let pattern = #"<input[^>]*name\s*=\s*[\"']csrfToken[\"'][^>]*value\s*=\s*[\"']([^\"']+)[\"'][^>]*>"#
        
        return extractValue(from: html, pattern: pattern)
    }
    
    /// HTML에서 세션 ID를 추출
    /// - Parameter html: HTML 문자열
    /// - Returns: 세션 ID 값 또는 nil
    /// - SeeAlso: yfinance-reference/yfinance/data.py:_get_cookie_csrf() sessionId 처리
    func extractSessionId(from html: String) -> String? {
        // <input name="sessionId" value="SESSION_VALUE"> 패턴 검색
        let pattern = #"<input[^>]*name\s*=\s*[\"']sessionId[\"'][^>]*value\s*=\s*[\"']([^\"']+)[\"'][^>]*>"#
        
        return extractValue(from: html, pattern: pattern)
    }
    
    /// 정규표현식을 사용하여 HTML에서 값을 추출하는 헬퍼 메서드
    /// - Parameters:
    ///   - html: 검색할 HTML 문자열
    ///   - pattern: 정규표현식 패턴
    /// - Returns: 추출된 값 또는 nil
    private func extractValue(from html: String, pattern: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
            let range = NSRange(location: 0, length: html.utf16.count)
            
            if let match = regex.firstMatch(in: html, options: [], range: range) {
                if match.numberOfRanges > 1 {
                    let valueRange = match.range(at: 1)
                    if let swiftRange = Range(valueRange, in: html) {
                        return String(html[swiftRange])
                    }
                }
            }
        } catch {
            // 정규표현식 오류 처리
            return nil
        }
        
        return nil
    }
    
    /// HTML에서 여러 input 값을 한번에 추출
    /// - Parameter html: HTML 문자열
    /// - Returns: csrfToken과 sessionId를 포함한 딕셔너리
    func extractConsentTokens(from html: String) -> [String: String] {
        var tokens: [String: String] = [:]
        
        if let csrfToken = extractCSRFToken(from: html) {
            tokens["csrfToken"] = csrfToken
        }
        
        if let sessionId = extractSessionId(from: html) {
            tokens["sessionId"] = sessionId
        }
        
        return tokens
    }
}