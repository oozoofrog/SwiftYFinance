import Testing
@testable import SwiftYFinance
import Foundation

struct YFFinancialsServiceTests {
    
    @Test("YFFinancialsService Protocol + Struct architecture")
    func testYFFinancialsServiceArchitecture() async {
        // TDD: YFFinancialsService struct가 존재하고 서비스 기반 호출이 작동하는지 테스트
        let client = YFClient()
        
        // INVALID 심볼로 에러 케이스 테스트 (실제 네트워크 호출 없이 구조 확인)
        let invalidTicker = YFTicker(symbol: "INVALID")
        
        // OOP & Protocol + Struct: 서비스 기반 호출 테스트
        do {
            _ = try await client.financials.fetch(ticker: invalidTicker)
            Issue.record("Should have thrown API error for INVALID ticker")
        } catch YFError.apiError(let message) {
            #expect(message.contains("Invalid symbol: INVALID"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    @Test("YFFinancialsService AAPL real data validation")
    func testAAPLFinancialsRealData() async throws {
        // Real API test with AAPL - comprehensive validation
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        let financials = try await client.financials.fetch(ticker: ticker)
        
        // Basic structure validation
        #expect(financials.ticker.symbol == "AAPL")
        #expect(financials.annualReports.count > 0, "Should have at least one annual report")
        
        guard let latestReport = financials.annualReports.first else {
            Issue.record("Should have at least one annual report")
            return
        }
        
        // Financial data validation (AAPL-specific realistic ranges)
        let revenueInBillions = latestReport.totalRevenue / 1_000_000_000
        let netIncomeInBillions = latestReport.netIncome / 1_000_000_000
        let assetsInBillions = latestReport.totalAssets / 1_000_000_000
        
        #expect(revenueInBillions > 300, "AAPL revenue should be over $300B")
        #expect(revenueInBillions < 500, "AAPL revenue should be under $500B")
        #expect(netIncomeInBillions > 50, "AAPL net income should be over $50B") 
        #expect(netIncomeInBillions < 150, "AAPL net income should be under $150B")
        #expect(assetsInBillions > 300, "AAPL assets should be over $300B")
        #expect(assetsInBillions < 500, "AAPL assets should be under $500B")
        
        // Profitability checks
        let profitMargin = latestReport.netIncome / latestReport.totalRevenue
        #expect(profitMargin > 0.15, "AAPL should have profit margin > 15%")
        #expect(profitMargin < 0.40, "AAPL profit margin should be < 40%")
        
        // Optional fields validation
        if let grossProfit = latestReport.grossProfit {
            #expect(grossProfit > 0, "Gross profit should be positive")
            #expect(grossProfit < latestReport.totalRevenue, "Gross profit should be less than revenue")
        }
        
        if let operatingIncome = latestReport.operatingIncome {
            #expect(operatingIncome > 0, "Operating income should be positive")
            #expect(operatingIncome < latestReport.totalRevenue, "Operating income should be less than revenue")
        }
        
        // Date validation - should be recent
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        #expect(latestReport.reportDate >= oneYearAgo, "Latest report should be within last year")
        
        // Multi-year data consistency
        if financials.annualReports.count >= 2 {
            let secondLatest = financials.annualReports[1]
            #expect(latestReport.reportDate > secondLatest.reportDate, "Reports should be chronologically ordered")
            
            // Revenue should be in reasonable range compared to previous year
            let revenueChange = abs(latestReport.totalRevenue - secondLatest.totalRevenue) / secondLatest.totalRevenue
            #expect(revenueChange < 0.5, "Year-over-year revenue change should be < 50%")
        }
    }
    
    @Test("YFFinancialsService multiple tickers validation")
    func testMultipleTickersFinancials() async throws {
        // Test different ticker symbols to ensure service works across companies
        let client = YFClient()
        let tickers = [
            YFTicker(symbol: "AAPL"),  // Tech
            YFTicker(symbol: "JPM"),   // Finance  
            YFTicker(symbol: "JNJ")    // Healthcare
        ]
        
        for ticker in tickers {
            let financials = try await client.financials.fetch(ticker: ticker)
            
            #expect(financials.ticker.symbol == ticker.symbol)
            #expect(financials.annualReports.count > 0, "[\(ticker.symbol)] Should have annual reports")
            
            if let latestReport = financials.annualReports.first {
                #expect(latestReport.totalRevenue > 0, "[\(ticker.symbol)] Revenue should be positive")
                #expect(latestReport.totalAssets > 0, "[\(ticker.symbol)] Assets should be positive")
                #expect(latestReport.totalLiabilities > 0, "[\(ticker.symbol)] Liabilities should be positive")
                
                // Basic financial sanity checks
                #expect(latestReport.totalAssets >= latestReport.totalLiabilities, 
                       "[\(ticker.symbol)] Assets should be >= Liabilities for healthy company")
            }
        }
    }
    
    @Test("YFFinancialsService error handling comprehensive")
    func testFinancialsErrorHandling() async {
        let client = YFClient()
        
        // Test various invalid ticker formats
        let invalidTickers = ["", "INVALID", "123", "TOOLONGTICKERNAMETHATSHOULDNOTWORK"]
        
        for invalidSymbol in invalidTickers {
            let ticker = YFTicker(symbol: invalidSymbol)
            
            do {
                _ = try await client.financials.fetch(ticker: ticker)
                if invalidSymbol == "INVALID" {
                    // Expected to fail for INVALID specifically
                    Issue.record("Should have thrown error for ticker: \(invalidSymbol)")
                }
                // For other invalid symbols, API might still return data or different errors
            } catch YFError.apiError(let message) {
                if invalidSymbol == "INVALID" {
                    #expect(message.contains("Invalid symbol"), "Error message should mention invalid symbol")
                }
            } catch {
                // Other network errors are acceptable for invalid tickers
                #expect(error is YFError, "Should throw YFError for invalid ticker: \(invalidSymbol)")
            }
        }
    }
    
    @Test("YFFinancialsService service composition validation")  
    func testFinancialsServiceComposition() async {
        // Test OOP principles: Composition, Encapsulation, Single Responsibility
        let client = YFClient()
        
        // Test that service is properly composed
        let financialsService = client.financials
        #expect(type(of: financialsService) == YFFinancialsService.self)
        
        // Test service properties (Composition pattern)
        #expect(financialsService.client.session != nil, "Service should have client with session")
        #expect(financialsService.debugEnabled == false, "Default debug should be false")
        
        // Test service with debug enabled
        let debugClient = YFClient(debugEnabled: true)
        let debugService = debugClient.financials
        #expect(debugService.debugEnabled == true, "Debug service should have debug enabled")
    }
    
    @Test("YFFinancialsService performance and concurrency")
    func testFinancialsConcurrency() async throws {
        // Test concurrent requests (Protocol + Struct should be thread-safe)
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        // Make multiple concurrent requests
        async let request1 = client.financials.fetch(ticker: ticker)
        async let request2 = client.financials.fetch(ticker: ticker)
        async let request3 = client.financials.fetch(ticker: ticker)
        
        let (result1, result2, result3) = try await (request1, request2, request3)
        
        // All results should be valid and consistent
        #expect(result1.ticker.symbol == "AAPL")
        #expect(result2.ticker.symbol == "AAPL")
        #expect(result3.ticker.symbol == "AAPL")
        
        // Results should be consistent (same data)
        #expect(result1.annualReports.count == result2.annualReports.count)
        #expect(result2.annualReports.count == result3.annualReports.count)
        
        if let latest1 = result1.annualReports.first,
           let latest2 = result2.annualReports.first,
           let latest3 = result3.annualReports.first {
            #expect(latest1.totalRevenue == latest2.totalRevenue)
            #expect(latest2.totalRevenue == latest3.totalRevenue)
        }
    }
}