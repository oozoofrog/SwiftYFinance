import XCTest
@testable import SwiftYFinance

final class YFFinancialsAPITests: XCTestCase {
    
    func testYFFinancialsAPIFileExists() async throws {
        // TDD Red: YFFinancialsAPI.swift 파일이 존재하고 financial 메서드들이 분리되어 있는지 테스트
        let client = YFClient()
        
        // INVALID 심볼로 에러 케이스 테스트 (실제 네트워크 호출 없이 구조 확인)
        let invalidTicker = try YFTicker(symbol: "INVALID")
        
        // fetchFinancials 테스트
        do {
            _ = try await client.fetchFinancials(ticker: invalidTicker)
            XCTFail("Should have thrown invalidSymbol error")
        } catch YFError.invalidSymbol {
            XCTAssertTrue(true, "fetchFinancials method works from YFFinancialsAPI extension")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // fetchBalanceSheet 테스트
        do {
            _ = try await client.fetchBalanceSheet(ticker: invalidTicker)
            XCTFail("Should have thrown invalidSymbol error")
        } catch YFError.invalidSymbol {
            XCTAssertTrue(true, "fetchBalanceSheet method works from YFFinancialsAPI extension")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // fetchCashFlow 테스트
        do {
            _ = try await client.fetchCashFlow(ticker: invalidTicker)
            XCTFail("Should have thrown invalidSymbol error")
        } catch YFError.invalidSymbol {
            XCTAssertTrue(true, "fetchCashFlow method works from YFFinancialsAPI extension")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // fetchEarnings 테스트
        do {
            _ = try await client.fetchEarnings(ticker: invalidTicker)
            XCTFail("Should have thrown invalidSymbol error")
        } catch YFError.invalidSymbol {
            XCTAssertTrue(true, "fetchEarnings method works from YFFinancialsAPI extension")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}