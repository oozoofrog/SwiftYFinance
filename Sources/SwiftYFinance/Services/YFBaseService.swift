import Foundation

/// 모든 Yahoo Finance 서비스 클래스의 공통 기능을 제공하는 부모 클래스
///
/// 인증된 요청, 에러 처리, 응답 파싱 등의 공통 로직을 포함합니다.
/// 모든 서비스 클래스는 이 클래스를 상속받아 일관된 동작을 보장합니다.
public class YFBaseService {
    
    /// YFClient에 대한 약한 참조 (순환 참조 방지)
    public weak var client: YFClient?
    
    /// 기본 재시도 횟수
    private let maxRetryAttempts = 2
    
    /// 디버깅 모드 플래그 (응답 로깅 활성화)
    private let isDebugEnabled: Bool
    
    /// 서비스 초기화
    /// - Parameters:
    ///   - client: YFClient 인스턴스
    ///   - debugEnabled: 디버깅 로그 활성화 여부 (기본값: false)
    public init(client: YFClient, debugEnabled: Bool = false) {
        self.client = client
        self.isDebugEnabled = debugEnabled
    }
    
    /// 인증된 요청을 수행합니다 (재시도 로직 포함)
    ///
    /// Yahoo Finance API에 대한 인증된 요청을 수행하며, 401/403 오류 시 자동으로 재시도합니다.
    /// 모든 서비스에서 동일한 인증 전략과 재시도 로직을 사용하여 일관성을 보장합니다.
    ///
    /// - Parameter url: 요청할 URL
    /// - Returns: 응답 데이터와 URLResponse 튜플
    /// - Throws: 네트워크 오류나 인증 실패 시 YFError
    func authenticatedRequest(url: URL) async throws -> (Data, URLResponse) {
        guard let client = client else {
            throw YFError.apiError("YFClient reference is nil")
        }
        
        var lastError: Error?
        
        // 재시도 로직
        for attempt in 0..<maxRetryAttempts {
            do {
                // 인증된 요청 수행
                let (data, response) = try await client.session.makeAuthenticatedRequest(url: url)
                
                // HTTP 응답 검증
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        // 인증 오류시 재시도 (첫 번째 시도에서만)
                        if attempt == 0 {
                            lastError = YFError.apiError("Authentication failed, retrying...")
                            continue
                        } else {
                            throw YFError.apiError("Authentication failed after \(maxRetryAttempts) attempts")
                        }
                    } else if httpResponse.statusCode != 200 {
                        throw YFError.networkErrorWithMessage("HTTP \(httpResponse.statusCode)")
                    }
                }
                
                // 성공적으로 응답을 받은 경우
                return (data, response)
                
            } catch {
                lastError = error
                
                // 인증 관련 에러가 아닌 경우 바로 재시도하지 않고 에러 던지기
                if let yfError = error as? YFError,
                   case .networkErrorWithMessage(let message) = yfError,
                   !message.contains("401") && !message.contains("403") {
                    throw error
                }
                
                // 마지막 시도에서 실패한 경우 에러 던지기
                if attempt == maxRetryAttempts - 1 {
                    throw error
                }
            }
        }
        
        // 모든 재시도가 실패한 경우
        throw lastError ?? YFError.apiError("Request failed after \(maxRetryAttempts) attempts")
    }
    
    /// URL에 대한 인증된 GET 요청을 수행합니다
    ///
    /// URLRequest를 직접 구성하여 요청하는 방식입니다. 
    /// 더 세밀한 제어가 필요한 경우 사용합니다.
    ///
    /// - Parameter url: 요청할 URL
    /// - Returns: 응답 데이터와 URLResponse 튜플
    /// - Throws: 네트워크 오류나 인증 실패 시 YFError
    func authenticatedURLRequest(url: URL) async throws -> (Data, URLResponse) {
        guard let client = client else {
            throw YFError.apiError("YFClient reference is nil")
        }
        
        var lastError: Error?
        
        // 재시도 로직
        for attempt in 0..<maxRetryAttempts {
            do {
                // URLRequest 구성
                var request = URLRequest(url: url, timeoutInterval: client.session.timeout)
                
                // 기본 헤더 설정
                for (key, value) in client.session.defaultHeaders {
                    request.setValue(value, forHTTPHeaderField: key)
                }
                
                let (data, response) = try await client.session.urlSession.data(for: request)
                
                // HTTP 응답 검증
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        // 인증 오류시 재시도 (첫 번째 시도에서만)
                        if attempt == 0 {
                            lastError = YFError.apiError("Authentication failed, retrying...")
                            continue
                        } else {
                            throw YFError.apiError("Authentication failed after \(maxRetryAttempts) attempts")
                        }
                    } else if httpResponse.statusCode != 200 {
                        throw YFError.networkErrorWithMessage("HTTP \(httpResponse.statusCode)")
                    }
                }
                
                // 성공적으로 응답을 받은 경우
                return (data, response)
                
            } catch {
                lastError = error
                
                // 마지막 시도에서 실패한 경우 에러 던지기
                if attempt == maxRetryAttempts - 1 {
                    throw error
                }
            }
        }
        
        // 모든 재시도가 실패한 경우
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
    /// - Throws: 파싱 실패 시 YFError.parsingErrorWithMessage
    func parseJSON<T: Codable>(data: Data, type: T.Type) throws -> T {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            throw YFError.parsingErrorWithMessage("JSON 파싱 실패: \(error.localizedDescription)")
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
    
    /// 클라이언트 참조가 유효한지 확인하고 반환합니다
    ///
    /// 서비스 메서드 시작 시 클라이언트 참조 유효성을 검증하고 검증된 클라이언트를 반환합니다.
    /// 이를 통해 각 서비스에서 guard문 중복을 제거할 수 있습니다.
    ///
    /// - Returns: 검증된 YFClient 인스턴스
    /// - Throws: 클라이언트 참조가 nil인 경우 YFError.apiError
    func validateClientReference() throws -> YFClient {
        guard let client = client else {
            throw YFError.apiError("YFClient reference is nil")
        }
        return client
    }
    
    /// API 응답을 디버깅 로그로 출력합니다
    ///
    /// 디버깅 모드가 활성화된 경우에만 로그를 출력합니다.
    /// 모든 서비스에서 일관된 로깅 포맷을 사용합니다.
    ///
    /// - Parameters:
    ///   - data: 응답 데이터
    ///   - serviceName: 서비스 이름 (로그 식별용)
    func logAPIResponse(_ data: Data, serviceName: String) {
        guard isDebugEnabled else { return }
        
        print("📋 [DEBUG] \(serviceName) API 응답 데이터 크기: \(data.count) bytes")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📋 [DEBUG] \(serviceName) API 응답 내용 (처음 500자): \(responseString.prefix(500))")
        } else {
            print("❌ [DEBUG] \(serviceName) API 응답을 UTF-8로 디코딩 실패")
        }
    }
}

// MARK: - Yahoo Finance API Response Protocol and Error Types

/// Yahoo Finance API 응답 공통 프로토콜
///
/// 모든 Yahoo Finance API 응답 구조체가 구현해야 하는 프로토콜입니다.
/// 에러 정보를 포함하여 공통 에러 처리를 가능하게 합니다.
protocol YahooFinanceResponse {
    /// API 응답의 에러 정보
    var error: YFAPIError? { get }
}

/// Yahoo Finance API 에러 구조체
///
/// Yahoo Finance API에서 반환하는 에러 정보를 담는 구조체입니다.
struct YFAPIError: Codable {
    let code: String?
    let description: String
    
    private enum CodingKeys: String, CodingKey {
        case code, description
    }
}