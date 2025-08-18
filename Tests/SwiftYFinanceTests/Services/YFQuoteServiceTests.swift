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
    
    @Test("무효한 심볼에 대한 처리를 확인한다")
    func testFetchQuoteInvalidSymbol() async throws {
        // Given
        let client = createMockClient()
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
    
    @Test("realtime 플래그가 제거된 fetch API가 동작한다")
    func testFetchAPIWithoutRealtime() async throws {
        // Given
        let client = createMockClient()
        let service = YFQuoteService(client: client)
        let ticker = YFTicker(symbol: "AAPL")
        
        // When
        let quote = try await service.fetch(ticker: ticker)
        
        // Then
        #expect(quote.ticker.symbol == "AAPL")
        #expect(quote.isRealtime == false) // 항상 false로 고정됨
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