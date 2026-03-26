import Foundation
@testable import SwiftYFinance

/// 단위 테스트용 Mock 네트워크 제공자
///
/// 실제 네트워크 연결 없이 미리 정의된 응답을 반환하는 테스트 더블입니다.
/// YFSession에 주입하여 네트워크 의존 없이 서비스 로직을 테스트할 수 있습니다.
///
/// ## 사용 예시
/// ```swift
/// let mockData = """{"quoteResponse": {"result": [], "error": null}}""".data(using: .utf8)!
/// let mock = MockNetworkProvider(data: mockData, statusCode: 200)
/// let session = YFSession(networkProvider: mock)
/// let client = YFClient(session: session)
/// ```
struct MockNetworkProvider: YFNetworkProvider {

    /// 응답으로 반환할 데이터
    let data: Data

    /// HTTP 상태 코드
    let statusCode: Int

    /// 응답 헤더 (옵셔널)
    let headers: [String: String]

    /// 네트워크 에러 시뮬레이션 (nil이면 정상 응답)
    let error: Error?

    /// 기본 초기화 (정상 응답)
    init(
        data: Data = Data(),
        statusCode: Int = 200,
        headers: [String: String] = [:]
    ) {
        self.data = data
        self.statusCode = statusCode
        self.headers = headers
        self.error = nil
    }

    /// 에러 응답 초기화
    init(error: Error) {
        self.data = Data()
        self.statusCode = 0
        self.headers = [:]
        self.error = error
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        // 에러 시뮬레이션
        if let error {
            throw error
        }

        let url = request.url ?? URL(string: "https://test.example.com")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )!

        return (data, response)
    }
}

// MARK: - 편의 팩토리 메서드

extension MockNetworkProvider {

    /// JSON 문자열로부터 Mock 생성
    /// - Parameters:
    ///   - json: JSON 응답 문자열
    ///   - statusCode: HTTP 상태 코드 (기본값: 200)
    static func json(_ json: String, statusCode: Int = 200) -> MockNetworkProvider {
        let data = json.data(using: .utf8) ?? Data()
        return MockNetworkProvider(
            data: data,
            statusCode: statusCode,
            headers: ["Content-Type": "application/json"]
        )
    }

    /// 빈 성공 응답 Mock
    static var success: MockNetworkProvider {
        MockNetworkProvider(data: Data(), statusCode: 200)
    }

    /// 401 Unauthorized 응답 Mock
    static var unauthorized: MockNetworkProvider {
        MockNetworkProvider(data: Data(), statusCode: 401)
    }

    /// 429 Too Many Requests 응답 Mock
    static var rateLimited: MockNetworkProvider {
        MockNetworkProvider(data: Data(), statusCode: 429)
    }

    /// 500 Server Error 응답 Mock
    static var serverError: MockNetworkProvider {
        MockNetworkProvider(data: Data(), statusCode: 500)
    }
}
