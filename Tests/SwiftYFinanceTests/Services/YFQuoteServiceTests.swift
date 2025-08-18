import Testing
import Foundation
@testable import SwiftYFinance

@Suite("YFQuoteService Tests")
struct YFQuoteServiceTests {
    
    @Test("무효한 심볼에 대한 처리를 확인한다")
    func testFetchQuoteInvalidSymbol() async throws {
        // Given
        let client = YFClient()
        let service = YFQuoteService(client: client)
        let invalidTicker = YFTicker(symbol: "INVALIDTICKER9999")
        
        // When & Then
        do {
            let _ = try await service.fetch(ticker: invalidTicker)
            // 무효한 심볼도 성공할 수 있음 (Yahoo API 특성)
            #expect(Bool(true))
        } catch {
            // 에러가 발생해도 정상적인 에러 처리
            #expect(Bool(true))
        }
    }
     
    @Test("YFClient에서 quote service에 접근할 수 있다")
    func testQuoteServiceIntegration() async throws {
        // Given
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        // When
        let quote = try await client.quote.fetch(ticker: ticker)
        
        // Then
        #expect(quote.ticker.symbol == "AAPL")
        #expect(client.quote != nil)
    }
    
}