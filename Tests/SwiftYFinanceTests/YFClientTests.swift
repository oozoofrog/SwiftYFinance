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
}