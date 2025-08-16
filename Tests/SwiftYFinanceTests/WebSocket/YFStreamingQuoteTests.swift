import Testing
import Foundation
@testable import SwiftYFinance

struct YFStreamingQuoteTests {
    
    @Test("YFStreamingQuote basic initialization")
    func testStreamingQuoteInit() {
        // Given
        let symbol = "TSLA"
        let price = 250.75
        let timestamp = Date()
        
        // When
        let quote = YFStreamingQuote(
            symbol: symbol,
            price: price,
            timestamp: timestamp
        )
        
        // Then
        #expect(quote.symbol == symbol)
        #expect(quote.price == price)
        #expect(quote.timestamp == timestamp)
    }
    
    @Test("YFStreamingQuote with change and volume")
    func testStreamingQuoteWithChangeAndVolume() {
        // Given
        let symbol = "AAPL"
        let price = 150.0
        let timestamp = Date()
        let change = 2.5
        let changePercent = 1.69
        let volume = 1000000
        
        // When
        let quote = YFStreamingQuote(
            symbol: symbol,
            price: price,
            timestamp: timestamp,
            change: change,
            changePercent: changePercent,
            volume: volume
        )
        
        // Then
        #expect(quote.symbol == symbol)
        #expect(quote.price == price)
        #expect(quote.timestamp == timestamp)
        #expect(quote.change == change)
        #expect(quote.changePercent == changePercent)
        #expect(quote.volume == volume)
    }
    
    @Test("YFStreamingQuote from YFWebSocketMessage conversion")
    func testStreamingQuoteFromWebSocketMessage() {
        // Given
        let message = YFWebSocketMessage(
            symbol: "BTC-USD",
            price: 94745.08,
            timestamp: Date(timeIntervalSince1970: 1736509140),
            currency: "USD"
        )
        
        // When
        let quote = YFStreamingQuote(from: message)
        
        // Then
        #expect(quote.symbol == "BTC-USD")
        #expect(quote.price == 94745.08)
        #expect(quote.timestamp.timeIntervalSince1970 == 1736509140)
        #expect(quote.change == nil)
        #expect(quote.changePercent == nil)
        #expect(quote.volume == nil)
    }
    
    @Test("YFStreamingQuote real-time update")
    func testStreamingQuoteRealTimeUpdate() {
        // Given
        let originalQuote = YFStreamingQuote(
            symbol: "MSFT",
            price: 300.0,
            timestamp: Date()
        )
        
        let newPrice = 305.25
        let newTimestamp = Date().addingTimeInterval(1)
        let change = 5.25
        let changePercent = 1.75
        
        // When
        let updatedQuote = originalQuote.updated(
            price: newPrice,
            timestamp: newTimestamp,
            change: change,
            changePercent: changePercent
        )
        
        // Then
        #expect(updatedQuote.symbol == "MSFT")
        #expect(updatedQuote.price == newPrice)
        #expect(updatedQuote.timestamp == newTimestamp)
        #expect(updatedQuote.change == change)
        #expect(updatedQuote.changePercent == changePercent)
    }
}