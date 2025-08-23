import Foundation

// MARK: - Quote Summary API Builder

extension YFAPIURLBuilder {
    
    /// Quote Summary API 전용 빌더
    /// 
    /// Yahoo Finance Quote Summary API는 60개의 모듈을 통해 종합적인 기업 정보를 제공합니다.
    /// 기본 Quote API보다 훨씬 상세하고 다양한 정보를 포함합니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// let url = try await YFAPIURLBuilder.quoteSummary(session: session)
    ///     .symbol("AAPL")
    ///     .modules([.summaryDetail, .financialData, .defaultKeyStatistics])
    ///     .build()
    /// ```
    public struct QuoteSummaryBuilder: Sendable {
        private let session: YFSession
        private let baseURL = "https://query2.finance.yahoo.com/v10/finance/quoteSummary"
        private var symbol: String = ""
        private var parameters: [String: String] = [:]
        
        init(session: YFSession) {
            self.session = session
            // 기본 파라미터 설정
            self.parameters = [
                "corsDomain": "finance.yahoo.com",
                "formatted": "false"
            ]
        }
        
        private init(session: YFSession, symbol: String, parameters: [String: String]) {
            self.session = session
            self.symbol = symbol
            self.parameters = parameters
        }
        
        /// 심볼 설정
        /// - Parameter symbol: 조회할 종목 심볼
        /// - Returns: 새로운 빌더 인스턴스
        public func symbol(_ symbol: String) -> QuoteSummaryBuilder {
            return QuoteSummaryBuilder(session: session, symbol: symbol, parameters: parameters)
        }
        
        /// 조회할 모듈들 설정
        /// - Parameter modules: Quote Summary 모듈 배열
        /// - Returns: 새로운 빌더 인스턴스
        public func modules(_ modules: [YFQuoteSummaryModule]) -> QuoteSummaryBuilder {
            var newParams = parameters
            let moduleStrings = modules.map { $0.rawValue }
            newParams["modules"] = moduleStrings.joined(separator: ",")
            return QuoteSummaryBuilder(session: session, symbol: symbol, parameters: newParams)
        }
        
        /// 단일 모듈 설정
        /// - Parameter module: Quote Summary 모듈
        /// - Returns: 새로운 빌더 인스턴스
        public func module(_ module: YFQuoteSummaryModule) -> QuoteSummaryBuilder {
            return modules([module])
        }
        
        /// 데이터 포맷팅 여부 설정
        /// - Parameter formatted: 포맷팅된 데이터 사용 여부 (기본값: false)
        /// - Returns: 새로운 빌더 인스턴스
        public func formatted(_ formatted: Bool) -> QuoteSummaryBuilder {
            var newParams = parameters
            newParams["formatted"] = String(formatted).lowercased()
            return QuoteSummaryBuilder(session: session, symbol: symbol, parameters: newParams)
        }
        
        /// CORS 도메인 설정
        /// - Parameter domain: CORS 도메인 (기본값: "finance.yahoo.com")
        /// - Returns: 새로운 빌더 인스턴스
        public func corsDomain(_ domain: String) -> QuoteSummaryBuilder {
            var newParams = parameters
            newParams["corsDomain"] = domain
            return QuoteSummaryBuilder(session: session, symbol: symbol, parameters: newParams)
        }
        
        /// 필수 정보 모듈들로 설정
        /// - Returns: 새로운 빌더 인스턴스
        public func essential() -> QuoteSummaryBuilder {
            return modules(YFQuoteSummaryModule.essential)
        }
        
        /// 종합 분석용 모듈들로 설정
        /// - Returns: 새로운 빌더 인스턴스
        public func comprehensive() -> QuoteSummaryBuilder {
            return modules(YFQuoteSummaryModule.comprehensive)
        }
        
        /// 재무제표 모듈들로 설정
        /// - Parameter quarterly: 분기별 포함 여부 (기본값: false)
        /// - Returns: 새로운 빌더 인스턴스
        public func financials(quarterly: Bool = false) -> QuoteSummaryBuilder {
            let financialModules = quarterly ? 
                YFQuoteSummaryModule.allFinancials : 
                YFQuoteSummaryModule.annualFinancials
            return modules(financialModules)
        }
        
        /// 추가 파라미터 설정
        /// - Parameters:
        ///   - key: 파라미터 키
        ///   - value: 파라미터 값
        /// - Returns: 새로운 빌더 인스턴스
        public func parameter(_ key: String, _ value: String) -> QuoteSummaryBuilder {
            var newParams = parameters
            newParams[key] = value
            return QuoteSummaryBuilder(session: session, symbol: symbol, parameters: newParams)
        }
        
        /// URL 구성
        /// - Returns: 구성된 URL
        /// - Throws: URL 구성 실패 시
        public func build() async throws -> URL {
            guard !symbol.isEmpty else {
                throw YFError.invalidParameter("Symbol cannot be empty")
            }
            
            let urlWithSymbol = "\(baseURL)/\(symbol)"
            return try await YFAPIURLBuilder.buildURL(baseURL: urlWithSymbol, parameters: parameters, session: session)
        }
    }
}