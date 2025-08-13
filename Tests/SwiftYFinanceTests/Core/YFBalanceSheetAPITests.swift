import XCTest
@testable import SwiftYFinance

final class YFBalanceSheetAPITests: XCTestCase {
    
    func testYFBalanceSheetAPIFileExists() async throws {
        // TDD Red: YFBalanceSheetAPI.swift 파일이 존재하고 fetchBalanceSheet 메서드가 분리되어 있는지 테스트
        let client = YFClient()
        
        // INVALID 심볼로 에러 케이스 테스트 (실제 네트워크 호출 없이 구조 확인)
        let invalidTicker = try YFTicker(symbol: "INVALID")
        
        do {
            _ = try await client.fetchBalanceSheet(ticker: invalidTicker)
            XCTFail("Should have thrown invalidSymbol error")
        } catch YFError.invalidSymbol {
            XCTAssertTrue(true, "fetchBalanceSheet method works from YFBalanceSheetAPI extension")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}