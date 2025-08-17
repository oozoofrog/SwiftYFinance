import Foundation

// MARK: - Screening API Extension
extension YFClient {
    
    // MARK: - Public Screening Methods
    
    /// 커스텀 스크리너로 종목 검색
    ///
    /// 사용자가 정의한 필터 조건에 따라 종목을 검색합니다.
    /// Python yfinance의 screen() 함수를 참조하여 구현되었습니다.
    ///
    /// - Parameter screener: 검색 조건이 설정된 스크리너
    /// - Returns: 검색 결과 배열
    /// - Throws: `YFError.invalidRequest` 등 API 오류
    ///
    /// ## 사용 예시
    /// ```swift
    /// let screener = YFScreener.equity()
    ///     .marketCap(min: 1_000_000_000)
    ///     .peRatio(max: 25)
    ///     .sortBy(.marketCap, ascending: false)
    /// 
    /// let results = try await client.screen(screener)
    /// ```
    /// - SeeAlso: yfinance-reference/yfinance/screener/screener.py:54
    public func screen(_ screener: YFScreener) async throws -> [YFScreenResult] {
        // 실제 Yahoo Finance Screener API 호출
        return try await fetchRealScreenResults(for: screener)
    }
    
    /// 사전 정의된 스크리너로 종목 검색
    ///
    /// Yahoo Finance에서 제공하는 인기 스크리너를 사용합니다.
    ///
    /// - Parameters:
    ///   - predefined: 사전 정의된 스크리너 유형
    ///   - limit: 결과 개수 제한 (기본값: 25)
    /// - Returns: 검색 결과 배열
    /// - Throws: `YFError.invalidRequest` 등 API 오류
    ///
    /// ## 사용 예시
    /// ```swift
    /// let results = try await client.screenPredefined(.dayGainers, limit: 50)
    /// ```
    /// - SeeAlso: yfinance-reference/yfinance/screener/screener.py:20-51
    public func screenPredefined(_ predefined: YFPredefinedScreener, limit: Int = 25) async throws -> [YFScreenResult] {
        let actualLimit = min(limit, 250) // Yahoo 제한
        return try await fetchRealPredefinedResults(for: predefined, limit: actualLimit)
    }
    
    // MARK: - Private Helper Methods for Real Screener API
    
    /// 실제 Yahoo Finance 커스텀 스크리너 API 호출
    private func fetchRealScreenResults(for screener: YFScreener) async throws -> [YFScreenResult] {
        // Yahoo Finance Screener API 요청
        let requestURL = try await buildScreenerURL(for: screener)
        var request = URLRequest(url: requestURL, timeoutInterval: session.timeout)
        
        // 기본 헤더 설정
        for (key, value) in session.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.urlSession.data(for: request)
        
        // HTTP 응답 상태 확인
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode != 200 {
                throw YFError.networkError
            }
        }
        
        // JSON 파싱
        let decoder = JSONDecoder()
        let screenerResponse = try decoder.decode(YFScreenerResponse.self, from: data)
        
        // Response를 YFScreenResult로 변환
        return screenerResponse.finance?.result?.compactMap { result in
            result.quotes?.compactMap { quote in
                convertToScreenResult(from: quote)
            }
        }.flatMap { $0 } ?? []
    }
    
    /// 실제 Yahoo Finance 사전 정의된 스크리너 API 호출
    private func fetchRealPredefinedResults(for predefined: YFPredefinedScreener, limit: Int) async throws -> [YFScreenResult] {
        // Yahoo Finance 사전 정의된 스크리너 API 요청
        let requestURL = try await buildPredefinedScreenerURL(for: predefined, limit: limit)
        var request = URLRequest(url: requestURL, timeoutInterval: session.timeout)
        
        // 기본 헤더 설정
        for (key, value) in session.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await session.urlSession.data(for: request)
        
        // HTTP 응답 상태 확인
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode != 200 {
                throw YFError.networkError
            }
        }
        
        // JSON 파싱
        let decoder = JSONDecoder()
        let screenerResponse = try decoder.decode(YFScreenerResponse.self, from: data)
        
        // Response를 YFScreenResult로 변환
        let results = screenerResponse.finance?.result?.compactMap { result in
            result.quotes?.compactMap { quote in
                convertToScreenResult(from: quote)
            }
        }.flatMap { $0 } ?? []
        
        return Array(results.prefix(limit))
    }
    
    /// Screener API URL 구성 헬퍼
    private func buildScreenerURL(for screener: YFScreener) async throws -> URL {
        let baseURL = "https://query1.finance.yahoo.com"
        
        var components = URLComponents(string: "\(baseURL)/v1/finance/screener")!
        components.queryItems = [
            URLQueryItem(name: "lang", value: "en-US"),
            URLQueryItem(name: "region", value: "US"),
            URLQueryItem(name: "formatted", value: "false"),
            URLQueryItem(name: "corsDomain", value: "finance.yahoo.com")
        ]
        
        guard let url = components.url else {
            throw YFError.invalidRequest
        }
        
        return url
    }
    
    /// 사전 정의된 스크리너 URL 구성 헬퍼  
    private func buildPredefinedScreenerURL(for predefined: YFPredefinedScreener, limit: Int) async throws -> URL {
        let baseURL = "https://query1.finance.yahoo.com"
        let screenerType = getPredefinedScreenerType(predefined)
        
        var components = URLComponents(string: "\(baseURL)/v1/finance/screener/predefined/saved")!
        components.queryItems = [
            URLQueryItem(name: "scrIds", value: screenerType),
            URLQueryItem(name: "count", value: String(limit)),
            URLQueryItem(name: "lang", value: "en-US"),
            URLQueryItem(name: "region", value: "US"),
            URLQueryItem(name: "formatted", value: "false"),
            URLQueryItem(name: "corsDomain", value: "finance.yahoo.com")
        ]
        
        guard let url = components.url else {
            throw YFError.invalidRequest
        }
        
        return url
    }
    
    /// 사전 정의된 스크리너 타입 매핑
    private func getPredefinedScreenerType(_ predefined: YFPredefinedScreener) -> String {
        switch predefined {
        case .dayGainers:
            return "day_gainers"
        case .dayLosers:
            return "day_losers" 
        case .mostActives:
            return "most_actives"
        case .aggressiveSmallCaps:
            return "aggressive_small_caps"
        case .growthTechnologyStocks:
            return "growth_technology_stocks"
        case .undervaluedGrowthStocks:
            return "undervalued_growth_stocks"
        case .undervaluedLargeCaps:
            return "undervalued_large_caps"
        case .smallCapGainers:
            return "small_cap_gainers"
        case .mostShortedStocks:
            return "most_shorted_stocks"
        }
    }
    
    /// Quote를 YFScreenResult로 변환
    private func convertToScreenResult(from quote: YFScreenerQuote) -> YFScreenResult? {
        guard let symbol = quote.symbol else {
            return nil
        }
        
        let ticker = YFTicker(symbol: symbol)
        
        return YFScreenResult(
            ticker: ticker,
            companyName: quote.shortName ?? quote.longName ?? symbol,
            price: quote.regularMarketPrice ?? 0,
            marketCap: quote.marketCap ?? 0,
            percentChange: quote.regularMarketChangePercent ?? 0,
            dayVolume: Int(quote.regularMarketVolume ?? 0),
            sector: quote.sector ?? "Unknown",
            industry: quote.industry,
            region: quote.region ?? "US",
            exchange: quote.fullExchangeName ?? "Unknown",
            peRatio: quote.forwardPE,
            returnOnEquity: quote.returnOnEquity,
            revenueGrowth: quote.revenueQuarterlyGrowth,
            debtToEquity: quote.debtToEquity
        )
    }
}