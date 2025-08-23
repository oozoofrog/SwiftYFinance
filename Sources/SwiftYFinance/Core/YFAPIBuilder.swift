import Foundation

/// Yahoo Finance API URL 구성을 위한 Builder 패턴 클래스
///
/// URL 구성의 단일 책임을 가지며, 유창한(fluent) 인터페이스를 제공합니다.
/// Session의 인증 상태에 따라 적절한 crumb 파라미터 추가를 자동으로 처리합니다.
/// 
/// **중요**: 이 클래스는 Sendable하며 thread-safe합니다. 각 메서드 호출 시 새로운 인스턴스를 반환합니다.
///
/// ## 사용 예시
/// ```swift
/// let url = try await YFAPIBuilder(session: session)
///     .url(YFPaths.quoteSummary + "/AAPL")
///     .parameter("modules", "price,summaryDetail")
///     .parameter("formatted", "false")
///     .build()
/// ```
public struct YFAPIBuilder: Sendable {
    
    // MARK: - Private State Container
    
    /// Builder의 모든 mutable 상태를 격리하는 컨테이너
    private struct BuilderState: Sendable {
        let host: URL
        let path: String
        let parameters: [String: String]
        
        init(host: URL = URL(string: "https://finance.yahoo.com")!, path: String = "", parameters: [String: String] = [:]) {
            self.host = host
            self.path = path
            self.parameters = parameters
        }
        
        
        func withPath(_ path: String) -> BuilderState {
            BuilderState(host: host, path: path, parameters: parameters)
        }
        
        func withParameter(_ key: String, _ value: String) -> BuilderState {
            var newParameters = parameters
            newParameters[key] = value
            return BuilderState(host: host, path: path, parameters: newParameters)
        }
        
        func withParameters(_ newParameters: [String: String]) -> BuilderState {
            var mergedParameters = parameters
            for (key, value) in newParameters {
                mergedParameters[key] = value
            }
            return BuilderState(host: host, path: path, parameters: mergedParameters)
        }
    }
    
    // MARK: - Properties
    
    private let session: YFSession
    private let state: BuilderState
    
    // MARK: - Initialization
    
    /// YFAPIBuilder 초기화
    /// - Parameter session: 인증 상태 확인 및 crumb 추가를 위한 YFSession
    public init(session: YFSession) {
        self.session = session
        self.state = BuilderState()
    }
    
    /// 내부 상태와 함께 YFAPIBuilder 초기화
    private init(session: YFSession, state: BuilderState) {
        self.session = session
        self.state = state
    }
    
    // MARK: - Builder Methods
    
    
    /// API 경로 설정
    /// - Parameter path: API 경로 (예: "/v10/finance/quoteSummary/AAPL")
    /// - Returns: 새로운 Builder 인스턴스 (체이닝을 위함)
    @discardableResult
    public func path(_ path: String) -> YFAPIBuilder {
        return YFAPIBuilder(session: session, state: state.withPath(path))
    }
    
    /// 완전한 URL 설정 (호스트 + 경로 포함)
    /// - Parameter urlString: 완전한 URL 문자열 (예: YFPaths.quote)
    /// - Returns: 새로운 Builder 인스턴스 (체이닝을 위함)
    @discardableResult
    public func url(_ urlString: String) -> YFAPIBuilder {
        guard let url = URL(string: urlString) else {
            // URL이 잘못된 경우 기본값으로 설정 (에러는 build()에서 발생)
            return self
        }
        let host = URL(string: "\(url.scheme!)://\(url.host!)")!
        let path = url.path
        let newState = BuilderState(host: host, path: path, parameters: state.parameters)
        return YFAPIBuilder(session: session, state: newState)
    }
    
    /// 쿼리 파라미터 추가
    /// - Parameters:
    ///   - key: 파라미터 키
    ///   - value: 파라미터 값
    /// - Returns: 새로운 Builder 인스턴스 (체이닝을 위함)
    @discardableResult
    public func parameter(_ key: String, _ value: String) -> YFAPIBuilder {
        return YFAPIBuilder(session: session, state: state.withParameter(key, value))
    }
    
    /// 여러 쿼리 파라미터를 한 번에 추가
    /// - Parameter parameters: 파라미터 딕셔너리
    /// - Returns: 새로운 Builder 인스턴스 (체이닝을 위함)
    @discardableResult
    public func parameters(_ parameters: [String: String]) -> YFAPIBuilder {
        return YFAPIBuilder(session: session, state: state.withParameters(parameters))
    }
    
    // MARK: - URL Building
    
    /// 설정된 값들로 최종 URL을 구성합니다
    /// 
    /// 호스트와 경로를 결합하여 기본 URL을 만들고, 쿼리 파라미터를 추가합니다.
    /// CSRF 인증된 경우 자동으로 crumb 파라미터를 추가합니다.
    ///
    /// - Returns: 완전히 구성된 API 요청 URL
    /// - Throws: URL 구성에 실패한 경우
    public func build() async throws -> URL {
        // 기본 URL 구성 (host는 항상 non-nil이므로 검증 불필요)
        let baseURL = state.host.absoluteString + state.path
        
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw YFError.invalidURL
        }
        
        // 쿼리 파라미터 추가
        if !state.parameters.isEmpty {
            urlComponents.queryItems = state.parameters.map { key, value in
                URLQueryItem(name: key, value: value)
            }
        }
        
        guard let url = urlComponents.url else {
            throw YFError.invalidURL
        }
        
        // CSRF 인증된 경우 crumb 파라미터 추가
        let isAuthenticated = await session.isCSRFAuthenticated
        return isAuthenticated ? await session.addCrumbIfNeeded(to: url) : url
    }
    
    /// 설정된 값들로 URLRequest를 구성합니다
    ///
    /// URL 구성과 함께 세션의 기본 헤더, 타임아웃 등을 포함한 완전한 URLRequest를 생성합니다.
    /// CSRF 인증된 경우 자동으로 crumb 파라미터를 추가합니다.
    ///
    /// - Parameter additionalHeaders: 추가할 HTTP 헤더 (기본값: 빈 딕셔너리)
    /// - Returns: 완전히 구성된 URLRequest
    /// - Throws: URL 구성에 실패한 경우
    public func buildRequest(additionalHeaders: [String: String] = [:]) async throws -> URLRequest {
        let url = try await build()
        
        var request = URLRequest(url: url)
        request.timeoutInterval = session.timeout
        
        // 세션의 기본 헤더 적용
        for (key, value) in session.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 추가 헤더 적용
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
}