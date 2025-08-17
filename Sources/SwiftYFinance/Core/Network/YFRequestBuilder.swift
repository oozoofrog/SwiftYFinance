import Foundation

/// Yahoo Finance API 요청을 구성하는 빌더 클래스
///
/// Fluent 인터페이스 패턴을 사용하여 URLRequest를 단계적으로 구성합니다.
/// 경로, 쿼리 파라미터, 헤더를 체이닝 방식으로 설정할 수 있습니다.
///
/// ## 주요 기능
/// - **경로 설정**: API 엔드포인트 경로 지정
/// - **쿼리 파라미터**: URL 쿼리 문자열 구성
/// - **헤더 관리**: 추가 HTTP 헤더 설정
/// - **세션 통합**: YFSession의 기본 설정 자동 적용
///
/// ## 사용 예시
/// ```swift
/// let session = YFSession()
/// let request = try YFRequestBuilder(session: session)
///     .path("/v8/finance/chart/AAPL")
///     .queryParam("interval", "1d")
///     .queryParam("range", "1mo")
///     .header("X-Custom-Header", "value")
///     .build()
/// 
/// // 생성된 요청 사용
/// let (data, _) = try await URLSession.shared.data(for: request)
/// ```
///
/// ## 메서드 체이닝
/// 모든 설정 메서드는 자기 자신을 반환하여 체이닝이 가능합니다:
/// ```swift
/// builder
///     .path("/api/endpoint")
///     .queryParams(["key1": "value1", "key2": "value2"])
///     .headers(["Accept": "application/json"])
///     .build()
/// ```
///
/// - SeeAlso: ``YFSession``
/// - SeeAlso: ``build()``
public class YFRequestBuilder {
    /// 연결된 세션 객체
    private let session: YFSession
    
    /// API 엔드포인트 경로
    private var pathString: String?
    
    /// URL 쿼리 파라미터 딕셔너리
    private var queryParameters: [String: String] = [:]
    
    /// 추가 HTTP 헤더 딕셔너리
    private var additionalHeaders: [String: String] = [:]
    
    /// RequestBuilder 초기화
    ///
    /// 지정된 세션을 사용하여 새 RequestBuilder를 생성합니다.
    ///
    /// - Parameter session: 요청에 사용할 YFSession 객체
    public init(session: YFSession) {
        self.session = session
    }
    
    /// API 엔드포인트 경로 설정
    ///
    /// Yahoo Finance API의 엔드포인트 경로를 설정합니다.
    /// 경로는 세션의 baseURL에 상대적으로 해석됩니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// builder.path("/v8/finance/chart/AAPL")
    /// // 전체 URL: https://query2.finance.yahoo.com/v8/finance/chart/AAPL
    /// ```
    ///
    /// - Parameter path: API 엔드포인트 경로 (예: "/v8/finance/chart/AAPL")
    /// - Returns: 메서드 체이닝을 위한 self
    public func path(_ path: String) -> YFRequestBuilder {
        self.pathString = path
        return self
    }
    
    /// 단일 쿼리 파라미터 추가
    ///
    /// URL 쿼리 문자열에 키-값 쌍을 추가합니다.
    /// 동일한 키로 여러 번 호출하면 마지막 값으로 덮어씁니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// builder
    ///     .queryParam("interval", "1d")
    ///     .queryParam("range", "1mo")
    /// // 결과: ?interval=1d&range=1mo
    /// ```
    ///
    /// - Parameters:
    ///   - key: 쿼리 파라미터 키
    ///   - value: 쿼리 파라미터 값
    /// - Returns: 메서드 체이닝을 위한 self
    public func queryParam(_ key: String, _ value: String) -> YFRequestBuilder {
        queryParameters[key] = value
        return self
    }
    
    /// 여러 쿼리 파라미터를 한 번에 추가
    ///
    /// 딕셔너리로 여러 쿼리 파라미터를 일괄 추가합니다.
    /// 기존 파라미터와 키가 중복되면 덮어씁니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// builder.queryParams([
    ///     "interval": "1d",
    ///     "range": "1mo",
    ///     "includePrePost": "true"
    /// ])
    /// ```
    ///
    /// - Parameter params: 쿼리 파라미터 딕셔너리
    /// - Returns: 메서드 체이닝을 위한 self
    public func queryParams(_ params: [String: String]) -> YFRequestBuilder {
        for (key, value) in params {
            queryParameters[key] = value
        }
        return self
    }
    
    /// 단일 HTTP 헤더 추가
    ///
    /// 요청에 추가 HTTP 헤더를 설정합니다.
    /// 세션의 기본 헤더에 추가로 적용됩니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// builder
    ///     .header("Accept", "application/json")
    ///     .header("X-Custom-Header", "custom-value")
    /// ```
    ///
    /// - Parameters:
    ///   - key: HTTP 헤더 키
    ///   - value: HTTP 헤더 값
    /// - Returns: 메서드 체이닝을 위한 self
    /// - Note: 세션의 기본 헤더와 충돌하는 경우, 이 메서드로 설정한 값이 우선합니다.
    public func header(_ key: String, _ value: String) -> YFRequestBuilder {
        additionalHeaders[key] = value
        return self
    }
    
    /// 여러 HTTP 헤더를 한 번에 추가
    ///
    /// 딕셔너리로 여러 HTTP 헤더를 일괄 추가합니다.
    /// 기존 헤더와 키가 중복되면 덮어씁니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// builder.headers([
    ///     "Accept": "application/json",
    ///     "Accept-Language": "en-US",
    ///     "X-Custom-Header": "value"
    /// ])
    /// ```
    ///
    /// - Parameter headers: HTTP 헤더 딕셔너리
    /// - Returns: 메서드 체이닝을 위한 self
    public func headers(_ headers: [String: String]) -> YFRequestBuilder {
        for (key, value) in headers {
            additionalHeaders[key] = value
        }
        return self
    }
    
    /// 설정된 파라미터로 URLRequest 생성
    ///
    /// 빌더에 설정된 모든 파라미터를 사용하여 최종 URLRequest를 생성합니다.
    /// 경로가 설정되지 않았거나 유효하지 않은 URL인 경우 에러를 던집니다.
    ///
    /// ## 생성 과정
    /// 1. 경로 검증 및 URL 구성
    /// 2. 쿼리 파라미터 추가
    /// 3. 세션 기본 헤더 적용
    /// 4. 추가 헤더 적용
    /// 5. 타임아웃 설정
    ///
    /// ## 사용 예시
    /// ```swift
    /// do {
    ///     let request = try builder
    ///         .path("/v8/finance/chart/AAPL")
    ///         .queryParam("interval", "1d")
    ///         .build()
    ///     
    ///     let (data, _) = try await URLSession.shared.data(for: request)
    /// } catch YFError.invalidRequest {
    ///     print("잘못된 요청 구성")
    /// }
    /// ```
    ///
    /// - Returns: 구성된 URLRequest 객체
    /// - Throws: ``YFError/invalidRequest`` - 경로가 없거나 유효하지 않은 URL인 경우
    public func build() throws -> URLRequest {
        guard let path = pathString else {
            throw YFError.invalidRequest
        }
        
        guard var urlComponents = URLComponents(string: path) else {
            throw YFError.invalidRequest
        }
        
        if !queryParameters.isEmpty {
            urlComponents.queryItems = queryParameters.map { key, value in
                URLQueryItem(name: key, value: value)
            }
        }
        
        guard let url = urlComponents.url(relativeTo: session.baseURL) else {
            throw YFError.invalidRequest
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = session.timeout
        
        for (key, value) in session.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        for (key, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
}