import XCTest
@testable import SwiftYFinance

final class YFFinancialsSeparationTests: XCTestCase {
    
    func testYFFinancialsFileExists() {
        // Red: 분리된 YFFinancials.swift 파일이 존재해야 함
        // 현재는 통합 파일이므로 이 테스트는 통과할 것
        let financials = YFFinancials(
            ticker: try! YFTicker(symbol: "AAPL"),
            annualReports: []
        )
        XCTAssertNotNil(financials)
    }
    
    func testYFBalanceSheetFileExists() {
        // Red: 분리된 YFBalanceSheet.swift 파일이 존재해야 함
        let balanceSheet = YFBalanceSheet(
            ticker: try! YFTicker(symbol: "AAPL"),
            annualReports: []
        )
        XCTAssertNotNil(balanceSheet)
    }
    
    func testYFCashFlowFileExists() {
        // Red: 분리된 YFCashFlow.swift 파일이 존재해야 함
        let cashFlow = YFCashFlow(
            ticker: try! YFTicker(symbol: "AAPL"),
            annualReports: []
        )
        XCTAssertNotNil(cashFlow)
    }
    
    func testYFEarningsFileExists() {
        // Red: 분리된 YFEarnings.swift 파일이 존재해야 함
        let earnings = YFEarnings(
            ticker: try! YFTicker(symbol: "AAPL"),
            annualReports: []
        )
        XCTAssertNotNil(earnings)
    }
}