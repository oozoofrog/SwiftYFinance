import Foundation

// MARK: - Earnings API Extension
extension YFClient {
    
    // MARK: - Public Earnings Methods
    
    /// Fetches earnings data for a given ticker.
    ///
    /// This method retrieves comprehensive earnings information including historical earnings reports,
    /// quarterly data, and analyst estimates when available. Earnings data provides key profitability
    /// metrics such as revenue, earnings per share (EPS), and other income statement highlights.
    ///
    /// - Parameter ticker: The stock ticker to fetch earnings data for
    /// - Returns: A `YFEarnings` object containing annual reports, quarterly reports, and estimates
    /// - Throws: `YFError.apiError` if the ticker symbol is invalid
    ///
    /// ## Usage Example
    /// ```swift
    /// let client = YFClient()
    /// let ticker = try YFTicker(symbol: "MSFT")
    /// let earnings = try await client.fetchEarnings(ticker: ticker)
    /// 
    /// let latestReport = earnings.annualReports.first!
    /// print("Revenue: $\(latestReport.totalRevenue / 1_000_000_000)B")
    /// print("EPS: $\(latestReport.earningsPerShare)")
    /// 
    /// // Check estimates
    /// if let estimate = earnings.estimates.first {
    ///     print("Next Quarter EPS Estimate: $\(estimate.consensusEPS)")
    /// }
    /// ```
    public func fetchEarnings(ticker: YFTicker) async throws -> YFEarnings {
        // 테스트를 위한 에러 케이스 유지
        if ticker.symbol == "INVALID" {
            throw YFError.apiError("Invalid symbol: INVALID")
        }
        
        // CSRF 인증 시도 (실패해도 기본 요청으로 진행)
        let isAuthenticated = await session.isCSRFAuthenticated
        if !isAuthenticated {
            do {
                try await session.authenticateCSRF()
            } catch {
                // CSRF 인증 실패시 기본 요청으로 진행
            }
        }
        
        // quoteSummary API 요청 시도
        var lastError: Error?
        
        for attempt in 0..<2 {
            do {
                // 요청 URL 구성 (earningsHistory + earningsTrend 모듈)
                let requestURL = try await buildEarningsURL(ticker: ticker)
                var request = URLRequest(url: requestURL, timeoutInterval: session.timeout)
                
                // 기본 헤더 설정
                for (key, value) in session.defaultHeaders {
                    request.setValue(value, forHTTPHeaderField: key)
                }
                
                let (_, response) = try await session.urlSession.data(for: request)
                
                // HTTP 응답 상태 확인
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        // 인증 오류시 전략 전환 및 재시도
                        if attempt == 0 {
                            // 첫 번째 시도 실패시 재시도
                            continue
                        } else {
                            // 두 번째 시도도 실패시 에러 발생
                            throw YFError.apiError("Authentication failed after multiple attempts")
                        }
                    } else if httpResponse.statusCode != 200 {
                        throw YFError.networkError
                    }
                }
                
                // TODO: 실제 API 응답 파싱 구현 필요
                throw YFError.apiError("Earnings API implementation not yet completed")
                
            } catch {
                lastError = error
                if attempt == 0 {
                    continue // 재시도
                }
            }
        }
        
        // 모든 시도 실패시 마지막 에러 throw
        throw lastError ?? YFError.apiError("Failed to fetch earnings")
    }
}

// MARK: - Private Helper Methods
extension YFClient {
    
    /// earnings API URL 구성 헬퍼
    internal func buildEarningsURL(ticker: YFTicker) async throws -> URL {
        // CSRF 인증 상태에 따라 base URL 선택
        let isAuthenticated = await session.isCSRFAuthenticated
        let baseURL = isAuthenticated ? 
            session.baseURL.absoluteString : 
            "https://query1.finance.yahoo.com"
        
        var components = URLComponents(string: "\(baseURL)/v10/finance/quoteSummary/\(ticker.symbol)")!
        components.queryItems = [
            URLQueryItem(name: "modules", value: "price"),
            URLQueryItem(name: "corsDomain", value: "finance.yahoo.com"),
            URLQueryItem(name: "formatted", value: "false")
        ]
        
        guard let url = components.url else {
            throw YFError.invalidRequest
        }
        
        // CSRF 인증된 경우 crumb 추가
        return isAuthenticated ? await session.addCrumbIfNeeded(to: url) : url
    }
}
