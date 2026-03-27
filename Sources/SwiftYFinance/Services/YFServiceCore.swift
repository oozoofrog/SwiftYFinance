import Foundation

/// Yahoo Finance 서비스들의 공통 로직을 제공하는 핵심 구조체
///
/// Sendable 프로토콜을 준수하며 @unchecked 없이도 thread-safe합니다.
/// 모든 서비스 구현체에서 composition으로 사용됩니다.
struct YFServiceCore: Sendable {

    /// YFClient 참조 (struct이므로 값 타입)
    let client: YFClient

    /// 기본 재시도 횟수
    private let maxRetryAttempts = 2

    /// YFServiceCore 초기화
    /// - Parameter client: YFClient 인스턴스
    init(client: YFClient) {
        self.client = client
    }

    // MARK: - 공통 HTTP 응답 검증

    /// HTTP 응답의 상태 코드를 검증합니다
    ///
    /// 2xx 범위를 성공으로 처리하고, 401/403은 인증 재시도 신호를,
    /// 그 외 오류 코드는 YFError.networkError를 throw합니다.
    ///
    /// - Parameters:
    ///   - response: URLResponse 객체
    ///   - url: 로그용 요청 URL
    ///   - attempt: 현재 재시도 횟수 (401/403 재시도 판단에 사용)
    /// - Returns: 성공(2xx)이면 true, 401/403이고 첫 시도면 false(재시도 신호)
    /// - Throws: 401/403 최종 실패 시, 또는 기타 HTTP 오류 시 YFError
    private func validateHTTPResponse(
        _ response: URLResponse,
        url: URL,
        attempt: Int
    ) throws -> Bool {
        guard let httpResponse = response as? HTTPURLResponse else {
            return true // URLResponse이면 상태 코드 없음 → 성공으로 처리
        }

        let statusCode = httpResponse.statusCode

        // 2xx 범위 전체를 성공으로 처리 (200, 201, 204 등)
        if statusCode >= 200 && statusCode < 300 {
            return true
        }

        // 인증 실패 — 첫 시도면 재시도 신호, 마지막 시도면 오류
        if statusCode == 401 || statusCode == 403 {
            if attempt == 0 {
                return false // 재시도 신호
            } else {
                throw YFError.apiError("Authentication failed after \(maxRetryAttempts) attempts")
            }
        }

        // 그 외 HTTP 오류
        YFLogger.network.error("HTTP \(statusCode) 오류: \(url.absoluteString)")
        throw YFError.networkError("HTTP \(statusCode)")
    }

    // MARK: - 인증 요청 실행

    /// 인증된 GET 요청을 수행합니다 (재시도 로직 포함)
    ///
    /// - Parameter url: 요청할 URL
    /// - Returns: 응답 데이터와 URLResponse 튜플
    /// - Throws: 네트워크 오류나 인증 실패 시 YFError
    func authenticatedRequest(url: URL) async throws -> (Data, URLResponse) {
        var lastError: Error?

        for attempt in 0..<maxRetryAttempts {
            do {
                let (data, response) = try await client.session.makeAuthenticatedRequest(url: url)
                let shouldContinue = try validateHTTPResponse(response, url: url, attempt: attempt)
                if !shouldContinue {
                    lastError = YFError.apiError("Authentication failed, retrying...")
                    continue
                }
                return (data, response)
            } catch {
                lastError = error
                if !isAuthError(error) || attempt == maxRetryAttempts - 1 {
                    YFLogger.network.error("요청 최종 실패: \(error.localizedDescription)")
                    throw error
                }
            }
        }

        throw lastError ?? YFError.apiError("Request failed after \(maxRetryAttempts) attempts")
    }

    /// 인증된 POST 요청을 수행합니다 (재시도 로직 포함)
    ///
    /// - Parameters:
    ///   - url: 요청할 URL
    ///   - requestBody: POST 요청 바디 데이터
    /// - Returns: 응답 데이터와 URLResponse 튜플
    /// - Throws: 네트워크 오류나 인증 실패 시 YFError
    func authenticatedPostRequest(url: URL, requestBody: Data) async throws -> (Data, URLResponse) {
        var lastError: Error?

        for attempt in 0..<maxRetryAttempts {
            do {
                let (data, response) = try await client.session.makeAuthenticatedPostRequest(url: url, requestBody: requestBody)
                let shouldContinue = try validateHTTPResponse(response, url: url, attempt: attempt)
                if !shouldContinue {
                    lastError = YFError.apiError("Authentication failed, retrying...")
                    continue
                }
                return (data, response)
            } catch {
                lastError = error
                if !isAuthError(error) || attempt == maxRetryAttempts - 1 {
                    YFLogger.network.error("POST 요청 최종 실패: \(error.localizedDescription)")
                    throw error
                }
            }
        }

        throw lastError ?? YFError.apiError("Request failed after \(maxRetryAttempts) attempts")
    }

    // MARK: - 공통 유틸리티

    /// 에러가 인증 관련 오류인지 판단합니다 (재시도 여부 결정용)
    private func isAuthError(_ error: Error) -> Bool {
        guard let yfError = error as? YFError,
              case .networkError(let message) = yfError,
              let message else { return false }
        return message.contains("401") || message.contains("403")
    }

    /// JSON 응답을 파싱합니다
    ///
    /// CPU-bound JSON 디코딩 작업으로, `@concurrent` 속성에 의해 항상 concurrent thread pool에서 실행됩니다.
    /// 호출자(예: MainActor)를 블로킹하지 않고 백그라운드에서 안전하게 처리됩니다.
    ///
    /// - Parameters:
    ///   - data: 파싱할 JSON 데이터
    ///   - type: 디코딩할 타입
    /// - Returns: 디코딩된 객체
    /// - Throws: 파싱 실패 시 YFError.parsingError
    @concurrent
    func parseJSON<T: Decodable>(data: Data, type: T.Type) async throws -> T {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            YFLogger.parser.error("JSON 파싱 실패 (\(T.self)): \(error.localizedDescription)")
            throw YFError.parsingError("JSON 파싱 실패: \(error.localizedDescription)")
        }
    }

    /// URL을 구성합니다
    ///
    /// - Parameters:
    ///   - baseURL: 기본 URL 문자열
    ///   - parameters: 쿼리 파라미터 딕셔너리
    /// - Returns: 완전히 구성된 URL
    /// - Throws: URL 구성이 실패할 경우 YFError.invalidURL
    func buildURL(baseURL: String, parameters: [String: String]) throws -> URL {
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw YFError.invalidURL
        }

        urlComponents.queryItems = parameters.map { key, value in
            URLQueryItem(name: key, value: value)
        }

        guard let url = urlComponents.url else {
            throw YFError.invalidURL
        }

        return url
    }
}
