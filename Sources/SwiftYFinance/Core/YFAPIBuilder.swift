import Foundation

/// Yahoo Finance API URL 구성을 위한 Builder 패턴 클래스
///
/// URL 구성의 단일 책임을 가지며, 유창한(fluent) 인터페이스를 제공합니다.
/// Session의 인증 상태에 따라 적절한 crumb 파라미터 추가를 자동으로 처리합니다.
/// 
/// **중요**: 이 클래스는 일회용입니다. `build()` 호출 후 재사용하지 마세요.
///
/// ## 사용 예시
/// ```swift
/// let url = try await YFAPIBuilder(session: session)
///     .host(YFHosts.query2)
///     .path(YFPaths.quoteSummary + "/AAPL")
///     .parameter("modules", "price,summaryDetail")
///     .parameter("formatted", "false")
///     .build()
/// ```
public final class YFAPIBuilder {
    
    // MARK: - Properties
    
    private let session: YFSession
    private var host: URL?
    private var path: String = ""
    private var parameters: [String: String] = [:]
    
    // MARK: - Initialization
    
    /// YFAPIBuilder 초기화
    /// - Parameter session: 인증 상태 확인 및 crumb 추가를 위한 YFSession
    public init(session: YFSession) {
        self.session = session
    }
    
    // MARK: - Builder Methods
    
    /// 호스트 URL 설정
    /// - Parameter host: 대상 호스트 (예: YFHosts.query2)
    /// - Returns: Builder 인스턴스 (체이닝을 위함)
    @discardableResult
    public func host(_ host: URL) -> YFAPIBuilder {
        self.host = host
        return self
    }
    
    /// API 경로 설정
    /// - Parameter path: API 경로 (예: YFPaths.quoteSummary + "/AAPL")
    /// - Returns: Builder 인스턴스 (체이닝을 위함)
    @discardableResult
    public func path(_ path: String) -> YFAPIBuilder {
        self.path = path
        return self
    }
    
    /// 쿼리 파라미터 추가
    /// - Parameters:
    ///   - key: 파라미터 키
    ///   - value: 파라미터 값
    /// - Returns: Builder 인스턴스 (체이닝을 위함)
    @discardableResult
    public func parameter(_ key: String, _ value: String) -> YFAPIBuilder {
        parameters[key] = value
        return self
    }
    
    /// 여러 쿼리 파라미터를 한 번에 추가
    /// - Parameter parameters: 파라미터 딕셔너리
    /// - Returns: Builder 인스턴스 (체이닝을 위함)
    @discardableResult
    public func parameters(_ parameters: [String: String]) -> YFAPIBuilder {
        for (key, value) in parameters {
            self.parameters[key] = value
        }
        return self
    }
    
    // MARK: - URL Building
    
    /// 설정된 값들로 최종 URL을 구성합니다
    /// 
    /// 호스트와 경로를 결합하여 기본 URL을 만들고, 쿼리 파라미터를 추가합니다.
    /// CSRF 인증된 경우 자동으로 crumb 파라미터를 추가합니다.
    ///
    /// - Returns: 완전히 구성된 API 요청 URL
    /// - Throws: 필수 값이 누락되거나 URL 구성에 실패한 경우
    public func build() async throws -> URL {
        // 필수 값 검증
        guard let host = host else {
            throw YFError.invalidRequest // host가 설정되지 않음
        }
        
        // 기본 URL 구성
        let baseURL = host.absoluteString + path
        
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw YFError.invalidURL
        }
        
        // 쿼리 파라미터 추가
        if !parameters.isEmpty {
            urlComponents.queryItems = parameters.map { key, value in
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
    
    // MARK: - Convenience Methods
    
    /// Quote Summary API URL 구성을 위한 편의 메서드
    /// - Parameter ticker: 주식 심볼
    /// - Returns: Builder 인스턴스 (체이닝을 위함)
    @discardableResult
    public func quoteSummary(for ticker: YFTicker) -> YFAPIBuilder {
        return host(YFHosts.query2)
            .path(YFPaths.quoteSummary + "/\(ticker.symbol)")
            .parameter("modules", "price,summaryDetail")
            .parameter("corsDomain", "finance.yahoo.com")
            .parameter("formatted", "false")
    }
    
    /// Chart API URL 구성을 위한 편의 메서드
    /// - Parameter ticker: 주식 심볼
    /// - Returns: Builder 인스턴스 (체이닝을 위함)
    @discardableResult
    public func chart(for ticker: YFTicker) -> YFAPIBuilder {
        return host(YFHosts.query2)
            .path(YFPaths.chart + "/\(ticker.symbol)")
    }
    
    /// Search API URL 구성을 위한 편의 메서드
    /// - Returns: Builder 인스턴스 (체이닝을 위함)
    @discardableResult
    public func search() -> YFAPIBuilder {
        return host(YFHosts.query2)
            .path(YFPaths.search)
    }
    
}

// MARK: - Error Extensions

extension YFError {
    /// API Builder에서 필수 값이 누락된 경우 사용할 에러
    static let invalidRequest = YFError.apiError("Invalid API request: missing required host or path")
}