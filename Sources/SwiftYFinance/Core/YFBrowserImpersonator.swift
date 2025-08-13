import Foundation

/// Yahoo Finance API 접근을 위한 브라우저 모방 기능
/// 
/// curl_cffi의 Chrome 136 설정을 Swift URLSession에 적용하여
/// Yahoo Finance의 탐지 시스템을 우회합니다.
///
/// ## 기능
/// - **Chrome 136 모방**: 최신 Chrome 브라우저 시그니처 사용
/// - **Header 최적화**: 브라우저와 동일한 헤더 순서 및 값
/// - **User-Agent 로테이션**: 탐지 방지를 위한 다중 User-Agent
/// - **URLSession 설정**: Chrome과 유사한 네트워크 설정
///
/// ## 사용 예시
/// ```swift
/// let impersonator = YFBrowserImpersonator()
/// let session = impersonator.createConfiguredURLSession()
/// let headers = impersonator.getChrome136Headers()
/// ```
///
/// - SeeAlso: curl_cffi-reference/curl_cffi/requests/impersonate.py
public class YFBrowserImpersonator {
    
    // MARK: - Chrome 136 User-Agent (curl_cffi DEFAULT_CHROME = "chrome136")
    
    /// Chrome 136 User-Agent 배열 (curl_cffi와 동기화)
    /// - SeeAlso: curl_cffi DEFAULT_CHROME = "chrome136"
    private static let chrome136UserAgents = [
        // macOS Chrome 136
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36",
        
        // Windows Chrome 136  
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36"
    ]
    
    private var currentUserAgentIndex = 0
    
    // MARK: - Initialization
    
    public init() {
        // 초기화 시 랜덤 User-Agent 선택 (탐지 방지)
        self.currentUserAgentIndex = Int.random(in: 0..<Self.chrome136UserAgents.count)
    }
    
    // MARK: - User-Agent Management
    
    /// 현재 User-Agent 반환
    public func getCurrentUserAgent() -> String {
        return Self.chrome136UserAgents[currentUserAgentIndex]
    }
    
    /// User-Agent 로테이션 (탐지 방지)
    public func rotateUserAgent() {
        currentUserAgentIndex = (currentUserAgentIndex + 1) % Self.chrome136UserAgents.count
    }
    
    /// 랜덤 User-Agent 선택
    public func randomizeUserAgent() {
        currentUserAgentIndex = Int.random(in: 0..<Self.chrome136UserAgents.count)
    }
    
    // MARK: - Chrome 136 Headers
    
    /// Chrome 136과 동일한 HTTP 헤더 반환
    /// - SeeAlso: curl_cffi chrome136 fingerprint
    public func getChrome136Headers() -> [String: String] {
        return [
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
            "Sec-CH-UA": "\"Not A(Brand\";v=\"99\", \"Google Chrome\";v=\"136\", \"Chromium\";v=\"136\"",
            "Sec-CH-UA-Mobile": "?0",
            "Sec-CH-UA-Platform": "\"macOS\"",
            "Cache-Control": "max-age=0"
        ]
    }
    
    // MARK: - URLSession Configuration
    
    /// Chrome 136과 유사한 URLSession 생성
    /// - Returns: 최적화된 URLSession
    public func createConfiguredURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        
        // Chrome과 유사한 네트워크 설정
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 30.0
        config.httpMaximumConnectionsPerHost = 6  // Chrome 기본값
        
        // HTTP/2 및 쿠키 설정
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        
        // Keep-alive 연결 최적화
        config.requestCachePolicy = .useProtocolCachePolicy
        config.urlCache = URLCache.shared
        
        return URLSession(configuration: config)
    }
    
    // MARK: - Request Configuration
    
    /// URLRequest에 Chrome 136 헤더 적용
    /// - Parameter request: 대상 URLRequest
    public func configureRequest(_ request: inout URLRequest) {
        let headers = getChrome136Headers()
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
    
    /// URLRequest 생성 및 Chrome 136 헤더 적용
    /// - Parameters:
    ///   - url: 대상 URL
    ///   - timeoutInterval: 타임아웃 (기본 30초)
    /// - Returns: 설정된 URLRequest
    public func createConfiguredRequest(url: URL, timeoutInterval: TimeInterval = 30.0) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        configureRequest(&request)
        return request
    }
}