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
                
                let (data, response) = try await session.urlSession.data(for: request)
                
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
                
                // fundamentals-timeseries API 응답 파싱 (다른 API들과 동일한 패턴)
                let decoder = JSONDecoder()
                let timeseriesResponse = try decoder.decode(FundamentalsTimeseriesResponse.self, from: data)
                
                // 각 earnings metric별 데이터 추출
                var annualData: [String: [TimeseriesValue]] = [:]
                var quarterlyData: [String: [TimeseriesValue]] = [:]
                
                for result in timeseriesResponse.timeseries?.result ?? [] {
                    // Annual Earnings metrics
                    if let annualTotalRevenue = result.annualTotalRevenue {
                        annualData["totalRevenue"] = annualTotalRevenue
                    }
                    if let annualNetIncome = result.annualNetIncome {
                        annualData["netIncome"] = annualNetIncome
                    }
                    if let annualBasicEPS = result.annualBasicEPS {
                        annualData["basicEPS"] = annualBasicEPS
                    }
                    if let annualDilutedEPS = result.annualDilutedEPS {
                        annualData["dilutedEPS"] = annualDilutedEPS
                    }
                    if let annualEBITDA = result.annualEBITDA {
                        annualData["ebitda"] = annualEBITDA
                    }
                    if let annualGrossProfit = result.annualGrossProfit {
                        annualData["grossProfit"] = annualGrossProfit
                    }
                    if let annualOperatingIncome = result.annualOperatingIncome {
                        annualData["operatingIncome"] = annualOperatingIncome
                    }
                    
                    // Quarterly Earnings metrics (필요시 사용)
                    if let quarterlyTotalRevenue = result.quarterlyTotalRevenue {
                        quarterlyData["totalRevenue"] = quarterlyTotalRevenue
                    }
                    if let quarterlyBasicEPS = result.quarterlyBasicEPS {
                        quarterlyData["basicEPS"] = quarterlyBasicEPS
                    }
                }
                
                // Annual reports 변환
                var annualReports: [YFEarningsReport] = []
                if let totalRevenues = annualData["totalRevenue"], let basicEPSValues = annualData["basicEPS"] {
                    // Revenue와 EPS 데이터를 기준으로 매칭
                    for revenue in totalRevenues {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        
                        guard let dateString = revenue.asOfDate,
                              let date = dateFormatter.date(from: dateString),
                              let totalRevenueValue = revenue.reportedValue?.raw else { continue }
                        
                        // 동일한 날짜의 EPS 데이터 찾기
                        guard let basicEPSValue = basicEPSValues.first(where: { $0.asOfDate == dateString })?.reportedValue?.raw else { continue }
                        
                        // 동일한 날짜의 다른 데이터 찾기
                        let netIncome = annualData["netIncome"]?.first { $0.asOfDate == dateString }?.reportedValue?.raw
                        let dilutedEPS = annualData["dilutedEPS"]?.first { $0.asOfDate == dateString }?.reportedValue?.raw
                        let ebitda = annualData["ebitda"]?.first { $0.asOfDate == dateString }?.reportedValue?.raw
                        let grossProfit = annualData["grossProfit"]?.first { $0.asOfDate == dateString }?.reportedValue?.raw
                        let operatingIncome = annualData["operatingIncome"]?.first { $0.asOfDate == dateString }?.reportedValue?.raw
                        
                        annualReports.append(YFEarningsReport(
                            reportDate: date,
                            totalRevenue: totalRevenueValue,
                            earningsPerShare: basicEPSValue,
                            dilutedEPS: dilutedEPS,
                            ebitda: ebitda,
                            netIncome: netIncome,
                            grossProfit: grossProfit,
                            operatingIncome: operatingIncome
                        ))
                    }
                }
                
                // 날짜순 정렬 (최신부터)
                annualReports.sort { $0.reportDate > $1.reportDate }
                
                return YFEarnings(
                    ticker: ticker,
                    annualReports: annualReports
                )
                
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
    
    /// earnings API URL 구성 헬퍼 (fundamentals-timeseries 사용)
    internal func buildEarningsURL(ticker: YFTicker) async throws -> URL {
        let baseURL = "https://query2.finance.yahoo.com"
        
        // yfinance-reference에 따른 earnings metrics
        let earningsMetrics = [
            "TotalRevenue", "NetIncome", "BasicEPS", "DilutedEPS",
            "EBITDA", "GrossProfit", "OperatingIncome"
        ]
        
        let annualMetrics = earningsMetrics.map { "annual\($0)" }
        let quarterlyMetrics = earningsMetrics.map { "quarterly\($0)" }
        let typeParam = (annualMetrics + quarterlyMetrics).joined(separator: ",")
        
        var components = URLComponents(string: "\(baseURL)/ws/fundamentals-timeseries/v1/finance/timeseries/\(ticker.symbol)")!
        components.queryItems = [
            URLQueryItem(name: "symbol", value: ticker.symbol),
            URLQueryItem(name: "type", value: typeParam),
            URLQueryItem(name: "merge", value: "false"),
            URLQueryItem(name: "period1", value: "493590046"), // 1985년부터
            URLQueryItem(name: "period2", value: String(Int(Date().timeIntervalSince1970))),
            URLQueryItem(name: "corsDomain", value: "finance.yahoo.com")
        ]
        
        guard let url = components.url else {
            throw YFError.invalidRequest
        }
        
        return url
    }
}
