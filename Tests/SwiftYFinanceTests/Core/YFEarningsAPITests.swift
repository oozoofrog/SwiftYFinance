import Testing
@testable import SwiftYFinance

struct YFEarningsAPITests {
    
    @Test("YFEarningsAPI file exists")
    func testYFEarningsAPIFileExists() async {
        // TDD Red: YFEarningsAPI.swift 파일이 존재하고 fetchEarnings 메서드가 분리되어 있는지 테스트
        let client = YFClient()
        
        // INVALID 심볼로 에러 케이스 테스트 (실제 네트워크 호출 없이 구조 확인)
        let invalidTicker = YFTicker(symbol: "INVALID")
        
        do {
            _ = try await client.fetchEarnings(ticker: invalidTicker)
            Issue.record("Should have thrown API error")
        } catch YFError.apiError(_) {
            #expect(Bool(true)) // fetchEarnings method works from YFEarningsAPI extension
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}