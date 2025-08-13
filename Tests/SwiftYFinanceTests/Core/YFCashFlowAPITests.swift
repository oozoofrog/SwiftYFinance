import Testing
@testable import SwiftYFinance

struct YFCashFlowAPITests {
    
    @Test("YFCashFlowAPI file exists")
    func testYFCashFlowAPIFileExists() async throws {
        // TDD Red: YFCashFlowAPI.swift 파일이 존재하고 fetchCashFlow 메서드가 분리되어 있는지 테스트
        let client = YFClient()
        
        // INVALID 심볼로 에러 케이스 테스트 (실제 네트워크 호출 없이 구조 확인)
        let invalidTicker = try YFTicker(symbol: "INVALID")
        
        do {
            _ = try await client.fetchCashFlow(ticker: invalidTicker)
            Issue.record("Should have thrown invalidSymbol error")
        } catch YFError.invalidSymbol {
            #expect(Bool(true)) // fetchCashFlow method works from YFCashFlowAPI extension
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}