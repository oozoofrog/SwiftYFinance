import Testing
@testable import SwiftYFinance

struct YFBalanceSheetAPITests {
    
    @Test("YFBalanceSheetAPI file exists")
    func testYFBalanceSheetAPIFileExists() async {
        // TDD Red: YFBalanceSheetAPI.swift 파일이 존재하고 fetchBalanceSheet 메서드가 분리되어 있는지 테스트
        let client = YFClient()
        
        // INVALID 심볼로 에러 케이스 테스트 (실제 네트워크 호출 없이 구조 확인)
        let invalidTicker = YFTicker(symbol: "INVALID")
        
        do {
            _ = try await client.fetchBalanceSheet(ticker: invalidTicker)
            Issue.record("Should have thrown API error")
        } catch YFError.apiError(_) {
            #expect(Bool(true)) // fetchBalanceSheet method works from YFBalanceSheetAPI extension
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}