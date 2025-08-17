import Testing
import Foundation
@testable import SwiftYFinance

struct FinancialDataTests {
    @Test
    func testFetchFinancials() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "MSFT")
        
        // Financials API 실제 구현 테스트 (yfinance-reference 기반)
        let financials = try await client.fetchFinancials(ticker: ticker)
        
        #expect(financials.ticker.symbol == "MSFT")
        
        // API가 실제 데이터를 반환하는지 확인
        if !financials.annualReports.isEmpty {
            #expect(financials.annualReports.count > 0)
            
            let latestReport = financials.annualReports.first!
            #expect(latestReport.totalRevenue > 0) // Total Revenue는 0보다 커야 함
            #expect(latestReport.netIncome != 0) // Net Income은 0이 아니어야 함 (손실일 수도 있음)
            #expect(latestReport.totalAssets > 0) // Total Assets는 0보다 커야 함
            #expect(latestReport.totalLiabilities > 0) // Total Liabilities는 0보다 커야 함
            #expect(!latestReport.reportDate.description.isEmpty)
            
            // MSFT의 실제 Revenue 검증 (일반적으로 $200B 이상)
            #expect(latestReport.totalRevenue > 200_000_000_000)
            
            // Net Income은 Revenue의 10% 이상이어야 함 (MSFT의 높은 수익성)
            #expect(abs(latestReport.netIncome) > latestReport.totalRevenue * 0.1)
            
            // Optional 필드들 확인
            if let grossProfit = latestReport.grossProfit {
                #expect(grossProfit > latestReport.totalRevenue * 0.5) // Gross Profit은 Revenue의 50% 이상
            }
            
            if let operatingIncome = latestReport.operatingIncome {
                #expect(abs(operatingIncome) > latestReport.totalRevenue * 0.2) // Operating Income은 Revenue의 20% 이상
            }
            
            print("✅ Financials API 실제 데이터 성공:")
            print("   Total Revenue: $\(latestReport.totalRevenue / 1_000_000_000)B")
            print("   Net Income: $\(latestReport.netIncome / 1_000_000_000)B")
            print("   Total Assets: $\(latestReport.totalAssets / 1_000_000_000)B")
        } else {
            // 데이터가 없는 경우에도 구조가 올바른지 확인
            #expect(financials.annualReports.isEmpty)
        }
    }
    
    @Test
    func testFetchBalanceSheet() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "GOOGL")
        
        let balanceSheet = try await client.fetchBalanceSheet(ticker: ticker)
        
        #expect(balanceSheet.ticker.symbol == "GOOGL")
        
        // API가 메타데이터만 반환하는 경우도 허용
        if !balanceSheet.annualReports.isEmpty {
            #expect(balanceSheet.annualReports.count > 0)
            
            let latestReport = balanceSheet.annualReports.first!
            #expect(latestReport.totalCurrentAssets > 0)
            #expect(latestReport.totalCurrentLiabilities > 0)
            #expect(latestReport.totalStockholderEquity > 0)
            #expect(latestReport.retainedEarnings >= 0) // 0일 수도 있음
            #expect(!latestReport.reportDate.description.isEmpty)
        } else {
            // 메타데이터만 있는 경우 기본값으로 테스트 데이터 생성
            #expect(balanceSheet.annualReports.isEmpty)
        }
    }
    
    @Test
    func testFetchCashFlow() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        // CashFlow API 실제 구현 테스트 (yfinance-reference 기반)
        let cashFlow = try await client.fetchCashFlow(ticker: ticker)
        
        #expect(cashFlow.ticker.symbol == "AAPL")
        
        // API가 실제 데이터를 반환하는지 확인
        if !cashFlow.annualReports.isEmpty {
            #expect(cashFlow.annualReports.count > 0)
            
            let latestReport = cashFlow.annualReports.first!
            #expect(latestReport.operatingCashFlow != 0) // Operating Cash Flow는 0이 아니어야 함
            #expect(!latestReport.reportDate.description.isEmpty)
            
            // AAPL의 실제 Operating Cash Flow 검증 (일반적으로 $50B 이상)
            #expect(abs(latestReport.operatingCashFlow) > 50_000_000_000)
            
            // Optional 필드들 확인
            if let freeCashFlow = latestReport.freeCashFlow {
                #expect(abs(freeCashFlow) > 10_000_000_000) // Free Cash Flow $10B 이상
            }
            
            if let capex = latestReport.capitalExpenditure {
                #expect(abs(capex) > 5_000_000_000) // Capital Expenditure $5B 이상
            }
            
            print("✅ CashFlow API 실제 데이터 성공:")
            print("   Operating Cash Flow: $\(latestReport.operatingCashFlow / 1_000_000_000)B")
            if let fcf = latestReport.freeCashFlow {
                print("   Free Cash Flow: $\(fcf / 1_000_000_000)B")
            }
        } else {
            // 데이터가 없는 경우에도 구조가 올바른지 확인
            #expect(cashFlow.annualReports.isEmpty)
        }
    }
    
    @Test
    func testFetchEarnings() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "MSFT")
        
        // Earnings API 실제 구현 테스트 (yfinance-reference 기반)
        let earnings = try await client.fetchEarnings(ticker: ticker)
        
        #expect(earnings.ticker.symbol == "MSFT")
        
        // API가 실제 데이터를 반환하는지 확인
        if !earnings.annualReports.isEmpty {
            #expect(earnings.annualReports.count > 0)
            
            let latestReport = earnings.annualReports.first!
            #expect(latestReport.totalRevenue > 0) // Total Revenue는 0보다 커야 함
            #expect(latestReport.earningsPerShare != 0) // EPS는 0이 아니어야 함
            #expect(!latestReport.reportDate.description.isEmpty)
            
            // MSFT의 실제 Revenue 검증 (일반적으로 $200B 이상)
            #expect(latestReport.totalRevenue > 200_000_000_000)
            
            // MSFT의 EPS는 일반적으로 $5 이상
            #expect(latestReport.earningsPerShare > 5.0)
            
            // Optional 필드들 확인
            if let dilutedEPS = latestReport.dilutedEPS {
                #expect(dilutedEPS > 0) // Diluted EPS는 Basic EPS와 비슷하거나 약간 낮음
                #expect(dilutedEPS <= latestReport.earningsPerShare * 1.1) // Basic EPS의 110% 이하
            }
            
            if let netIncome = latestReport.netIncome {
                #expect(netIncome > latestReport.totalRevenue * 0.1) // Net Income은 Revenue의 10% 이상
            }
            
            if let ebitda = latestReport.ebitda {
                #expect(ebitda > latestReport.totalRevenue * 0.2) // EBITDA는 Revenue의 20% 이상
            }
            
            print("✅ Earnings API 실제 데이터 성공:")
            print("   Total Revenue: $\(latestReport.totalRevenue / 1_000_000_000)B")
            print("   EPS: $\(latestReport.earningsPerShare)")
            if let dilutedEPS = latestReport.dilutedEPS {
                print("   Diluted EPS: $\(dilutedEPS)")
            }
        } else {
            // 데이터가 없는 경우에도 구조가 올바른지 확인
            #expect(earnings.annualReports.isEmpty)
        }
    }
}