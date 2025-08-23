import Foundation

// MARK: - Quote API Builder

extension YFAPIURLBuilder {
    
    /// Quote API 전용 빌더
    public struct QuoteBuilder: Sendable {
        private let session: YFSession
        private let baseURL = "https://query1.finance.yahoo.com/v7/finance/quote"
        private var parameters: [String: String] = [:]
        
        init(session: YFSession) {
            self.session = session
        }
        
        private init(session: YFSession, parameters: [String: String]) {
            self.session = session
            self.parameters = parameters
        }
        
        /// 심볼 설정
        /// - Parameter symbol: 조회할 종목 심볼
        /// - Returns: 새로운 빌더 인스턴스
        public func symbol(_ symbol: String) -> QuoteBuilder {
            var newParams = parameters
            newParams["symbols"] = symbol
            return QuoteBuilder(session: session, parameters: newParams)
        }
        
        /// 여러 심볼 설정
        /// - Parameter symbols: 조회할 종목 심볼들
        /// - Returns: 새로운 빌더 인스턴스
        public func symbols(_ symbols: [String]) -> QuoteBuilder {
            var newParams = parameters
            newParams["symbols"] = symbols.joined(separator: ",")
            return QuoteBuilder(session: session, parameters: newParams)
        }
        
        /// 추가 파라미터 설정
        /// - Parameters:
        ///   - key: 파라미터 키
        ///   - value: 파라미터 값
        /// - Returns: 새로운 빌더 인스턴스
        public func parameter(_ key: String, _ value: String) -> QuoteBuilder {
            var newParams = parameters
            newParams[key] = value
            return QuoteBuilder(session: session, parameters: newParams)
        }
        
        /// URL 구성 (인증 포함)
        /// - Returns: 구성된 URL
        /// - Throws: URL 구성 실패 시
        public func build() async throws -> URL {
            return try await YFAPIURLBuilder.buildURL(baseURL: baseURL, parameters: parameters, session: session)
        }
        
        /// URL 구성 (공개 API - 인증 불필요)
        ///
        /// Quote API는 공개 API이므로 CSRF 인증이 필요하지 않습니다.
        /// Python yfinance와 동일한 방식으로 crumb 없이 구성합니다.
        ///
        /// - Returns: 구성된 URL (인증 없음)
        /// - Throws: URL 구성 실패 시
        public func buildPublic() throws -> URL {
            guard var urlComponents = URLComponents(string: baseURL) else {
                throw YFError.invalidURL
            }
            
            // 쿼리 파라미터 추가 (crumb 제외)
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
    }
}