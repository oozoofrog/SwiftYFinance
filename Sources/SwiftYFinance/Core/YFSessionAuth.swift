import Foundation

extension YFSession {
    // MARK: - CSRF 인증 메서드들
    
    /// Yahoo Finance 인증 프로세스 (Rate Limiting 지원)
    /// - SeeAlso: yfinance-reference/yfinance/data.py:_get_cookie_and_crumb()
    public func authenticateCSRF() async throws {
        // Rate limiter를 통해 인증 요청 실행
        try await performAuthenticationWithRateLimit()
    }
    
    /// Rate limiting과 함께 인증 수행
    ///
    /// YFRateLimiter를 통해 인증 요청 빈도를 제한하여 Yahoo Finance API 차단을 방지합니다.
    /// 내부적으로 재시도 로직과 전략 전환을 포함합니다.
    ///
    /// - Throws: ``YFError/apiError`` 모든 전략이 실패한 경우
    private func performAuthenticationWithRateLimit() async throws {
        // Rate limiting 적용
        await YFRateLimiter.shared.executeRequest {
            // 인증 수행
        }
        
        // 실제 인증 로직 실행
        try await performAuthenticationWithRetry()
    }
    
    /// 전략 전환과 재시도를 포함한 인증 수행
    /// Python yfinance의 전략 전환 로직과 동일
    private func performAuthenticationWithRetry() async throws {
        // 1차 시도: 현재 전략으로 인증
        let success = await attemptAuthenticationWithCurrentStrategy()
        
        if success {
            await sessionState.setAuthenticated(true)
            return
        }
        
        // 1차 실패 시 전략 전환 후 재시도
        await sessionState.toggleCookieStrategy()
        let retrySuccess = await attemptAuthenticationWithCurrentStrategy()
        
        if retrySuccess {
            await sessionState.setAuthenticated(true)
            return
        }
        
        // 두 전략 모두 실패 시 예외 발생
        throw YFError.apiError("Failed to authenticate with both basic and csrf strategies")
    }
    
    /// 현재 쿠키 전략으로 인증 시도
    private func attemptAuthenticationWithCurrentStrategy() async -> Bool {
        let strategy = await sessionState.cookieStrategy
        switch strategy {
        case .basic:
            return await attemptBasicAuthentication()
        case .csrf:
            return await attemptCSRFAuthentication()
        }
    }
    
    /// CSRF 전략으로 인증 시도
    /// - SeeAlso: yfinance-reference/yfinance/data.py:_get_crumb_csrf()
    internal func attemptCSRFAuthentication() async -> Bool {
        // 1. 동의 페이지에서 CSRF 토큰 획득
        guard let tokens = await getConsentTokens() else {
            return false
        }

        // 2. 동의 프로세스 실행
        guard await processConsent(tokens: tokens) else {
            return false
        }

        // 3. Crumb 토큰 획득
        return await getCrumbToken(strategy: .csrf)
    }
    
    /// Basic 전략으로 인증 시도  
    /// - SeeAlso: yfinance-reference/yfinance/data.py:_get_cookie_and_crumb_basic()
    internal func attemptBasicAuthentication() async -> Bool {
        // 1. 기본 쿠키 획득 (fc.yahoo.com 접근)
        if !(await getBasicCookie()) {
            return false
        }
        
        // 2. Crumb 토큰 획득
        return await getCrumbToken(strategy: .basic)
    }
    
    /// 기본 쿠키 획득 (fc.yahoo.com)
    /// - SeeAlso: yfinance-reference/yfinance/data.py:_get_cookie_basic()
    private func getBasicCookie() async -> Bool {
        do {
            let url = URL(string: "https://fc.yahoo.com")!
            var request = URLRequest(url: url, timeoutInterval: timeout)
            
            // 기본 헤더 설정
            for (key, value) in defaultHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            let (_, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            
            // 200-299 범위의 응답이면 성공
            return (200...299).contains(httpResponse.statusCode)
            
        } catch {
            // DNS 에러 등 네트워크 오류도 허용 (Python 구현과 동일)
            return false
        }
    }
    
    /// 동의 페이지에서 CSRF 토큰과 세션 ID 획득
    /// - SeeAlso: yfinance-reference/yfinance/data.py:_get_cookie_csrf() consent 처리
    internal func getConsentTokens() async -> [String: String]? {
        do {
            let url = URL(string: "https://guce.yahoo.com/consent")!
            var request = URLRequest(url: url, timeoutInterval: timeout)
            
            // 기본 헤더 설정
            for (key, value) in defaultHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            let html = String(data: data, encoding: .utf8) ?? ""
            let tokens = htmlParser.extractConsentTokens(from: html)
            
            return tokens.count >= 2 ? tokens : nil
            
        } catch {
            return nil
        }
    }
    
    /// 동의 프로세스 실행
    /// - SeeAlso: yfinance-reference/yfinance/data.py consent POST 요청
    internal func processConsent(tokens: [String: String]) async -> Bool {
        guard let csrfToken = tokens["csrfToken"],
              let sessionId = tokens["sessionId"] else {
            return false
        }
        
        do {
            // POST 요청으로 동의 처리
            let postURL = URL(string: "https://consent.yahoo.com/v2/collectConsent?sessionId=\(sessionId)")!
            var postRequest = URLRequest(url: postURL, timeoutInterval: timeout)
            postRequest.httpMethod = "POST"
            
            // 동의 데이터 구성
            let postData = [
                "agree": "agree",
                "consentUUID": "default", 
                "sessionId": sessionId,
                "csrfToken": csrfToken,
                "originalDoneUrl": "https://finance.yahoo.com/",
                "namespace": "yahoo"
            ]
            
            postRequest.httpBody = try encodeFormData(postData)
            postRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            let (_, response) = try await urlSession.data(for: postRequest)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return false
            }
            
            // GET 요청으로 동의 복사
            let getURL = URL(string: "https://guce.yahoo.com/copyConsent?sessionId=\(sessionId)")!
            let getRequest = URLRequest(url: getURL, timeoutInterval: timeout)
            
            let (_, getResponse) = try await urlSession.data(for: getRequest)
            
            guard let getHttpResponse = getResponse as? HTTPURLResponse,
                  (200...299).contains(getHttpResponse.statusCode) else {
                return false
            }
            
            return true
            
        } catch {
            return false
        }
    }
    
    /// Crumb 토큰 획득
    /// - SeeAlso: yfinance-reference/yfinance/data.py:_get_crumb_basic() / _get_crumb_csrf()
    internal func getCrumbToken(strategy: CookieStrategy) async -> Bool {
        do {
            let baseURLString = strategy == .csrf ? 
                "https://query2.finance.yahoo.com" : 
                "https://query1.finance.yahoo.com"
            
            let url = URL(string: "\(baseURLString)/v1/test/getcrumb")!
            var request = URLRequest(url: url, timeoutInterval: timeout)
            
            for (key, value) in defaultHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            
            // Rate limiting 체크 (Python yfinance와 동일)
            if httpResponse.statusCode == 429 {
                return false  // 429 에러 시 false 반환하여 전략 전환 유도
            }
            
            guard httpResponse.statusCode == 200 else {
                return false
            }
            
            let crumb = String(data: data, encoding: .utf8) ?? ""
            
            // 유효한 crumb인지 확인 (Python yfinance와 동일)
            if crumb.isEmpty || crumb.contains("<html>") || crumb.contains("Too Many Requests") {
                return false
            }
            
            await sessionState.setCrumbToken(crumb)
            return true
            
        } catch {
            return false
        }
    }
    
    /// 쿠키 전략 전환
    /// - SeeAlso: yfinance-reference/yfinance/data.py:_set_cookie_strategy()
    internal func toggleCookieStrategy() async {
        await sessionState.toggleCookieStrategy()
        
        // 쿠키 초기화
        urlSession.configuration.httpCookieStorage?.removeCookies(since: Date.distantPast)
    }
    
    /// URL 요청에 crumb 파라미터 자동 추가
    /// - SeeAlso: yfinance-reference/yfinance/data.py:get() 메서드
    public func addCrumbIfNeeded(to url: URL) async -> URL {
        guard let crumb = await sessionState.crumbToken,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        
        // 이미 crumb이 있는지 확인
        if components.queryItems?.contains(where: { $0.name == "crumb" }) == true {
            return url
        }
        
        // crumb 파라미터 추가
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: "crumb", value: crumb))
        components.queryItems = queryItems
        
        return components.url ?? url
    }
    
    /// Form data 인코딩 헬퍼
    internal func encodeFormData(_ data: [String: String]) throws -> Data {
        let formString = data.map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")
        
        return formString.data(using: .utf8) ?? Data()
    }
    
    /// 현재 인증 상태 확인
    public var isCSRFAuthenticated: Bool {
        get async {
            await sessionState.isCSRFAuthenticated
        }
    }
    
    /// API 요청을 Rate Limiting과 자동 재인증과 함께 실행
    ///
    /// Python yfinance의 _make_request() 메서드와 동일한 로직을 구현합니다.
    /// 요청 실패 시 자동으로 재인증하고 전략을 전환하여 재시도합니다.
    ///
    /// ## 주요 기능
    /// - **Rate Limiting**: 요청 빈도 제한으로 차단 방지
    /// - **자동 인증**: 인증되지 않은 상태에서 자동으로 인증 수행  
    /// - **Crumb 자동 추가**: URL에 필요한 crumb 파라미터 자동 추가
    /// - **재시도 로직**: 실패 시 전략 전환 후 자동 재시도
    ///
    /// ## 사용 예시
    /// ```swift
    /// let url = URL(string: "https://query2.finance.yahoo.com/v8/finance/chart/AAPL")!
    /// let (data, response) = try await session.makeAuthenticatedRequest(url: url)
    /// ```
    ///
    /// - Parameters:
    ///   - url: 요청할 API URL
    ///   - method: HTTP 메서드 (기본값: GET)
    ///   - body: POST 요청시 전송할 데이터 (옵셔널)
    /// - Returns: API 응답 데이터와 URLResponse 튜플
    /// - Throws: ``YFError`` 네트워크 오류 또는 인증 실패시
    public func makeAuthenticatedRequest(url: URL, method: HTTPMethod = .GET, body: Data? = nil) async throws -> (Data, URLResponse) {
        return try await YFRateLimiter.shared.executeRequest {
            return try await self.performRequestWithAuth(url: url, method: method, body: body)
        }
    }
    
    /// 인증이 포함된 요청 수행 (재시도 로직 포함)
    private func performRequestWithAuth(url: URL, method: HTTPMethod, body: Data?) async throws -> (Data, URLResponse) {
        // 인증되지 않았다면 먼저 인증 시도
        let authenticated = await sessionState.isAuthenticated
        if !authenticated {
            try await authenticateCSRF()
        }
        
        // crumb이 필요한 URL에 자동 추가
        let urlWithCrumb = await addCrumbIfNeeded(to: url)
        
        // 첫 번째 요청 시도
        let result = try await executeHTTPRequest(url: urlWithCrumb, method: method, body: body)
        
        // 응답 상태 확인
        if let httpResponse = result.1 as? HTTPURLResponse {
            if httpResponse.statusCode >= 400 {
                // 실패 시 전략 전환 후 재시도 (Python yfinance와 동일)
                await sessionState.toggleCookieStrategy()
                try await authenticateCSRF()
                
                let urlWithNewCrumb = await addCrumbIfNeeded(to: url)
                return try await executeHTTPRequest(url: urlWithNewCrumb, method: method, body: body)
            }
        }
        
        return result
    }
    
    /// 실제 HTTP 요청 실행
    private func executeHTTPRequest(url: URL, method: HTTPMethod, body: Data?) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method.rawValue
        
        // 기본 헤더 설정
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // POST 요청에 body 추가
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return try await urlSession.data(for: request)
    }
}

/// HTTP 메서드 열거형
///
/// Yahoo Finance API 요청에 사용되는 HTTP 메서드를 정의합니다.
/// 대부분의 API는 GET 요청을 사용하지만, 일부 고급 기능에서는 POST를 사용합니다.
public enum HTTPMethod: String, Sendable {
    
    /// GET 메서드
    ///
    /// 데이터 조회용으로 사용됩니다. Yahoo Finance API의 대부분이 GET 요청입니다.
    case GET = "GET"
    
    /// POST 메서드  
    ///
    /// 데이터 전송이 필요한 요청에 사용됩니다. 주로 동의 처리나 복잡한 쿼리에서 사용됩니다.
    case POST = "POST"
}
