import Foundation

/// Yahoo Finance API 요청 파이프라인
///
/// YFService extension에 집중되어 있던 인증, 로깅, 파싱, 에러처리,
/// HTTP 상태 검증, POST 요청 등의 책임을 단일 타입으로 추출합니다.
///
/// ## 사용 예시
/// ```swift
/// let pipeline = YFRequestPipeline(client: client)
/// let result: YFQuote = try await pipeline.fetch(url: url, type: YFQuote.self, serviceName: "Quote")
/// ```
/// nonisolated: 순수 요청 파이프라인 struct — actor isolation 불필요
/// 라이브러리 소비자의 모든 isolation 컨텍스트에서 안전하게 사용 가능
nonisolated struct YFRequestPipeline: Sendable {

    /// YFClient 참조
    let client: YFClient

    /// 내부 서비스 코어 (인증된 HTTP 요청 수행)
    private let core: YFServiceCore

    /// YFRequestPipeline 초기화
    /// - Parameter client: YFClient 인스턴스
    init(client: YFClient) {
        self.client = client
        self.core = YFServiceCore(client: client)
    }

    // MARK: - 인증

    /// CSRF 인증을 시도합니다
    ///
    /// Yahoo Finance API 요청 시 필요한 CSRF 인증을 처리합니다.
    /// 인증이 실패해도 에러를 던지지 않고 기본 요청으로 진행합니다.
    func ensureCSRFAuthentication() async {
        let isAuthenticated = await client.session.isCSRFAuthenticated
        if !isAuthenticated {
            do {
                try await client.session.authenticateCSRF()
            } catch {
                YFLogger.auth.error("CSRF 인증 실패: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 로깅

    /// API 응답을 디버그 로그로 출력합니다
    ///
    /// - Parameters:
    ///   - data: 응답 데이터
    ///   - serviceName: 서비스 이름 (로그 식별용)
    func logAPIResponse(_ data: Data, serviceName: String) {
        YFLogger.network.debug("[\(serviceName)] 응답 \(data.count) bytes")
    }

    // MARK: - GET 요청 (인증 필요)

    /// 인증이 필요한 API 호출 및 JSON 파싱을 수행합니다
    ///
    /// CSRF 인증, URL 요청, 응답 로깅, JSON 파싱을 일괄 처리합니다.
    ///
    /// - Parameters:
    ///   - url: API 요청 URL
    ///   - type: 디코딩할 타입
    ///   - serviceName: 로깅용 서비스 이름
    /// - Returns: 파싱된 객체
    /// - Throws: API 호출 또는 파싱 중 발생하는 에러
    func fetch<T: Decodable>(url: URL, type: T.Type, serviceName: String) async throws -> T {
        await ensureCSRFAuthentication()
        do {
            let (data, _) = try await core.authenticatedRequest(url: url)
            logAPIResponse(data, serviceName: serviceName)
            return try await core.parseJSON(data: data, type: type)
        } catch {
            YFLogger.service.error("[\(serviceName)] fetch 실패: \(error.localizedDescription)")
            throw error
        }
    }

    /// 인증이 필요한 API 호출을 수행하고 원본 JSON 데이터를 반환합니다
    ///
    /// - Parameters:
    ///   - url: API 요청 URL
    ///   - serviceName: 로깅용 서비스 이름
    /// - Returns: 원본 JSON 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    func fetchRawJSON(url: URL, serviceName: String) async throws -> Data {
        await ensureCSRFAuthentication()
        let (data, _) = try await core.authenticatedRequest(url: url)
        logAPIResponse(data, serviceName: "\(serviceName) (Raw JSON)")
        return data
    }

    // MARK: - GET 요청 (인증 불필요 - 공개 API)

    /// 공개 API용 fetch 메서드 (인증 불필요)
    ///
    /// - Parameters:
    ///   - url: 요청 URL
    ///   - type: 응답 타입
    ///   - serviceName: 서비스 이름 (로깅용)
    /// - Returns: 파싱된 응답 객체
    /// - Throws: API 호출 중 발생하는 에러
    func fetchPublic<T: Decodable>(url: URL, type: T.Type, serviceName: String) async throws -> T {
        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            guard 200...299 ~= httpResponse.statusCode else {
                YFLogger.network.error("[\(serviceName)] HTTP \(httpResponse.statusCode)")
                throw YFError.httpError(statusCode: httpResponse.statusCode)
            }
        }

        logAPIResponse(data, serviceName: serviceName)
        // YFResponseParser.parse()를 @concurrent await로 호출 — CPU-bound 파싱을 concurrent thread pool에서 실행
        return try await client.responseParser.parse(data, type: type)
    }

    /// 공개 API용 Raw JSON 메서드 (인증 불필요)
    ///
    /// - Parameters:
    ///   - url: 요청 URL
    ///   - serviceName: 서비스 이름 (로깅용)
    /// - Returns: Raw JSON 데이터
    /// - Throws: API 호출 중 발생하는 에러
    func fetchPublicRawJSON(url: URL, serviceName: String) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            guard 200...299 ~= httpResponse.statusCode else {
                YFLogger.network.error("[\(serviceName)] HTTP \(httpResponse.statusCode)")
                throw YFError.httpError(statusCode: httpResponse.statusCode)
            }
        }

        logAPIResponse(data, serviceName: "\(serviceName) (Raw JSON)")
        return data
    }

    // MARK: - POST 요청 (인증 필요)

    /// 인증이 필요한 POST API 호출 및 JSON 파싱을 수행합니다
    ///
    /// - Parameters:
    ///   - url: API 요청 URL
    ///   - requestBody: POST 요청 바디 데이터
    ///   - type: 디코딩할 타입
    ///   - serviceName: 로깅용 서비스 이름
    /// - Returns: 파싱된 객체
    /// - Throws: API 호출 또는 파싱 중 발생하는 에러
    func post<T: Decodable>(url: URL, requestBody: Data, type: T.Type, serviceName: String) async throws -> T {
        await ensureCSRFAuthentication()
        do {
            let (data, _) = try await core.authenticatedPostRequest(url: url, requestBody: requestBody)
            logAPIResponse(data, serviceName: serviceName)
            return try await core.parseJSON(data: data, type: type)
        } catch {
            YFLogger.service.error("[\(serviceName)] post 실패: \(error.localizedDescription)")
            throw error
        }
    }

    /// 인증이 필요한 POST API 호출을 수행하고 원본 JSON 데이터를 반환합니다
    ///
    /// - Parameters:
    ///   - url: API 요청 URL
    ///   - requestBody: POST 요청 바디 데이터
    ///   - serviceName: 로깅용 서비스 이름
    /// - Returns: 원본 JSON 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    func postRawJSON(url: URL, requestBody: Data, serviceName: String) async throws -> Data {
        await ensureCSRFAuthentication()
        let (data, _) = try await core.authenticatedPostRequest(url: url, requestBody: requestBody)
        logAPIResponse(data, serviceName: "\(serviceName) (Raw JSON)")
        return data
    }

    // MARK: - Yahoo Finance 에러 처리

    /// Yahoo Finance API 응답에서 공통 에러를 처리합니다
    ///
    /// - Parameter errorDescription: API 응답의 에러 설명
    /// - Throws: 에러가 있는 경우 YFError.apiError
    func handleYahooFinanceError(_ errorDescription: String?) throws {
        if let error = errorDescription {
            throw YFError.apiError(error)
        }
    }
}
