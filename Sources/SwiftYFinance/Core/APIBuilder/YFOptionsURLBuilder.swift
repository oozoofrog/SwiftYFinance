import Foundation

// MARK: - Options API Builder

extension YFAPIURLBuilder {
    
    /// Options API 전용 빌더
    public struct OptionsBuilder: Sendable {
        private let session: YFSession
        private let baseURL = "https://query2.finance.yahoo.com/v7/finance/options"
        private var symbol: String = ""
        private var parameters: [String: String] = [:]
        
        init(session: YFSession) {
            self.session = session
        }
        
        private init(session: YFSession, symbol: String, parameters: [String: String]) {
            self.session = session
            self.symbol = symbol
            self.parameters = parameters
        }
        
        /// 심볼 설정
        /// - Parameter symbol: 조회할 종목 심볼
        /// - Returns: 새로운 빌더 인스턴스
        public func symbol(_ symbol: String) -> OptionsBuilder {
            return OptionsBuilder(session: session, symbol: symbol, parameters: parameters)
        }
        
        /// 만기일 설정
        /// - Parameter date: 옵션 만기일
        /// - Returns: 새로운 빌더 인스턴스
        public func expiration(_ date: Date) -> OptionsBuilder {
            var newParams = parameters
            newParams["date"] = String(Int(date.timeIntervalSince1970))
            return OptionsBuilder(session: session, symbol: symbol, parameters: newParams)
        }
        
        /// URL 구성
        /// - Returns: 구성된 URL
        /// - Throws: URL 구성 실패 시
        public func build() async throws -> URL {
            let urlWithSymbol = "\(baseURL)/\(symbol)"
            return try await YFAPIURLBuilder.buildURL(baseURL: urlWithSymbol, parameters: parameters, session: session)
        }
    }
}