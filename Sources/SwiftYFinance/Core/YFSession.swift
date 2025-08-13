import Foundation

/// 쿠키 인증 전략
/// - SeeAlso: yfinance-reference/yfinance/data.py _cookie_strategy
public enum CookieStrategy: Sendable {
    case basic
    case csrf
}

/// Yahoo Finance API 세션 관리자
/// 
/// 이 클래스는 Yahoo Finance API와의 네트워크 통신을 관리하며,
/// 브라우저 수준의 쿠키 관리, User-Agent 로테이션, CSRF 인증을 제공합니다.
///
/// ## 기능
/// - **네트워크 세션**: URLSession 기반 HTTP 통신
/// - **헤더 관리**: Chrome 브라우저 모방 헤더 자동 설정
/// - **User-Agent 로테이션**: 탐지 방지를 위한 다중 User-Agent 지원
/// - **CSRF 인증**: Yahoo Finance 인증 시스템 호환
///
/// ## 사용 예시
/// ```swift
/// let session = YFSession()
/// try await session.authenticateCSRF()
/// 
/// let url = session.addCrumbIfNeeded(to: someURL)
/// // 네트워크 요청 수행...
/// ```
public class YFSession {
    // MARK: - Public Properties
    public let urlSession: URLSession
    public let baseURL: URL
    public let timeout: TimeInterval
    public let proxy: [String: Any]?
    
    // MARK: - Private Properties
    private let additionalHeaders: [String: String]
    
    // CSRF 인증 관련 프로퍼티
    internal var cookieStrategy: CookieStrategy = .basic
    internal var crumbToken: String?
    internal let htmlParser = YFHTMLParser()
    internal var isAuthenticated = false
    
    // User-Agent 로테이션을 위한 Chrome 버전들
    internal static let chromeUserAgents = [
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36"
    ]
    internal var currentUserAgentIndex = 0
    
    // MARK: - Computed Properties
    
    /// Chrome 브라우저 완전 모방 HTTP 헤더
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
    
    // MARK: - Initialization
    
    /// YFSession 초기화
    /// - Parameters:
    ///   - baseURL: 기본 API URL (기본값: query2.finance.yahoo.com)
    ///   - timeout: 요청 타임아웃 (기본값: 30초)
    ///   - additionalHeaders: 추가 HTTP 헤더
    ///   - proxy: 프록시 설정
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
}