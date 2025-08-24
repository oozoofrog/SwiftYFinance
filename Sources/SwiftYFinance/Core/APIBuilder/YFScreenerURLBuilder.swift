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
    
    /// Custom Screener API 전용 빌더
    /// 
    /// 사용자 정의 쿼리를 사용한 커스텀 스크리닝 기능을 제공합니다.
    /// yfinance Python 라이브러리의 EquityQuery/FundQuery와 호환됩니다.
    ///
    /// ## 사용 예시
    /// ```swift
    /// let query = YFScreenerQuery.and([
    ///     .eq("region", "us"),
    ///     .gte("intradaymarketcap", 10_000_000_000),
    ///     .eq("sector", "Technology")
    /// ])
    /// 
    /// let url = try await YFAPIURLBuilder.customScreener(session: session)
    ///     .query(query)
    ///     .count(25)
    ///     .build()
    /// ```
    public struct CustomScreenerBuilder: Sendable {
        private let session: YFSession
        private let baseURL = "https://query1.finance.yahoo.com/v1/finance/screener"
        private var query: YFScreenerQuery?
        private var requestBody: [String: Sendable] = [:]
        
        init(session: YFSession) {
            self.session = session
            // 기본 요청 파라미터 설정
            self.requestBody = [
                "offset": 0,
                "count": 25,
                "userId": "",
                "userIdType": "guid"
            ]
        }
        
        private init(session: YFSession, query: YFScreenerQuery?, requestBody: [String: Sendable]) {
            self.session = session
            self.query = query
            self.requestBody = requestBody
        }
        
        /// 스크리너 쿼리 설정
        /// - Parameter query: 스크리너 쿼리
        /// - Returns: 새로운 빌더 인스턴스
        public func query(_ query: YFScreenerQuery) -> CustomScreenerBuilder {
            var newBody = requestBody
            newBody["query"] = query.toDictionary()
            // Python yfinance와 동일하게 quoteType 필드 추가 (line 197 in screener.py)
            newBody["quoteType"] = "EQUITY"
            return CustomScreenerBuilder(session: session, query: query, requestBody: newBody)
        }
        
        /// 결과 개수 설정
        /// - Parameter count: 최대 결과 개수 (최대 250)
        /// - Returns: 새로운 빌더 인스턴스
        public func count(_ count: Int) -> CustomScreenerBuilder {
            var newBody = requestBody
            newBody["count"] = min(count, 250)
            return CustomScreenerBuilder(session: session, query: query, requestBody: newBody)
        }
        
        /// 오프셋 설정
        /// - Parameter offset: 결과 시작 위치
        /// - Returns: 새로운 빌더 인스턴스
        public func offset(_ offset: Int) -> CustomScreenerBuilder {
            var newBody = requestBody
            newBody["offset"] = offset
            return CustomScreenerBuilder(session: session, query: query, requestBody: newBody)
        }
        
        /// 정렬 필드 설정
        /// - Parameter field: 정렬 기준 필드
        /// - Returns: 새로운 빌더 인스턴스
        public func sortField(_ field: String) -> CustomScreenerBuilder {
            var newBody = requestBody
            newBody["sortField"] = field
            return CustomScreenerBuilder(session: session, query: query, requestBody: newBody)
        }
        
        /// 정렬 순서 설정
        /// - Parameter ascending: 오름차순 여부 (기본값: false)
        /// - Returns: 새로운 빌더 인스턴스
        public func sortOrder(ascending: Bool = false) -> CustomScreenerBuilder {
            var newBody = requestBody
            newBody["sortType"] = ascending ? "ASC" : "DESC"
            return CustomScreenerBuilder(session: session, query: query, requestBody: newBody)
        }
        
        /// 사용자 ID 설정
        /// - Parameter userId: 사용자 ID
        /// - Returns: 새로운 빌더 인스턴스
        public func userId(_ userId: String) -> CustomScreenerBuilder {
            var newBody = requestBody
            newBody["userId"] = userId
            return CustomScreenerBuilder(session: session, query: query, requestBody: newBody)
        }
        
        /// 사용자 ID 타입 설정
        /// - Parameter userIdType: 사용자 ID 타입 (기본값: "guid")
        /// - Returns: 새로운 빌더 인스턴스
        public func userIdType(_ userIdType: String) -> CustomScreenerBuilder {
            var newBody = requestBody
            newBody["userIdType"] = userIdType
            return CustomScreenerBuilder(session: session, query: query, requestBody: newBody)
        }
        
        /// 추가 파라미터 설정
        /// - Parameters:
        ///   - key: 파라미터 키
        ///   - value: 파라미터 값
        /// - Returns: 새로운 빌더 인스턴스
        public func parameter(_ key: String, _ value: Sendable) -> CustomScreenerBuilder {
            var newBody = requestBody
            newBody[key] = value
            return CustomScreenerBuilder(session: session, query: query, requestBody: newBody)
        }
        
        /// HTTP Method 반환 (항상 POST)
        public var httpMethod: String {
            return "POST"
        }
        
        /// Request Body JSON 데이터 반환
        public func getRequestBody() throws -> Data {
            guard query != nil else {
                throw YFError.invalidParameter("Query cannot be empty for custom screener")
            }
            
            return try JSONSerialization.data(withJSONObject: requestBody, options: [.prettyPrinted])
        }
        
        /// URL 구성
        /// - Returns: 구성된 URL
        /// - Throws: URL 구성 실패 시
        public func build() async throws -> URL {
            guard query != nil else {
                throw YFError.invalidParameter("Query cannot be empty for custom screener")
            }
            
            return try await YFAPIURLBuilder.buildURL(baseURL: baseURL, parameters: [:], session: session)
        }
    }
}