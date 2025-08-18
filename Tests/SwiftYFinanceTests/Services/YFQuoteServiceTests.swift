import Testing
import Foundation
@testable import SwiftYFinance

@Suite("YFQuoteService Tests")
struct YFQuoteServiceTests {
    
    // Helper function to create mock client
    private func createMockClient() -> YFClient {
        return YFClient()
    }
    
    @Test("YFQuoteService가 존재하고 초기화 가능하다")
    func testQuoteServiceInitialization() {
        // Given
        let client = createMockClient()
        
        // When
        let service = YFQuoteService(client: client)
        
        // Then
        #expect(service != nil)
    }
    
    @Test("fetch 메서드가 존재한다")
    func testFetchMethodExists() async throws {
        // Given
        let client = createMockClient()
        let service = YFQuoteService(client: client)
        let ticker = YFTicker(symbol: "AAPL")
        
        // When
        let quote = try await service.fetch(ticker: ticker)
        
        // Then
        #expect(quote.ticker.symbol == "AAPL")
    }
    
    @Test("잘못된 심볼에 대해 에러를 발생시킨다")
    func testFetchQuoteInvalidSymbol() async throws {
        // Given
        let client = createMockClient()
        let service = YFQuoteService(client: client)
        let invalidTicker = YFTicker(symbol: "INVALID")
        
        // When & Then
        do {
            let _ = try await service.fetch(ticker: invalidTicker)
            #expect(Bool(false), "Should have thrown an error for invalid symbol")
        } catch {
            #expect(error is YFError)
        }
    }
    
    @Test("새로운 fetch API가 동작한다")
    func testFetchAPI() async throws {
        // Given
        let client = createMockClient()
        let service = YFQuoteService(client: client)
        let ticker = YFTicker(symbol: "AAPL")
        
        // When
        let quote = try await service.fetch(ticker: ticker)
        
        // Then
        #expect(quote.ticker.symbol == "AAPL")
    }
    
    @Test("새로운 fetch API with realtime이 동작한다")
    func testFetchAPIWithRealtime() async throws {
        // Given
        let client = createMockClient()
        let service = YFQuoteService(client: client)
        let ticker = YFTicker(symbol: "AAPL")
        
        // When
        let quote = try await service.fetch(ticker: ticker, realtime: true)
        
        // Then
        #expect(quote.ticker.symbol == "AAPL")
        #expect(quote.isRealtime == true)
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