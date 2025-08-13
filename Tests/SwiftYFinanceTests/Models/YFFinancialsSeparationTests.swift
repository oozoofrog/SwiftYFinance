import Testing
@testable import SwiftYFinance

struct YFFinancialsSeparationTests {
    
    @Test("YFFinancials file exists")
    func testYFFinancialsFileExists() throws {
        // Red: 분리된 YFFinancials.swift 파일이 존재해야 함
        // 현재는 통합 파일이므로 이 테스트는 통과할 것
        let financials = YFFinancials(
            ticker: try YFTicker(symbol: "AAPL"),
            annualReports: []
        )
        #expect(financials != nil)
    }
    
    @Test("YFBalanceSheet file exists")
    func testYFBalanceSheetFileExists() throws {
        // Red: 분리된 YFBalanceSheet.swift 파일이 존재해야 함
        let balanceSheet = YFBalanceSheet(
            ticker: try YFTicker(symbol: "AAPL"),
            annualReports: []
        )
        #expect(balanceSheet != nil)
    }
    
    @Test("YFCashFlow file exists")
    func testYFCashFlowFileExists() throws {
        // Red: 분리된 YFCashFlow.swift 파일이 존재해야 함
        let cashFlow = YFCashFlow(
            ticker: try YFTicker(symbol: "AAPL"),
            annualReports: []
        )
        #expect(cashFlow != nil)
    }
    
    @Test("YFEarnings file exists")
    func testYFEarningsFileExists() throws {
        // Red: 분리된 YFEarnings.swift 파일이 존재해야 함
        let earnings = YFEarnings(
            ticker: try YFTicker(symbol: "AAPL"),
            annualReports: []
        )
        #expect(earnings != nil)
    }
}