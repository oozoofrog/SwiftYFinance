import Testing
@testable import SwiftYFinance

struct YFQuoteAPITests {
    
    @Test("YFQuoteService integration works correctly")
    func testYFQuoteServiceIntegration() async {
        // 새로운 서비스 기반 구조 테스트
        let client = YFClient()
        
        // INVALID 심볼로 에러 케이스 테스트 (실제 네트워크 호출 없이 구조 확인)
        let invalidTicker = YFTicker(symbol: "INVALID")
        
        do {
            _ = try await client.quote.fetch(ticker: invalidTicker)
            Issue.record("Should have thrown API error")
        } catch YFError.apiError(_) {
            // 예상된 에러 - YFQuoteService가 정상 동작함
            #expect(Bool(true))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
        
        // realtime 파라미터가 있는 메서드도 동일하게 테스트
        do {
            _ = try await client.quote.fetch(ticker: invalidTicker, realtime: true)
            Issue.record("Should have thrown API error")
        } catch YFError.apiError(_) {
            // 예상된 에러 - YFQuoteService가 정상 동작함
            #expect(Bool(true))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
        
        // 새로운 fetch API도 테스트
        do {
            _ = try await client.quote.fetch(ticker: invalidTicker)
            Issue.record("Should have thrown API error")
        } catch YFError.apiError(_) {
            // 예상된 에러 - 새로운 fetch API가 정상 동작함
            #expect(Bool(true))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}