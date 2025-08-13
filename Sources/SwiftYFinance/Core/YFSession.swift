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
public final class YFSession: @unchecked Sendable {
    // MARK: - Public Properties
    public let urlSession: URLSession
    public let baseURL: URL
    public let timeout: TimeInterval
    public let proxy: [String: Any]?
    
    // MARK: - Private Properties
    private let additionalHeaders: [String: String]
    
    // 상태 관리 (Thread-safe actor)
    internal let sessionState = YFSessionState()
    
    // Immutable components
    internal let htmlParser = YFHTMLParser()
    internal let browserImpersonator = YFBrowserImpersonator()
    internal let networkLogger = YFNetworkLogger.shared
    
    // MARK: - Computed Properties
    
    /// Chrome 브라우저 완전 모방 HTTP 헤더 (YFBrowserImpersonator 활용)
    public var defaultHeaders: [String: String] {
        var headers = browserImpersonator.getChrome136Headers()
        
        // 추가 헤더 적용
        for (key, value) in additionalHeaders {
            headers[key] = value
        }
        
        return headers
    }
    
    /// 현재 쿠키 전략 (async)
    var cookieStrategy: CookieStrategy {
        get async {
            await sessionState.cookieStrategy
        }
    }
    
    /// Crumb 토큰 (async)
    var crumbToken: String? {
        get async {
            await sessionState.crumbToken
        }
    }
    
    /// 인증 상태 (async)  
    var isAuthenticated: Bool {
        get async {
            await sessionState.isAuthenticated
        }
    }
    
    // MARK: - Initialization
    
    /// YFSession 초기화 (Phase 4.5.3 네트워크 최적화)
    /// - Parameters:
    ///   - baseURL: 기본 API URL (기본값: query2.finance.yahoo.com)
    ///   - timeout: 요청 타임아웃 (기본값: 15초로 단축)
    ///   - additionalHeaders: 추가 HTTP 헤더
    ///   - proxy: 프록시 설정
    public init(
        baseURL: URL = URL(string: "https://query2.finance.yahoo.com")!,
        timeout: TimeInterval = 15.0,  // Phase 4.5.3: 30초 → 15초 단축
        additionalHeaders: [String: String] = [:],
        proxy: [String: Any]? = nil
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.additionalHeaders = additionalHeaders
        self.proxy = proxy
        
        // YFBrowserImpersonator를 사용한 네트워크 최적화된 URLSession 생성
        self.urlSession = browserImpersonator.createConfiguredURLSession()
        
        // 프록시 설정이 있는 경우 적용
        if let proxy = proxy {
            let config = self.urlSession.configuration
            config.connectionProxyDictionary = proxy
        }
    }
}