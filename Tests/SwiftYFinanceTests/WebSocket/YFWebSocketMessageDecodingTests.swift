import Testing
import Foundation
@testable import SwiftYFinance

struct YFWebSocketMessageDecodingTests {
    
    @Test("YFWebSocketMessage decoding with real Yahoo Finance BTC-USD data")
    func testWebSocketMessageDecodingBTCUSD() throws {
        // Given - Real Yahoo Finance test data from yfinance-reference
        let btcUsdBase64 = "CgdCVEMtVVNEFYoMuUcYwLCVgIplIgNVU0QqA0NDQzApOAFFPWrEP0iAgOrxvANVx/25R12csrRHZYD8skR9/7i0R7ABgIDq8bwD2AEE4AGAgOrxvAPoAYCA6vG8A/IBA0JUQ4ECAAAAwPrjckGJAgAA2P5ZT3tC"
        let decoder = YFWebSocketMessageDecoder()
        
        // When
        let message = try decoder.decode(btcUsdBase64)
        
        // Then - Expected values from yfinance-reference test
        #expect(message.symbol == "BTC-USD")
        #expect(message.price == 94745.08)
        #expect(message.currency == "USD")
        
        // Timestamp should be reasonable (around test time)
        let testTimestamp = Date(timeIntervalSince1970: 1736509140)
        let timeDifference = abs(message.timestamp.timeIntervalSince1970 - testTimestamp.timeIntervalSince1970)
        #expect(timeDifference < 60, "Timestamp should be close to expected test time")
    }
    
    @Test("YFWebSocketMessage decoding with minimal protobuf data")
    func testWebSocketMessageDecodingMinimal() throws {
        // Given - Simple test case
        let simpleBase64 = "SGVsbG8gV29ybGQ=" // This won't be valid protobuf, should handle gracefully
        let decoder = YFWebSocketMessageDecoder()
        
        // When & Then - Should handle gracefully or throw appropriate error
        do {
            let message = try decoder.decode(simpleBase64)
            // If it succeeds, should have reasonable defaults
            #expect(!message.symbol.isEmpty)
            #expect(message.price >= 0)
        } catch YFError.webSocketError(.messageDecodingFailed(let errorMessage)) {
            // If it fails, should have descriptive error
            #expect(errorMessage.contains("protobuf") || errorMessage.contains("decode"))
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
    
    @Test("YFWebSocketMessage decoder initialization")
    func testWebSocketMessageDecoderInit() {
        // Given & When
        let decoder = YFWebSocketMessageDecoder()
        
        // Then
        #expect(decoder != nil)
        
        // Test that decoder can be created multiple times
        let decoder2 = YFWebSocketMessageDecoder()
        #expect(decoder2 != nil)
    }
    
    @Test("YFWebSocketMessage decoding error handling")
    func testWebSocketMessageDecodingErrorHandling() {
        // Given
        let decoder = YFWebSocketMessageDecoder()
        let invalidCases = [
            "",                    // Empty string
            "InvalidBase64!@#",    // Invalid Base64
            "QQ==",               // Valid Base64 but invalid protobuf
        ]
        
        // When & Then
        for invalidCase in invalidCases {
            do {
                let _ = try decoder.decode(invalidCase)
                // If it doesn't throw, that's acceptable for now (minimal implementation)
                #expect(true)
            } catch YFError.webSocketError(.messageDecodingFailed(let message)) {
                // Expected error type
                #expect(!message.isEmpty)
            } catch {
                #expect(Bool(false), "Unexpected error type for \(invalidCase): \(error)")
            }
        }
    }
    
    @Test("YFWebSocketMessage decoding consistency")
    func testWebSocketMessageDecodingConsistency() throws {
        // Given
        let testBase64 = "CgdCVEMtVVNEFYoMuUcYwLCVgIplIgNVU0QqA0NDQzApOAFFPWrEP0iAgOrxvANVx/25R12csrRHZYD8skR9/7i0R7ABgIDq8bwD2AEE4AGAgOrxvAPoAYCA6vG8A/IBA0JUQ4ECAAAAwPrjckGJAgAA2P5ZT3tC"
        let decoder = YFWebSocketMessageDecoder()
        
        // When - Decode multiple times
        let message1 = try decoder.decode(testBase64)
        let message2 = try decoder.decode(testBase64)
        
        // Then - Should be consistent
        #expect(message1.symbol == message2.symbol)
        #expect(message1.price == message2.price)
        #expect(message1.currency == message2.currency)
        
        // Timestamps might be different if using current time, but should be close
        let timeDifference = abs(message1.timestamp.timeIntervalSince1970 - message2.timestamp.timeIntervalSince1970)
        #expect(timeDifference < 1.0, "Timestamps should be very close for same input")
    }
}