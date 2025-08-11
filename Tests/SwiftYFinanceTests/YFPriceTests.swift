import Testing
import Foundation
@testable import SwiftYFinance

struct YFPriceTests {
    @Test
    func testPriceInitWithValues() {
        let date = Date()
        let price = YFPrice(
            date: date,
            open: 150.0,
            high: 155.0,
            low: 149.0,
            close: 153.0,
            adjClose: 153.0,
            volume: 1000000
        )
        
        #expect(price.date == date)
        #expect(price.open == 150.0)
        #expect(price.high == 155.0)
        #expect(price.low == 149.0)
        #expect(price.close == 153.0)
        #expect(price.adjClose == 153.0)
        #expect(price.volume == 1000000)
    }
    
    @Test
    func testPriceComparison() {
        let date1 = Date()
        let date2 = Date().addingTimeInterval(86400)
        
        let price1 = YFPrice(
            date: date1,
            open: 150.0,
            high: 155.0,
            low: 149.0,
            close: 153.0,
            adjClose: 153.0,
            volume: 1000000
        )
        
        let price2 = YFPrice(
            date: date2,
            open: 150.0,
            high: 155.0,
            low: 149.0,
            close: 153.0,
            adjClose: 153.0,
            volume: 1000000
        )
        
        let price3 = YFPrice(
            date: date1,
            open: 150.0,
            high: 155.0,
            low: 149.0,
            close: 153.0,
            adjClose: 153.0,
            volume: 1000000
        )
        
        #expect(price1 == price3)
        #expect(price1 != price2)
        #expect(price1 < price2)
        #expect(price2 > price1)
    }
    
    @Test
    func testPriceCodable() throws {
        let date = Date()
        let originalPrice = YFPrice(
            date: date,
            open: 150.0,
            high: 155.0,
            low: 149.0,
            close: 153.0,
            adjClose: 152.5,
            volume: 1000000
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(originalPrice)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedPrice = try decoder.decode(YFPrice.self, from: data)
        
        #expect(abs(decodedPrice.date.timeIntervalSince1970 - date.timeIntervalSince1970) < 1.0)
        #expect(decodedPrice.open == originalPrice.open)
        #expect(decodedPrice.high == originalPrice.high)
        #expect(decodedPrice.low == originalPrice.low)
        #expect(decodedPrice.close == originalPrice.close)
        #expect(decodedPrice.adjClose == originalPrice.adjClose)
        #expect(decodedPrice.volume == originalPrice.volume)
    }
}