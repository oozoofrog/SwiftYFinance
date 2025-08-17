import Foundation

/// 쿠키 인증 전략
///
/// Yahoo Finance API 접근을 위한 인증 방법을 정의합니다.
/// Python yfinance와 동일한 두 가지 전략을 지원하며, 실패 시 자동으로 전환됩니다.
///
/// - SeeAlso: yfinance-reference/yfinance/data.py _cookie_strategy
public enum CookieStrategy: Sendable {
    
    /// 기본 인증 전략
    ///
    /// fc.yahoo.com에서 기본 쿠키를 획득한 후 query1.finance.yahoo.com에서 crumb 토큰을 요청합니다.
    /// 가장 간단하고 빠른 방법이지만 차단될 가능성이 있습니다.
    case basic
    
    /// CSRF 인증 전략  
    ///
    /// 동의 페이지를 거쳐 CSRF 토큰을 획득한 후 query2.finance.yahoo.com에서 crumb 토큰을 요청합니다.
    /// 더 안전하고 안정적이지만 추가 단계가 필요합니다.
    case csrf
}

/// Yahoo Finance API 세션 관리자 (Actor 기반)
/// 
/// 이 actor는 Yahoo Finance API와의 네트워크 통신을 관리하며,
/// 브라우저 수준의 쿠키 관리, User-Agent 로테이션, CSRF 인증을 제공합니다.
///
/// ## 기능
/// - **네트워크 세션**: URLSession 기반 HTTP 통신
/// - **헤더 관리**: Chrome 브라우저 모방 헤더 자동 설정
/// - **User-Agent 로테이션**: 탐지 방지를 위한 다중 User-Agent 지원
/// - **CSRF 인증**: Yahoo Finance 인증 시스템 호환
/// - **동시성 안전성**: Swift Actor 모델을 통한 완전한 thread-safety
///
/// ## 사용 예시
/// ```swift
/// let session = YFSession()
/// try await session.authenticateCSRF()
/// 
/// let url = await session.addCrumbIfNeeded(to: someURL)
/// // 네트워크 요청 수행...
/// ```
public final actor YFSession {
    // MARK: - Public Properties
    nonisolated public let urlSession: URLSession
    nonisolated public let baseURL: URL
    nonisolated public let timeout: TimeInterval
    public let proxy: [String: Any]?
    
    // MARK: - Private Properties
    nonisolated private let additionalHeaders: [String: String]
    
    // 상태 관리 (Thread-safe actor)
    internal let sessionState = YFSessionState()
    
    // Immutable components
    nonisolated internal let htmlParser = YFHTMLParser()
    nonisolated internal let browserImpersonator = YFBrowserImpersonator()
    nonisolated internal let networkLogger = YFNetworkLogger.shared
    
    // MARK: - Computed Properties
    
    /// Chrome 브라우저 완전 모방 HTTP 헤더 (YFBrowserImpersonator 활용)
    nonisolated public var defaultHeaders: [String: String] {
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
    
    /// 프록시 설정 (async)
    var proxyConfig: [String: Any]? {
        get async {
            return proxy
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
    
    // MARK: - 테스트 지원
    
    /// 세션 상태 완전 초기화 (테스트용)
    /// 
    /// 테스트 격리를 위해 세션의 모든 상태를 초기값으로 되돌립니다.
    /// 인증 상태, crumb 토큰, 쿠키 전략을 모두 리셋합니다.
    public func resetState() async {
        await sessionState.reset()
    }
}