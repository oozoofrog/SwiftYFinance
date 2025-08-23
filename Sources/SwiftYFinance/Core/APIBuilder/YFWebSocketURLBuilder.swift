import Foundation

// MARK: - WebSocket API Builder

extension YFAPIURLBuilder {
    
    /// WebSocket API 전용 빌더
    /// 
    /// Yahoo Finance의 실시간 스트리밍 WebSocket 연결을 위한 URL 빌더입니다.
    /// yfinance Python 라이브러리의 WebSocket 클라이언트와 호환되는 기능을 제공합니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// let webSocketURL = try await YFAPIURLBuilder.webSocket(session: session)
    ///     .version(2)
    ///     .build()
    /// 
    /// // WebSocket 클라이언트와 함께 사용
    /// let client = YFWebSocketClient(url: webSocketURL)
    /// try await client.connect()
    /// try await client.subscribe(["AAPL", "BTC-USD"])
    /// ```
    public struct WebSocketBuilder: Sendable {
        private let session: YFSession
        private let baseURL = "wss://streamer.finance.yahoo.com"
        private var parameters: [String: String] = [:]
        
        init(session: YFSession) {
            self.session = session
            // 기본 버전 설정
            self.parameters["version"] = "2"
        }
        
        private init(session: YFSession, parameters: [String: String]) {
            self.session = session
            self.parameters = parameters
        }
        
        /// WebSocket 프로토콜 버전 설정
        /// - Parameter version: WebSocket 프로토콜 버전 (기본값: 2)
        /// - Returns: 새로운 빌더 인스턴스
        public func version(_ version: Int) -> WebSocketBuilder {
            var newParams = parameters
            newParams["version"] = String(version)
            return WebSocketBuilder(session: session, parameters: newParams)
        }
        
        /// 커스텀 파라미터 추가
        /// - Parameters:
        ///   - key: 파라미터 키
        ///   - value: 파라미터 값
        /// - Returns: 새로운 빌더 인스턴스
        public func parameter(_ key: String, _ value: String) -> WebSocketBuilder {
            var newParams = parameters
            newParams[key] = value
            return WebSocketBuilder(session: session, parameters: newParams)
        }
        
        /// WebSocket URL 구성
        /// - Returns: 구성된 WebSocket URL
        /// - Throws: URL 구성 실패 시
        public func build() async throws -> URL {
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
            
            return url
        }
        
        /// WebSocket 클라이언트 생성
        /// - Parameters:
        ///   - verbose: 디버그 로그 출력 여부
        ///   - urlSession: URLSession 인스턴스
        /// - Returns: 구성된 WebSocket 클라이언트
        /// - Throws: URL 구성 실패 시
        public func createClient(
            verbose: Bool = false,
            urlSession: URLSession = .shared
        ) async throws -> YFWebSocketClient {
            let url = try await build()
            return YFWebSocketClient(url: url, verbose: verbose, urlSession: urlSession)
        }
    }
}

// MARK: - Convenience Methods

extension YFAPIURLBuilder.WebSocketBuilder {
    
    /// 기본 설정으로 WebSocket 클라이언트 생성
    /// - Parameter verbose: 디버그 로그 출력 여부
    /// - Returns: 구성된 WebSocket 클라이언트
    /// - Throws: URL 구성 실패 시
    public func defaultClient(verbose: Bool = false) async throws -> YFWebSocketClient {
        return try await createClient(verbose: verbose)
    }
    
    /// 개발용 WebSocket 클라이언트 생성 (디버그 모드)
    /// - Returns: 디버그 모드가 활성화된 WebSocket 클라이언트
    /// - Throws: URL 구성 실패 시
    public func debugClient() async throws -> YFWebSocketClient {
        return try await createClient(verbose: true)
    }
    
    /// AsyncStream 기반 WebSocket 클라이언트 생성
    /// - Parameters:
    ///   - verbose: 디버그 로그 출력 여부
    ///   - symbols: 초기 구독할 심볼 배열
    /// - Returns: 구성되고 연결된 WebSocket 클라이언트
    /// - Throws: URL 구성 또는 연결 실패 시
    public func streamClient(
        verbose: Bool = false,
        autoConnect symbols: [String] = []
    ) async throws -> YFWebSocketClient {
        let client = try await createClient(verbose: verbose)
        
        if !symbols.isEmpty {
            try await client.connect()
            try await client.subscribe(symbols)
        }
        
        return client
    }
}