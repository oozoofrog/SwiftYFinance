import Foundation

/// Yahoo Finance 서비스들의 공통 로직을 제공하는 핵심 구조체
///
/// YFBaseService의 모든 기능을 struct로 재구현한 것입니다.
/// Sendable 프로토콜을 준수하며 @unchecked 없이도 thread-safe합니다.
/// 모든 서비스 구현체에서 composition으로 사용됩니다.
public struct YFServiceCore: Sendable {
    
    /// YFClient 참조 (struct이므로 값 타입)
    public let client: YFClient
    
    /// 기본 재시도 횟수
    private let maxRetryAttempts = 2
    
    
    /// YFServiceCore 초기화
    /// - Parameter client: YFClient 인스턴스
    public init(client: YFClient) {
        self.client = client
    }
    
    /// 인증된 요청을 수행합니다 (재시도 로직 포함)
    ///
    /// Yahoo Finance API에 대한 인증된 요청을 수행하며, 401/403 오류 시 자동으로 재시도합니다.
    /// 모든 서비스에서 동일한 인증 전략과 재시도 로직을 사용하여 일관성을 보장합니다.
    ///
    /// - Parameter url: 요청할 URL
    /// - Returns: 응답 데이터와 URLResponse 튜플
    /// - Throws: 네트워크 오류나 인증 실패 시 YFError
    public func authenticatedRequest(url: URL) async throws -> (Data, URLResponse) {
        DebugPrint("🚀 [ServiceCore] authenticatedRequest() 시작")
        DebugPrint("🌐 [ServiceCore] 요청 URL: \(url)")
        
        var lastError: Error?
        
        // 재시도 로직
        for attempt in 0..<maxRetryAttempts {
            DebugPrint("🔄 [ServiceCore] 시도 \(attempt + 1)/\(maxRetryAttempts)")
            do {
                // 인증된 요청 수행
                DebugPrint("📡 [ServiceCore] makeAuthenticatedRequest() 호출...")
                let (data, response) = try await client.session.makeAuthenticatedRequest(url: url)
                DebugPrint("✅ [ServiceCore] makeAuthenticatedRequest() 완료, 데이터 크기: \(data.count) bytes")
                
                // HTTP 응답 검증
                if let httpResponse = response as? HTTPURLResponse {
                    DebugPrint("🔍 [ServiceCore] HTTP 응답 상태: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        DebugPrint("❌ [ServiceCore] 인증 오류 감지: \(httpResponse.statusCode)")
                        // 인증 오류시 재시도 (첫 번째 시도에서만)
                        if attempt == 0 {
                            DebugPrint("🔄 [ServiceCore] 첫 번째 시도, 재시도 예정...")
                            lastError = YFError.apiError("Authentication failed, retrying...")
                            continue
                        } else {
                            DebugPrint("❌ [ServiceCore] 최대 재시도 횟수 초과, 실패")
                            throw YFError.apiError("Authentication failed after \(maxRetryAttempts) attempts")
                        }
                    } else if httpResponse.statusCode != 200 {
                        DebugPrint("❌ [ServiceCore] 비정상 상태 코드: \(httpResponse.statusCode)")
                        throw YFError.networkError("HTTP \(httpResponse.statusCode)")
                    } else {
                        DebugPrint("✅ [ServiceCore] HTTP 200 OK 응답")
                    }
                } else {
                    DebugPrint("⚠️ [ServiceCore] HTTP 응답이 아닌 응답 타입")
                }
                
                // 성공적으로 응답을 받은 경우
                DebugPrint("✅ [ServiceCore] authenticatedRequest() 성공")
                return (data, response)
                
            } catch {
                DebugPrint("❌ [ServiceCore] 시도 \(attempt + 1) 중 예외 발생: \(error)")
                lastError = error
                
                // 인증 관련 에러가 아닌 경우 바로 재시도하지 않고 에러 던지기
                if let yfError = error as? YFError,
                   case .networkError(let message) = yfError,
                   let message,
                   !message.contains("401") && !message.contains("403") {
                    DebugPrint("❌ [ServiceCore] 비인증 관련 네트워크 오류, 즉시 실패: \(message)")
                    throw error
                } else {
                    DebugPrint("⚠️ [ServiceCore] 재시도 가능한 오류: \(error)")
                }
                
                // 마지막 시도에서 실패한 경우 에러 던지기
                if attempt == maxRetryAttempts - 1 {
                    DebugPrint("❌ [ServiceCore] 마지막 시도 실패")
                    throw error
                } else {
                    DebugPrint("🔄 [ServiceCore] 다음 시도 준비 중...")
                }
            }
        }
        
        // 모든 재시도가 실패한 경우
        DebugPrint("❌ [ServiceCore] 모든 재시도 실패, 최종 오류: \(lastError?.localizedDescription ?? "Unknown error")")
        throw lastError ?? YFError.apiError("Request failed after \(maxRetryAttempts) attempts")
    }
    
    /// 인증된 POST 요청을 수행합니다 (재시도 로직 포함)
    ///
    /// Yahoo Finance Custom Screener와 같은 POST 요청이 필요한 API에서 사용합니다.
    /// 401/403 오류 시 자동으로 재시도하며, CSRF 인증을 포함한 모든 헤더를 설정합니다.
    ///
    /// - Parameters:
    ///   - url: 요청할 URL
    ///   - requestBody: POST 요청 바디 데이터
    /// - Returns: 응답 데이터와 URLResponse 튜플
    /// - Throws: 네트워크 오류나 인증 실패 시 YFError
    public func authenticatedPostRequest(url: URL, requestBody: Data) async throws -> (Data, URLResponse) {
        DebugPrint("🚀 [ServiceCore] authenticatedPostRequest() 시작")
        DebugPrint("🌐 [ServiceCore] 요청 URL: \(url)")
        DebugPrint("📦 [ServiceCore] 요청 바디 크기: \(requestBody.count) bytes")
        
        var lastError: Error?
        
        // 재시도 로직
        for attempt in 0..<maxRetryAttempts {
            DebugPrint("🔄 [ServiceCore] 시도 \(attempt + 1)/\(maxRetryAttempts)")
            do {
                // 인증된 POST 요청 수행
                DebugPrint("📡 [ServiceCore] makeAuthenticatedPostRequest() 호출...")
                let (data, response) = try await client.session.makeAuthenticatedPostRequest(url: url, requestBody: requestBody)
                DebugPrint("✅ [ServiceCore] makeAuthenticatedPostRequest() 완료, 데이터 크기: \(data.count) bytes")
                
                // HTTP 응답 검증
                if let httpResponse = response as? HTTPURLResponse {
                    DebugPrint("🔍 [ServiceCore] HTTP 응답 상태: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        DebugPrint("❌ [ServiceCore] 인증 오류 감지: \(httpResponse.statusCode)")
                        // 인증 오류시 재시도 (첫 번째 시도에서만)
                        if attempt == 0 {
                            DebugPrint("🔄 [ServiceCore] 첫 번째 시도, 재시도 예정...")
                            lastError = YFError.apiError("Authentication failed, retrying...")
                            continue
                        } else {
                            DebugPrint("❌ [ServiceCore] 최대 재시도 횟수 초과, 실패")
                            throw YFError.apiError("Authentication failed after \(maxRetryAttempts) attempts")
                        }
                    } else if httpResponse.statusCode != 200 {
                        DebugPrint("❌ [ServiceCore] 비정상 상태 코드: \(httpResponse.statusCode)")
                        throw YFError.networkError("HTTP \(httpResponse.statusCode)")
                    } else {
                        DebugPrint("✅ [ServiceCore] HTTP 200 OK 응답")
                    }
                } else {
                    DebugPrint("⚠️ [ServiceCore] HTTP 응답이 아닌 응답 타입")
                }
                
                // 성공적으로 응답을 받은 경우
                DebugPrint("✅ [ServiceCore] authenticatedPostRequest() 성공")
                return (data, response)
                
            } catch {
                DebugPrint("❌ [ServiceCore] 시도 \(attempt + 1) 중 예외 발생: \(error)")
                lastError = error
                
                // 인증 관련 에러가 아닌 경우 바로 재시도하지 않고 에러 던지기
                if let yfError = error as? YFError,
                   case .networkError(let message) = yfError,
                   let message,
                   !message.contains("401") && !message.contains("403") {
                    DebugPrint("❌ [ServiceCore] 비인증 관련 네트워크 오류, 즉시 실패: \(message)")
                    throw error
                } else {
                    DebugPrint("⚠️ [ServiceCore] 재시도 가능한 오류: \(error)")
                }
                
                // 마지막 시도에서 실패한 경우 에러 던지기
                if attempt == maxRetryAttempts - 1 {
                    DebugPrint("❌ [ServiceCore] 마지막 시도 실패")
                    throw error
                } else {
                    DebugPrint("🔄 [ServiceCore] 다음 시도 준비 중...")
                }
            }
        }
        
        // 모든 재시도가 실패한 경우
        DebugPrint("❌ [ServiceCore] 모든 재시도 실패, 최종 오류: \(lastError?.localizedDescription ?? "Unknown error")")
        throw lastError ?? YFError.apiError("Request failed after \(maxRetryAttempts) attempts")
    }
    
    /// JSON 응답을 파싱합니다
    ///
    /// 공통 JSON 파싱 로직을 제공하며, 파싱 실패 시 명확한 에러 메시지를 제공합니다.
    ///
    /// - Parameters:
    ///   - data: 파싱할 JSON 데이터
    ///   - type: 디코딩할 타입
    /// - Returns: 디코딩된 객체
    /// - Throws: 파싱 실패 시 YFError.parsingError
    public func parseJSON<T: Decodable>(data: Data, type: T.Type) throws -> T {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            throw YFError.parsingError("JSON 파싱 실패: \(error.localizedDescription)")
        }
    }
    
    /// URL을 구성합니다
    ///
    /// 기본 URL과 파라미터들로부터 완전한 URL을 생성합니다.
    ///
    /// - Parameters:
    ///   - baseURL: 기본 URL 문자열
    ///   - parameters: 쿼리 파라미터 딕셔너리
    /// - Returns: 완전히 구성된 URL
    /// - Throws: URL 구성이 실패할 경우 YFError.invalidURL
    public func buildURL(baseURL: String, parameters: [String: String]) throws -> URL {
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