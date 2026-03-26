import Foundation

/// Yahoo Finance 서비스들의 공통 로직을 제공하는 핵심 구조체
///
/// YFBaseService의 모든 기능을 struct로 재구현한 것입니다.
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

    /// 인증된 요청을 수행합니다 (재시도 로직 포함)
    ///
    /// Yahoo Finance API에 대한 인증된 요청을 수행하며, 401/403 오류 시 자동으로 재시도합니다.
    ///
    /// - Parameter url: 요청할 URL
    /// - Returns: 응답 데이터와 URLResponse 튜플
    /// - Throws: 네트워크 오류나 인증 실패 시 YFError
    func authenticatedRequest(url: URL) async throws -> (Data, URLResponse) {
        var lastError: Error?

        for attempt in 0..<maxRetryAttempts {
            do {
                let (data, response) = try await client.session.makeAuthenticatedRequest(url: url)

                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        if attempt == 0 {
                            lastError = YFError.apiError("Authentication failed, retrying...")
                            continue
                        } else {
                            throw YFError.apiError("Authentication failed after \(maxRetryAttempts) attempts")
                        }
                    } else if httpResponse.statusCode != 200 {
                        YFLogger.network.error("HTTP \(httpResponse.statusCode) 오류: \(url.absoluteString)")
                        throw YFError.networkError("HTTP \(httpResponse.statusCode)")
                    }
                }

                return (data, response)

            } catch {
                lastError = error

                // 인증 관련 에러가 아닌 경우 즉시 실패
                if let yfError = error as? YFError,
                   case .networkError(let message) = yfError,
                   let message,
                   !message.contains("401") && !message.contains("403") {
                    throw error
                }

                if attempt == maxRetryAttempts - 1 {
                    YFLogger.network.error("요청 최종 실패: \(error.localizedDescription)")
                    throw error
                }
            }
        }

        throw lastError ?? YFError.apiError("Request failed after \(maxRetryAttempts) attempts")
    }

    /// 인증된 POST 요청을 수행합니다 (재시도 로직 포함)
    ///
    /// Yahoo Finance Custom Screener와 같은 POST 요청이 필요한 API에서 사용합니다.
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

                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        if attempt == 0 {
                            lastError = YFError.apiError("Authentication failed, retrying...")
                            continue
                        } else {
                            throw YFError.apiError("Authentication failed after \(maxRetryAttempts) attempts")
                        }
                    } else if httpResponse.statusCode != 200 {
                        YFLogger.network.error("POST HTTP \(httpResponse.statusCode) 오류: \(url.absoluteString)")
                        throw YFError.networkError("HTTP \(httpResponse.statusCode)")
                    }
                }

                return (data, response)

            } catch {
                lastError = error

                if let yfError = error as? YFError,
                   case .networkError(let message) = yfError,
                   let message,
                   !message.contains("401") && !message.contains("403") {
                    throw error
                }

                if attempt == maxRetryAttempts - 1 {
                    YFLogger.network.error("POST 요청 최종 실패: \(error.localizedDescription)")
                    throw error
                }
            }
        }

        throw lastError ?? YFError.apiError("Request failed after \(maxRetryAttempts) attempts")
    }

    /// JSON 응답을 파싱합니다
    ///
    /// - Parameters:
    ///   - data: 파싱할 JSON 데이터
    ///   - type: 디코딩할 타입
    /// - Returns: 디코딩된 객체
    /// - Throws: 파싱 실패 시 YFError.parsingError
    func parseJSON<T: Decodable>(data: Data, type: T.Type) throws -> T {
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
