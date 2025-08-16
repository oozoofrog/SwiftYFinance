import Testing
import Foundation
@testable import SwiftYFinance

struct FinancialDataTests {
    @Test
    func testFetchFinancials() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "MSFT")
        
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
        let ticker = YFTicker(symbol: "GOOGL")
        
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
        let ticker = YFTicker(symbol: "AAPL")
        
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
        let ticker = YFTicker(symbol: "MSFT")
        
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
}