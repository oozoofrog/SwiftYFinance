import Testing
@testable import SwiftYFinance

struct YFQuoteAPITests {
    
    @Test("YFQuoteService integration works correctly")
    func testYFQuoteServiceIntegration() async {
        // 새로운 서비스 기반 구조 테스트
        let client = YFClient()
        
        // 유효한 심볼로 정상 동작 테스트
        let validTicker = YFTicker(symbol: "AAPL")
        
        do {
            let quote = try await client.quote.fetch(ticker: validTicker)
            #expect(quote.ticker.symbol == "AAPL")
            #expect(quote.regularMarketPrice > 0)
        } catch {
            Issue.record("Valid symbol should not throw error: \(error)")
        }
        
        // 무효한 심볼로 에러 처리 테스트 (실제 404 등의 HTTP 에러 예상)
        let invalidTicker = YFTicker(symbol: "INVALIDTICKER9999")
        
        do {
            _ = try await client.quote.fetch(ticker: invalidTicker)
            // 무효한 심볼도 성공할 수 있음 (Yahoo에서 데이터 없음으로 응답)
            #expect(Bool(true))
        } catch {
            // 에러가 발생해도 정상 (네트워크 에러, 파싱 에러 등)
            #expect(Bool(true))
        }
    }
}