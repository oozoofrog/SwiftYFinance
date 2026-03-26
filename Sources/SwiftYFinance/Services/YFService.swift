import Foundation

/// 모든 Yahoo Finance 서비스의 공통 인터페이스
///
/// Protocol-oriented programming과 Swift Concurrency를 위한 설계입니다.
/// 모든 서비스 구현체는 이 프로토콜을 준수하여 일관된 인터페이스를 제공합니다.
/// Sendable 프로토콜을 준수하여 concurrent 환경에서 안전하게 사용할 수 있습니다.
public protocol YFService: Sendable {
    /// YFClient 참조
    var client: YFClient { get }
}

/// YFService의 기본 구현을 제공하는 확장
///
/// Protocol default implementation을 통해 공통 기능을 제공합니다.
/// 모든 서비스에서 일관된 동작을 보장하며 코드 중복을 제거합니다.
public extension YFService {

    /// 클라이언트 참조가 유효한지 확인하고 반환합니다
    ///
    /// 서비스 메서드 시작 시 클라이언트 참조 유효성을 검증합니다.
    /// 각 서비스에서 guard문 중복을 제거할 수 있습니다.
    ///
    /// - Returns: 검증된 YFClient 인스턴스
    func validateClient() throws -> YFClient {
        return client // struct이므로 항상 valid
    }

    /// API 응답을 디버깅 로그로 출력합니다
    ///
    /// 디버깅 모드가 활성화된 경우에만 로그를 출력합니다.
    ///
    /// - Parameters:
    ///   - data: 응답 데이터
    ///   - serviceName: 서비스 이름 (로그 식별용)
    func logAPIResponse(_ data: Data, serviceName: String) {
        YFLogger.network.debug("[\(serviceName)] 응답 \(data.count) bytes")
    }

    /// CSRF 인증을 시도합니다
    ///
    /// Yahoo Finance API 요청 시 필요한 CSRF 인증을 처리합니다.
    /// 인증이 실패해도 에러를 던지지 않고 기본 요청으로 진행할 수 있도록 합니다.
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

    /// Yahoo Finance API 응답에서 공통 에러를 처리합니다
    ///
    /// - Parameter errorDescription: API 응답의 에러 설명
    /// - Throws: 에러가 있는 경우 YFError.apiError
    func handleYahooFinanceError(_ errorDescription: String?) throws {
        if let error = errorDescription {
            throw YFError.apiError(error)
        }
    }

    /// 공통 API 호출 및 JSON 파싱을 수행합니다
    ///
    /// CSRF 인증, URL 요청, 응답 로깅, JSON 파싱을 일괄 처리합니다.
    ///
    /// - Parameters:
    ///   - url: API 요청 URL
    ///   - type: 디코딩할 타입
    ///   - serviceName: 로깅용 서비스 이름
    /// - Returns: 파싱된 객체
    /// - Throws: API 호출 또는 파싱 중 발생하는 에러
    func performFetch<T: Decodable>(url: URL, type: T.Type, serviceName: String) async throws -> T {
        await ensureCSRFAuthentication()
        let core = YFServiceCore(client: client)
        do {
            let (data, _) = try await core.authenticatedRequest(url: url)
            logAPIResponse(data, serviceName: serviceName)
            return try core.parseJSON(data: data, type: type)
        } catch {
            YFLogger.service.error("[\(serviceName)] performFetch 실패: \(error.localizedDescription)")
            throw error
        }
    }

    /// 공통 API 호출을 수행하고 원본 JSON 데이터를 반환합니다
    ///
    /// - Parameters:
    ///   - url: API 요청 URL
    ///   - serviceName: 로깅용 서비스 이름
    /// - Returns: 원본 JSON 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    func performFetchRawJSON(url: URL, serviceName: String) async throws -> Data {
        await ensureCSRFAuthentication()
        let core = YFServiceCore(client: client)
        let (data, _) = try await core.authenticatedRequest(url: url)
        logAPIResponse(data, serviceName: "\(serviceName) (Raw JSON)")
        return data
    }

    // MARK: - Public API Methods (No Authentication Required)

    /// 공개 API용 fetch 메서드 (인증 불필요)
    ///
    /// Quote API와 같은 공개 API는 CSRF 인증이 필요하지 않습니다.
    ///
    /// - Parameters:
    ///   - url: 요청 URL
    ///   - type: 응답 타입
    ///   - serviceName: 서비스 이름 (로깅용)
    /// - Returns: 파싱된 응답 객체
    /// - Throws: API 호출 중 발생하는 에러
    func performPublicFetch<T: Decodable>(url: URL, type: T.Type, serviceName: String) async throws -> T {
        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            guard 200...299 ~= httpResponse.statusCode else {
                YFLogger.network.error("[\(serviceName)] HTTP \(httpResponse.statusCode)")
                throw YFError.httpError(statusCode: httpResponse.statusCode)
            }
        }

        logAPIResponse(data, serviceName: serviceName)
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }

    /// 공개 API용 Raw JSON 메서드 (인증 불필요)
    ///
    /// - Parameters:
    ///   - url: 요청 URL
    ///   - serviceName: 서비스 이름 (로깅용)
    /// - Returns: Raw JSON 데이터
    /// - Throws: API 호출 중 발생하는 에러
    func performPublicFetchRawJSON(url: URL, serviceName: String) async throws -> Data {
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

    // MARK: - POST Request Methods (Authentication Required)

    /// 공통 POST API 호출 및 JSON 파싱을 수행합니다
    ///
    /// CSRF 인증, POST 요청, 응답 로깅, JSON 파싱을 일괄 처리합니다.
    ///
    /// - Parameters:
    ///   - url: API 요청 URL
    ///   - requestBody: POST 요청 바디 데이터
    ///   - type: 디코딩할 타입
    ///   - serviceName: 로깅용 서비스 이름
    /// - Returns: 파싱된 객체
    /// - Throws: API 호출 또는 파싱 중 발생하는 에러
    func performPostFetch<T: Decodable>(url: URL, requestBody: Data, type: T.Type, serviceName: String) async throws -> T {
        await ensureCSRFAuthentication()
        let core = YFServiceCore(client: client)
        do {
            let (data, _) = try await core.authenticatedPostRequest(url: url, requestBody: requestBody)
            logAPIResponse(data, serviceName: serviceName)
            return try core.parseJSON(data: data, type: type)
        } catch {
            YFLogger.service.error("[\(serviceName)] performPostFetch 실패: \(error.localizedDescription)")
            throw error
        }
    }

    /// 공통 POST API 호출을 수행하고 원본 JSON 데이터를 반환합니다
    ///
    /// - Parameters:
    ///   - url: API 요청 URL
    ///   - requestBody: POST 요청 바디 데이터
    ///   - serviceName: 로깅용 서비스 이름
    /// - Returns: 원본 JSON 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    func performPostFetchRawJSON(url: URL, requestBody: Data, serviceName: String) async throws -> Data {
        await ensureCSRFAuthentication()
        let core = YFServiceCore(client: client)
        let (data, _) = try await core.authenticatedPostRequest(url: url, requestBody: requestBody)
        logAPIResponse(data, serviceName: "\(serviceName) (Raw JSON)")
        return data
    }
}
