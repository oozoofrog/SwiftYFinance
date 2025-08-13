import Foundation

/// 쿠키 인증 전략
/// - SeeAlso: yfinance-reference/yfinance/data.py _cookie_strategy
public enum CookieStrategy: Sendable {
    case basic
    case csrf
}

public class YFSession {
    public let urlSession: URLSession
    public let baseURL: URL
    public let timeout: TimeInterval
    public let proxy: [String: Any]?
    private let additionalHeaders: [String: String]
    
    // CSRF 인증 관련 프로퍼티
    private var cookieStrategy: CookieStrategy = .basic
    private var crumbToken: String?
    private let htmlParser = YFHTMLParser()
    private var isAuthenticated = false
    
    // User-Agent 로테이션을 위한 Chrome 버전들
    private static let chromeUserAgents = [
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36"
    ]
    private var currentUserAgentIndex = 0
    
    public var defaultHeaders: [String: String] {
        var headers = [
            "User-Agent": getCurrentUserAgent(),
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
            "Accept-Language": "en-US,en;q=0.9",
            "Accept-Encoding": "gzip, deflate, br, zstd",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": "none",
            "Sec-Fetch-User": "?1",
            "Cache-Control": "max-age=0"
        ]
        
        for (key, value) in additionalHeaders {
            headers[key] = value
        }
        
        return headers
    }
    
    public init(
        baseURL: URL = URL(string: "https://query2.finance.yahoo.com")!,
        timeout: TimeInterval = 30.0,
        additionalHeaders: [String: String] = [:],
        proxy: [String: Any]? = nil
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.additionalHeaders = additionalHeaders
        self.proxy = proxy
        
        // 초기화 시 랜덤 User-Agent 선택 (탐지 방지)
        self.currentUserAgentIndex = Int.random(in: 0..<Self.chromeUserAgents.count)
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        
        // HTTPCookieStorage 설정 - 브라우저 수준 쿠키 관리
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        
        if let proxy = proxy {
            config.connectionProxyDictionary = proxy
        }
        
        self.urlSession = URLSession(configuration: config)
    }
    
    // MARK: - CSRF 인증 메서드들
    
    /// Yahoo Finance CSRF 인증 프로세스
    /// - SeeAlso: yfinance-reference/yfinance/data.py:_get_cookie_and_crumb()
    public func authenticateCSRF() async throws {
        // 전략별로 인증 시도
        let success = cookieStrategy == .csrf ? 
            await attemptCSRFAuthentication() : 
            await attemptBasicAuthentication()
        
        if !success {
            // 현재 전략이 실패하면 다른 전략으로 전환
            toggleCookieStrategy()
            let retrySuccess = cookieStrategy == .csrf ? 
                await attemptCSRFAuthentication() : 
                await attemptBasicAuthentication()
            
            if !retrySuccess {
                throw YFError.apiError("Failed to authenticate with Yahoo Finance")
            }
        }
        
        isAuthenticated = true
    }
    
    /// CSRF 전략으로 인증 시도
    /// - SeeAlso: yfinance-reference/yfinance/data.py:_get_crumb_csrf()
    private func attemptCSRFAuthentication() async -> Bool {
        do {
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
        } catch {
            return false
        }
    }
    
    /// Basic 전략으로 인증 시도  
    /// - SeeAlso: yfinance-reference/yfinance/data.py:_get_cookie_and_crumb_basic()
    private func attemptBasicAuthentication() async -> Bool {
        return await getCrumbToken(strategy: .basic)
    }
    
    /// 동의 페이지에서 CSRF 토큰과 세션 ID 획득
    /// - SeeAlso: yfinance-reference/yfinance/data.py:_get_cookie_csrf() consent 처리
    private func getConsentTokens() async -> [String: String]? {
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
    private func processConsent(tokens: [String: String]) async -> Bool {
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
            var getRequest = URLRequest(url: getURL, timeoutInterval: timeout)
            
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
    private func getCrumbToken(strategy: CookieStrategy) async -> Bool {
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
            
            // Rate limiting 체크
            if httpResponse.statusCode == 429 {
                throw YFError.apiError("Rate limited")
            }
            
            guard httpResponse.statusCode == 200 else {
                return false
            }
            
            let crumb = String(data: data, encoding: .utf8) ?? ""
            
            // 유효한 crumb인지 확인
            guard !crumb.isEmpty && !crumb.contains("<html>") else {
                return false
            }
            
            self.crumbToken = crumb
            return true
            
        } catch {
            return false
        }
    }
    
    /// 쿠키 전략 전환
    /// - SeeAlso: yfinance-reference/yfinance/data.py:_set_cookie_strategy()
    private func toggleCookieStrategy() {
        cookieStrategy = cookieStrategy == .basic ? .csrf : .basic
        crumbToken = nil
        isAuthenticated = false
        
        // 쿠키 초기화
        urlSession.configuration.httpCookieStorage?.removeCookies(since: Date.distantPast)
    }
    
    /// URL 요청에 crumb 파라미터 자동 추가
    /// - SeeAlso: yfinance-reference/yfinance/data.py:get() 메서드
    public func addCrumbIfNeeded(to url: URL) -> URL {
        guard let crumb = crumbToken,
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
    private func encodeFormData(_ data: [String: String]) throws -> Data {
        let formString = data.map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")
        
        return formString.data(using: .utf8) ?? Data()
    }
    
    /// 현재 인증 상태 확인
    public var isCSRFAuthenticated: Bool {
        return isAuthenticated && crumbToken != nil
    }
    
    // MARK: - User-Agent 로테이션 메서드들
    
    /// 현재 User-Agent 반환
    private func getCurrentUserAgent() -> String {
        return Self.chromeUserAgents[currentUserAgentIndex]
    }
    
    /// User-Agent 로테이션 (탐지 방지)
    public func rotateUserAgent() {
        currentUserAgentIndex = (currentUserAgentIndex + 1) % Self.chromeUserAgents.count
    }
    
    /// 랜덤 User-Agent 선택
    public func randomizeUserAgent() {
        currentUserAgentIndex = Int.random(in: 0..<Self.chromeUserAgents.count)
    }
}