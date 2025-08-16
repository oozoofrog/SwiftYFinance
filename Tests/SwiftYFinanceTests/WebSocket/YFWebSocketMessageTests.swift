import Testing
import Foundation
@testable import SwiftYFinance

struct YFWebSocketMessageTests {
    
    @Test("YFWebSocketMessage basic initialization")
    func testWebSocketMessageInit() {
        // Given
        let symbol = "AAPL"
        let price = 150.0
        let timestamp = Date()
        let currency = "USD"
        
        // When
        let message = YFWebSocketMessage(
            symbol: symbol,
            price: price,
            timestamp: timestamp,
            currency: currency
        )
        
        // Then
        #expect(message.symbol == symbol)
        #expect(message.price == price)
        #expect(message.timestamp == timestamp)
        #expect(message.currency == currency)
    }
    
    @Test("YFWebSocketMessage with nil currency")
    func testWebSocketMessageWithNilCurrency() {
        // Given
        let symbol = "BTC-USD"
        let price = 94745.08
        let timestamp = Date()
        
        // When
        let message = YFWebSocketMessage(
            symbol: symbol,
            price: price,
            timestamp: timestamp,
            currency: nil
        )
        
        // Then
        #expect(message.symbol == symbol)
        #expect(message.price == price)
        #expect(message.timestamp == timestamp)
        #expect(message.currency == nil)
    }
    
    @Test("YFWebSocketMessage real Yahoo Finance data structure")
    func testWebSocketMessageWithYFinanceData() {
        // Given - Based on yfinance test data
        let symbol = "BTC-USD"
        let price = 94745.08
        let timestamp = Date(timeIntervalSince1970: 1736509140)
        let currency = "USD"
        
        // When
        let message = YFWebSocketMessage(
            symbol: symbol,
            price: price,
            timestamp: timestamp,
            currency: currency
        )
        
        // Then
        #expect(message.symbol == "BTC-USD")
        #expect(message.price == 94745.08)
        #expect(message.currency == "USD")
        #expect(message.timestamp.timeIntervalSince1970 == 1736509140)
    }
}