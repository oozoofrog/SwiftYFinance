import Testing
@testable import SwiftYFinance

struct YFFinancialsAPITests {
    
    @Test("YFFinancialsService Protocol + Struct architecture")
    func testYFFinancialsServiceArchitecture() async {
        // TDD Red: YFFinancialsService struct가 존재하고 서비스 기반 호출이 작동하는지 테스트
        let client = YFClient()
        
        // INVALID 심볼로 에러 케이스 테스트 (실제 네트워크 호출 없이 구조 확인)
        let invalidTicker = YFTicker(symbol: "INVALID")
        
        // OOP & Protocol + Struct: 서비스 기반 호출 테스트
        do {
            _ = try await client.financials.fetch(ticker: invalidTicker)
            Issue.record("Should have thrown API error")
        } catch YFError.apiError(_) {
            #expect(Bool(true)) // YFFinancialsService works through Protocol + Struct pattern
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}