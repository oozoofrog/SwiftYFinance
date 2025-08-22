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
            let quote = try await service.fetch(ticker: invalidTicker)
            // 무효한 심볼도 성공할 수 있음 (Yahoo API 특성)
            // 하지만 실제 데이터는 없거나 최소한이어야 함
            let hasValidPrice = (quote.regularMarketPrice ?? 0) > 0
            let hasValidName = !(quote.shortName ?? "").isEmpty
            let hasValidData = hasValidPrice || hasValidName
            
            // 무효한 심볼은 유의미한 데이터가 없어야 함
            #expect(!hasValidData, "Invalid ticker should not return meaningful data")
        } catch {
            // 에러가 발생해도 정상적인 에러 처리 (API에 따라 다를 수 있음)
            #expect(error is YFError, "Should throw YFError for invalid symbols")
        }
    }
     
    @Test("YFClient에서 quote service에 접근할 수 있다")
    func testQuoteServiceIntegration() async throws {
        // Given
        let client = YFClient(debugEnabled: true)
        let ticker = YFTicker(symbol: "MSFT")
        
        // When
        let quote = try await client.quote.fetch(ticker: ticker)
        
        // Then
        #expect(quote.symbol == "MSFT")
    }
    
}