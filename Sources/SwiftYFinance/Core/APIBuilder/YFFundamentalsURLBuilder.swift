import Foundation

// MARK: - Fundamentals API Builder

extension YFAPIURLBuilder {
    
    /// Fundamentals API 전용 빌더
    public struct FundamentalsBuilder: Sendable {
        private let session: YFSession
        private let baseURL = "https://query1.finance.yahoo.com/ws/fundamentals-timeseries/v1/finance/timeseries"
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
        public func symbol(_ symbol: String) -> FundamentalsBuilder {
            var newParams = parameters
            newParams["symbol"] = symbol
            return FundamentalsBuilder(session: session, symbol: symbol, parameters: newParams)
        }
        
        /// 메트릭 타입 설정
        /// - Parameter types: 조회할 메트릭 타입들
        /// - Returns: 새로운 빌더 인스턴스
        public func types(_ types: [String]) -> FundamentalsBuilder {
            var newParams = parameters
            newParams["type"] = types.joined(separator: ",")
            return FundamentalsBuilder(session: session, symbol: symbol, parameters: newParams)
        }
        
        /// 기간 설정
        /// - Parameters:
        ///   - startPeriod: 시작 기간
        ///   - endPeriod: 종료 기간
        /// - Returns: 새로운 빌더 인스턴스
        public func period(from startPeriod: String, to endPeriod: String) -> FundamentalsBuilder {
            var newParams = parameters
            newParams["period1"] = startPeriod
            newParams["period2"] = endPeriod
            return FundamentalsBuilder(session: session, symbol: symbol, parameters: newParams)
        }
        
        /// 병합 설정
        /// - Parameter merge: 데이터 병합 여부
        /// - Returns: 새로운 빌더 인스턴스
        public func merge(_ merge: Bool) -> FundamentalsBuilder {
            var newParams = parameters
            newParams["merge"] = String(merge)
            return FundamentalsBuilder(session: session, symbol: symbol, parameters: newParams)
        }
        
        /// 추가 파라미터 설정
        /// - Parameters:
        ///   - key: 파라미터 키
        ///   - value: 파라미터 값
        /// - Returns: 새로운 빌더 인스턴스
        public func parameter(_ key: String, _ value: String) -> FundamentalsBuilder {
            var newParams = parameters
            newParams[key] = value
            return FundamentalsBuilder(session: session, symbol: symbol, parameters: newParams)
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