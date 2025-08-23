import Foundation

// MARK: - Screener API Builder

extension YFAPIURLBuilder {
    
    /// Screener API 전용 빌더
    public struct ScreenerBuilder: Sendable {
        private let session: YFSession
        private let baseURL = "https://query1.finance.yahoo.com/v1/finance/screener"
        private var parameters: [String: String] = [:]
        
        init(session: YFSession) {
            self.session = session
        }
        
        private init(session: YFSession, parameters: [String: String]) {
            self.session = session
            self.parameters = parameters
        }
        
        /// 사전 정의된 스크리너 설정
        /// - Parameter screener: 사전 정의된 스크리너 타입
        /// - Returns: 새로운 빌더 인스턴스
        public func predefined(_ screener: YFPredefinedScreener) -> ScreenerBuilder {
            let screenerType: String
            switch screener {
            case .dayGainers:
                screenerType = "day_gainers"
            case .dayLosers:
                screenerType = "day_losers"
            case .mostActives:
                screenerType = "most_actives"
            case .aggressiveSmallCaps:
                screenerType = "aggressive_small_caps"
            case .growthTechnologyStocks:
                screenerType = "growth_technology_stocks"
            case .undervaluedGrowthStocks:
                screenerType = "undervalued_growth_stocks"
            case .undervaluedLargeCaps:
                screenerType = "undervalued_large_caps"
            case .smallCapGainers:
                screenerType = "small_cap_gainers"
            case .mostShortedStocks:
                screenerType = "most_shorted_stocks"
            }
            
            var newParams = parameters
            newParams["scrIds"] = screenerType
            return ScreenerBuilder(session: session, parameters: newParams)
        }
        
        /// 결과 개수 설정
        /// - Parameter count: 최대 결과 개수
        /// - Returns: 새로운 빌더 인스턴스
        public func count(_ count: Int) -> ScreenerBuilder {
            var newParams = parameters
            newParams["count"] = String(count)
            return ScreenerBuilder(session: session, parameters: newParams)
        }
        
        /// 언어 설정
        /// - Parameter lang: 언어 코드
        /// - Returns: 새로운 빌더 인스턴스
        public func language(_ lang: String) -> ScreenerBuilder {
            var newParams = parameters
            newParams["lang"] = lang
            return ScreenerBuilder(session: session, parameters: newParams)
        }
        
        /// 지역 설정
        /// - Parameter region: 지역 코드
        /// - Returns: 새로운 빌더 인스턴스
        public func region(_ region: String) -> ScreenerBuilder {
            var newParams = parameters
            newParams["region"] = region
            return ScreenerBuilder(session: session, parameters: newParams)
        }
        
        /// 추가 파라미터 설정
        /// - Parameters:
        ///   - key: 파라미터 키
        ///   - value: 파라미터 값
        /// - Returns: 새로운 빌더 인스턴스
        public func parameter(_ key: String, _ value: String) -> ScreenerBuilder {
            var newParams = parameters
            newParams[key] = value
            return ScreenerBuilder(session: session, parameters: newParams)
        }
        
        /// URL 구성
        /// - Returns: 구성된 URL
        /// - Throws: URL 구성 실패 시
        public func build() async throws -> URL {
            let urlWithPath = "\(baseURL)/predefined/saved"
            return try await YFAPIURLBuilder.buildURL(baseURL: urlWithPath, parameters: parameters, session: session)
        }
    }
}