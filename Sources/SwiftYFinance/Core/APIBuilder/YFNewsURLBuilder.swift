import Foundation

// MARK: - News API Builder

extension YFAPIURLBuilder {
    
    /// News API 전용 빌더 (Search API 기반)
    public struct NewsBuilder: Sendable {
        private let session: YFSession
        private let baseURL = "https://query2.finance.yahoo.com/v1/finance/search"
        private var parameters: [String: String] = [:]
        
        init(session: YFSession) {
            self.session = session
        }
        
        private init(session: YFSession, parameters: [String: String]) {
            self.session = session
            self.parameters = parameters
        }
        
        /// 종목 심볼 설정
        /// - Parameter symbol: 뉴스를 조회할 종목 심볼
        /// - Returns: 새로운 빌더 인스턴스
        public func symbol(_ symbol: String) -> NewsBuilder {
            var newParams = parameters
            newParams["q"] = symbol
            newParams["quotesCount"] = "0" // 뉴스만 조회
            return NewsBuilder(session: session, parameters: newParams)
        }
        
        /// 뉴스 개수 설정
        /// - Parameter count: 조회할 뉴스 개수
        /// - Returns: 새로운 빌더 인스턴스
        public func count(_ count: Int) -> NewsBuilder {
            var newParams = parameters
            newParams["newsCount"] = String(count)
            return NewsBuilder(session: session, parameters: newParams)
        }
        
        /// Fuzzy 검색 비활성화 (뉴스의 경우 정확한 매칭 선호)
        /// - Returns: 새로운 빌더 인스턴스
        public func disableFuzzyQuery() -> NewsBuilder {
            var newParams = parameters
            newParams["enableFuzzyQuery"] = "false"
            return NewsBuilder(session: session, parameters: newParams)
        }
        
        /// URL 구성
        /// - Returns: 구성된 URL
        /// - Throws: URL 구성 실패 시
        public func build() async throws -> URL {
            return try await YFAPIURLBuilder.buildURL(baseURL: baseURL, parameters: parameters, session: session)
        }
    }
}