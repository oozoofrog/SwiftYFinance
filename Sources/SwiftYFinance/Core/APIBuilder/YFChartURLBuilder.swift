import Foundation

// MARK: - Chart API Builder

extension YFAPIURLBuilder {
    
    /// Chart API 전용 빌더
    public struct ChartBuilder: Sendable {
        private let session: YFSession
        private let baseURL = "https://query2.finance.yahoo.com/v8/finance/chart"
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
        public func symbol(_ symbol: String) -> ChartBuilder {
            return ChartBuilder(session: session, symbol: symbol, parameters: parameters)
        }
        
        /// 기간 설정
        /// - Parameter period: 조회 기간
        /// - Returns: 새로운 빌더 인스턴스
        public func period(_ period: YFPeriod) -> ChartBuilder {
            var newParams = parameters
            newParams["range"] = period.rangeValue
            return ChartBuilder(session: session, symbol: symbol, parameters: newParams)
        }
        
        /// 인터벌 설정
        /// - Parameter interval: 데이터 간격
        /// - Returns: 새로운 빌더 인스턴스
        public func interval(_ interval: YFInterval) -> ChartBuilder {
            var newParams = parameters
            newParams["interval"] = interval.stringValue
            return ChartBuilder(session: session, symbol: symbol, parameters: newParams)
        }
        
        /// 날짜 범위 설정
        /// - Parameters:
        ///   - startDate: 시작 날짜
        ///   - endDate: 종료 날짜
        /// - Returns: 새로운 빌더 인스턴스
        public func dateRange(from startDate: Date, to endDate: Date) -> ChartBuilder {
            var newParams = parameters
            newParams["period1"] = String(Int(startDate.timeIntervalSince1970))
            newParams["period2"] = String(Int(endDate.timeIntervalSince1970))
            newParams.removeValue(forKey: "range") // range와 period1/2는 상충
            return ChartBuilder(session: session, symbol: symbol, parameters: newParams)
        }
        
        /// 추가 파라미터 설정
        /// - Parameters:
        ///   - key: 파라미터 키
        ///   - value: 파라미터 값
        /// - Returns: 새로운 빌더 인스턴스
        public func parameter(_ key: String, _ value: String) -> ChartBuilder {
            var newParams = parameters
            newParams[key] = value
            return ChartBuilder(session: session, symbol: symbol, parameters: newParams)
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