import Foundation

// MARK: - Search API Builder

extension YFAPIURLBuilder {
    
    /// Search API 전용 빌더
    public struct SearchBuilder: Sendable {
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
        
        /// 검색 쿼리 설정
        /// - Parameter query: 검색어
        /// - Returns: 새로운 빌더 인스턴스
        public func query(_ query: String) -> SearchBuilder {
            var newParams = parameters
            newParams["q"] = query
            return SearchBuilder(session: session, parameters: newParams)
        }
        
        /// 검색 결과 개수 제한
        /// - Parameter count: 최대 결과 개수
        /// - Returns: 새로운 빌더 인스턴스
        public func quotesCount(_ count: Int) -> SearchBuilder {
            var newParams = parameters
            newParams["quotesCount"] = String(count)
            return SearchBuilder(session: session, parameters: newParams)
        }
        
        /// 뉴스 결과 개수 제한
        /// - Parameter count: 최대 뉴스 개수
        /// - Returns: 새로운 빌더 인스턴스
        public func newsCount(_ count: Int) -> SearchBuilder {
            var newParams = parameters
            newParams["newsCount"] = String(count)
            return SearchBuilder(session: session, parameters: newParams)
        }
        
        /// Fuzzy 검색 설정
        /// - Parameter enabled: Fuzzy 검색 활성화 여부
        /// - Returns: 새로운 빌더 인스턴스
        public func fuzzyQuery(_ enabled: Bool) -> SearchBuilder {
            var newParams = parameters
            newParams["enableFuzzyQuery"] = String(enabled)
            return SearchBuilder(session: session, parameters: newParams)
        }
        
        /// 추가 파라미터 설정
        /// - Parameters:
        ///   - key: 파라미터 키
        ///   - value: 파라미터 값
        /// - Returns: 새로운 빌더 인스턴스
        public func parameter(_ key: String, _ value: String) -> SearchBuilder {
            var newParams = parameters
            newParams[key] = value
            return SearchBuilder(session: session, parameters: newParams)
        }
        
        /// URL 구성
        /// - Returns: 구성된 URL
        /// - Throws: URL 구성 실패 시
        public func build() async throws -> URL {
            return try await YFAPIURLBuilder.buildURL(baseURL: baseURL, parameters: parameters, session: session)
        }
    }
}