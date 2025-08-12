import Testing
import Foundation
@testable import SwiftYFinance

struct YFClientTests {
    @Test
    func testFetchPriceHistory1Day() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "AAPL")
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate)!
        
        let history = try await client.fetchHistory(ticker: ticker, period: .oneDay)
        
        #expect(history.prices.count > 0)
        #expect(history.ticker.symbol == "AAPL")
        #expect(history.startDate <= history.endDate)
    }
    
    @Test
    func testFetchPriceHistory1Week() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "MSFT")
        
        let history = try await client.fetchHistory(ticker: ticker, period: .oneWeek)
        
        #expect(history.prices.count > 0)
        #expect(history.ticker.symbol == "MSFT")
        #expect(history.startDate <= history.endDate)
        
        let expectedStartDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
        let timeDifference = abs(history.startDate.timeIntervalSince(expectedStartDate))
        #expect(timeDifference < 86400) // 1일 이내 오차 허용
    }
    
    @Test
    func testFetchPriceHistoryCustomRange() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "GOOGL")
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -3, to: endDate)!
        
        let history = try await client.fetchHistory(ticker: ticker, startDate: startDate, endDate: endDate)
        
        #expect(history.prices.count > 0)
        #expect(history.ticker.symbol == "GOOGL")
        #expect(history.startDate <= history.endDate)
        
        let timeDifference1 = abs(history.startDate.timeIntervalSince(startDate))
        let timeDifference2 = abs(history.endDate.timeIntervalSince(endDate))
        #expect(timeDifference1 < 86400) // 1일 이내 오차 허용
        #expect(timeDifference2 < 86400) // 1일 이내 오차 허용
    }
    
    @Test
    func testFetchPriceHistoryInvalidSymbol() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "INVALID")
        
        do {
            let _ = try await client.fetchHistory(ticker: ticker, period: .oneDay)
            Issue.record("Expected error for invalid symbol, but call succeeded")
        } catch YFError.invalidSymbol {
            // Expected error
        } catch {
            Issue.record("Expected YFError.invalidSymbol, got \(error)")
        }
    }
    
    @Test
    func testFetchPriceHistoryEmptyResult() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "EMPTY")
        
        let history = try await client.fetchHistory(ticker: ticker, period: .oneDay)
        
        #expect(history.prices.isEmpty)
        #expect(history.ticker.symbol == "EMPTY")
        #expect(history.startDate <= history.endDate)
    }
    
    @Test
    func testFetchQuoteBasic() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "AAPL")
        
        let quote = try await client.fetchQuote(ticker: ticker)
        
        #expect(quote.ticker.symbol == "AAPL")
        #expect(quote.regularMarketPrice > 0)
        #expect(quote.regularMarketVolume > 0)
        #expect(quote.marketCap > 0)
        #expect(!quote.shortName.isEmpty)
    }
    
    @Test
    func testFetchQuoteRealtime() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "TSLA")
        
        let quote = try await client.fetchQuote(ticker: ticker, realtime: true)
        
        #expect(quote.ticker.symbol == "TSLA")
        #expect(quote.regularMarketPrice > 0)
        #expect(quote.isRealtime == true)
        
        // 실시간 데이터는 최근 시간이어야 함
        let now = Date()
        let timeDifference = now.timeIntervalSince(quote.regularMarketTime)
        #expect(timeDifference < 300) // 5분 이내
    }
    
    @Test
    func testFetchQuoteAfterHours() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "NVDA")
        
        let quote = try await client.fetchQuote(ticker: ticker)
        
        #expect(quote.ticker.symbol == "NVDA")
        #expect(quote.regularMarketPrice > 0)
        
        // 시간외 거래 데이터 확인
        if let afterHoursPrice = quote.postMarketPrice {
            #expect(afterHoursPrice > 0)
            #expect(quote.postMarketTime != nil)
            #expect(quote.postMarketChangePercent != nil)
        }
        
        if let preMarketPrice = quote.preMarketPrice {
            #expect(preMarketPrice > 0)
            #expect(quote.preMarketTime != nil)
            #expect(quote.preMarketChangePercent != nil)
        }
    }
    
    @Test
    func testFetchFinancials() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "MSFT")
        
        let financials = try await client.fetchFinancials(ticker: ticker)
        
        #expect(financials.ticker.symbol == "MSFT")
        #expect(financials.annualReports.count > 0)
        
        let latestReport = financials.annualReports.first!
        #expect(latestReport.totalRevenue > 0)
        #expect(latestReport.netIncome > 0)
        #expect(latestReport.totalAssets > 0)
        #expect(latestReport.totalLiabilities > 0)
        #expect(!latestReport.reportDate.description.isEmpty)
    }
    
    @Test
    func testFetchBalanceSheet() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "GOOGL")
        
        let balanceSheet = try await client.fetchBalanceSheet(ticker: ticker)
        
        #expect(balanceSheet.ticker.symbol == "GOOGL")
        #expect(balanceSheet.annualReports.count > 0)
        
        let latestReport = balanceSheet.annualReports.first!
        #expect(latestReport.totalCurrentAssets > 0)
        #expect(latestReport.totalCurrentLiabilities > 0)
        #expect(latestReport.totalStockholderEquity > 0)
        #expect(latestReport.retainedEarnings > 0)
        #expect(!latestReport.reportDate.description.isEmpty)
    }
    
    @Test
    func testFetchCashFlow() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "AAPL")
        
        let cashFlow = try await client.fetchCashFlow(ticker: ticker)
        
        #expect(cashFlow.ticker.symbol == "AAPL")
        #expect(cashFlow.annualReports.count > 0)
        
        let latestReport = cashFlow.annualReports.first!
        #expect(latestReport.operatingCashFlow != 0)
        #expect(!latestReport.reportDate.description.isEmpty)
        
        // Operating Cash Flow와 Net PPE Purchase And Sale는 Python에서 expected_keys
        #expect(latestReport.operatingCashFlow > 0)
        
        // Optional fields 확인
        if let freeCashFlow = latestReport.freeCashFlow {
            #expect(freeCashFlow != 0)
        }
        
        if let capex = latestReport.capitalExpenditure {
            #expect(capex != 0)
        }
        
        // 연간 보고서들 간의 기간 확인 (약 365일)
        if cashFlow.annualReports.count >= 2 {
            let period = abs(cashFlow.annualReports[0].reportDate.timeIntervalSince(cashFlow.annualReports[1].reportDate))
            let expectedPeriodDays = 365.0 * 24 * 60 * 60 // 365일을 초로 변환
            let tolerance = 20.0 * 24 * 60 * 60 // 20일 허용 오차
            #expect(abs(period - expectedPeriodDays) < tolerance)
        }
    }
    
    @Test
    func testFetchEarnings() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "MSFT")
        
        let earnings = try await client.fetchEarnings(ticker: ticker)
        
        #expect(earnings.ticker.symbol == "MSFT")
        #expect(earnings.annualReports.count > 0)
        
        let latestReport = earnings.annualReports.first!
        #expect(latestReport.totalRevenue > 0)
        #expect(latestReport.earningsPerShare != 0)
        #expect(!latestReport.reportDate.description.isEmpty)
        
        // 수익과 EPS는 일반적으로 양수여야 함
        #expect(latestReport.totalRevenue > 0)
        #expect(latestReport.earningsPerShare > 0)
        
        // Optional fields 확인
        if let dilutedEPS = latestReport.dilutedEPS {
            #expect(dilutedEPS > 0)
        }
        
        if let netIncome = latestReport.netIncome {
            #expect(netIncome != 0) // 손실일 수도 있으므로 0이 아닌지만 확인
        }
        
        if let ebitda = latestReport.ebitda {
            #expect(ebitda > 0)
        }
        
        // 연간 보고서들 간의 기간 확인 (약 365일)
        if earnings.annualReports.count >= 2 {
            let period = abs(earnings.annualReports[0].reportDate.timeIntervalSince(earnings.annualReports[1].reportDate))
            let expectedPeriodDays = 365.0 * 24 * 60 * 60 // 365일을 초로 변환
            let tolerance = 30.0 * 24 * 60 * 60 // 30일 허용 오차 (회계연도 차이)
            #expect(abs(period - expectedPeriodDays) < tolerance)
        }
        
        // 추정치 확인 (있는 경우)
        if !earnings.estimates.isEmpty {
            let estimate = earnings.estimates.first!
            #expect(!estimate.period.isEmpty)
            #expect(estimate.consensusEPS != 0)
            
            if let high = estimate.highEstimate, let low = estimate.lowEstimate {
                #expect(high >= low) // 최고 추정치가 최저 추정치보다 크거나 같아야 함
                #expect(estimate.consensusEPS >= low && estimate.consensusEPS <= high)
            }
        }
    }
    
    /// 1분 간격 고해상도 데이터 조회 테스트
    @Test func testFetchHistoryWithInterval1Min() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "AAPL")
        
        // 1분 간격으로 1일 데이터 요청
        let historicalData = try await client.fetchPriceHistory(
            ticker: ticker,
            period: .oneDay,
            interval: .oneMinute
        )
        
        #expect(historicalData.ticker.symbol == "AAPL")
        #expect(!historicalData.prices.isEmpty)
        
        // 1분 간격 데이터는 1일에 약 390개 (6.5시간 거래시간)
        #expect(historicalData.prices.count > 300)
        #expect(historicalData.prices.count < 500)
        
        // 연속된 데이터 간격이 1분인지 확인
        if historicalData.prices.count >= 2 {
            let firstPrice = historicalData.prices[0]
            let secondPrice = historicalData.prices[1]
            let interval = abs(secondPrice.date.timeIntervalSince(firstPrice.date))
            let oneMinute = 60.0
            #expect(abs(interval - oneMinute) < 30.0) // 30초 허용 오차
        }
        
        // 각 가격 데이터의 필수 필드 확인
        let firstPrice = historicalData.prices.first!
        #expect(firstPrice.open > 0)
        #expect(firstPrice.high >= firstPrice.open)
        #expect(firstPrice.low <= firstPrice.open)
        #expect(firstPrice.close > 0)
        #expect(firstPrice.volume >= 0)
    }
    
    /// 5분 간격 고해상도 데이터 조회 테스트
    @Test func testFetchHistoryWithInterval5Min() async throws {
        let client = YFClient()
        let ticker = try YFTicker(symbol: "AAPL")
        
        // 5분 간격으로 1일 데이터 요청
        let historicalData = try await client.fetchPriceHistory(
            ticker: ticker,
            period: .oneDay,
            interval: .fiveMinutes
        )
        
        #expect(historicalData.ticker.symbol == "AAPL")
        #expect(!historicalData.prices.isEmpty)
        
        // 5분 간격 데이터는 1일에 약 78개 (6.5시간 거래시간 / 5분)
        #expect(historicalData.prices.count > 70)
        #expect(historicalData.prices.count < 90)
        
        // 연속된 데이터 간격이 5분인지 확인
        if historicalData.prices.count >= 2 {
            let firstPrice = historicalData.prices[0]
            let secondPrice = historicalData.prices[1]
            let interval = abs(secondPrice.date.timeIntervalSince(firstPrice.date))
            let fiveMinutes = 300.0 // 5분 = 300초
            #expect(abs(interval - fiveMinutes) < 60.0) // 1분 허용 오차
        }
        
        // 각 가격 데이터의 필수 필드 확인
        let firstPrice = historicalData.prices.first!
        #expect(firstPrice.open > 0)
        #expect(firstPrice.high >= firstPrice.open)
        #expect(firstPrice.low <= firstPrice.open)
        #expect(firstPrice.close > 0)
        #expect(firstPrice.volume >= 0)
    }
}