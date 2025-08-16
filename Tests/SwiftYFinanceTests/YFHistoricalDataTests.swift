import Testing
import Foundation
@testable import SwiftYFinance

struct YFHistoricalDataTests {
    @Test
    func testHistoricalDataInit() throws {
        let ticker = YFTicker(symbol: "AAPL")
        let startDate = Date().addingTimeInterval(-86400 * 30)
        let endDate = Date()
        
        let price1 = YFPrice(
            date: startDate,
            open: 150.0,
            high: 155.0,
            low: 149.0,
            close: 153.0,
            adjClose: 153.0,
            volume: 1000000
        )
        
        let price2 = YFPrice(
            date: startDate.addingTimeInterval(86400),
            open: 153.0,
            high: 157.0,
            low: 152.0,
            close: 156.0,
            adjClose: 156.0,
            volume: 1100000
        )
        
        let prices = [price1, price2]
        
        let historicalData = try YFHistoricalData(
            ticker: ticker,
            prices: prices,
            startDate: startDate,
            endDate: endDate
        )
        
        #expect(historicalData.ticker.symbol == "AAPL")
        #expect(historicalData.prices.count == 2)
        #expect(historicalData.startDate == startDate)
        #expect(historicalData.endDate == endDate)
        #expect(historicalData.prices[0] == price1)
        #expect(historicalData.prices[1] == price2)
    }
    
    @Test
    func testHistoricalDataDateRange() throws {
        let ticker = YFTicker(symbol: "AAPL")
        let startDate = Date().addingTimeInterval(-86400 * 30)
        let endDate = Date()
        
        #expect(throws: YFError.invalidDateRange) {
            _ = try YFHistoricalData(
                ticker: ticker,
                prices: [],
                startDate: endDate,
                endDate: startDate
            )
        }
        
        let validData = try YFHistoricalData(
            ticker: ticker,
            prices: [],
            startDate: startDate,
            endDate: endDate
        )
        
        #expect(validData.startDate < validData.endDate)
        
        let sameDate = Date()
        let sameDateData = try YFHistoricalData(
            ticker: ticker,
            prices: [],
            startDate: sameDate,
            endDate: sameDate
        )
        
        #expect(sameDateData.startDate == sameDateData.endDate)
    }
    
    @Test
    func testHistoricalDataEmpty() throws {
        let ticker = YFTicker(symbol: "AAPL")
        let startDate = Date().addingTimeInterval(-86400 * 30)
        let endDate = Date()
        
        let emptyData = try YFHistoricalData(
            ticker: ticker,
            prices: [],
            startDate: startDate,
            endDate: endDate
        )
        
        #expect(emptyData.prices.isEmpty)
        #expect(emptyData.isEmpty == true)
        
        let price = YFPrice(
            date: startDate,
            open: 150.0,
            high: 155.0,
            low: 149.0,
            close: 153.0,
            adjClose: 153.0,
            volume: 1000000
        )
        
        let nonEmptyData = try YFHistoricalData(
            ticker: ticker,
            prices: [price],
            startDate: startDate,
            endDate: endDate
        )
        
        #expect(nonEmptyData.isEmpty == false)
        #expect(nonEmptyData.count == 1)
    }
}