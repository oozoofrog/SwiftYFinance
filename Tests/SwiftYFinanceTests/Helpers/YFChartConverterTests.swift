import Testing
import Foundation
@testable import SwiftYFinance

@Suite("YFChartConverter Tests")
struct YFChartConverterTests {
    
    // Helper function to create a mock ChartMeta
    private func createMockMeta() -> ChartMeta {
        return ChartMeta(
            currency: "USD",
            symbol: "AAPL",
            exchangeName: nil,
            fullExchangeName: nil,
            instrumentType: nil,
            firstTradeDate: nil,
            regularMarketTime: nil,
            hasPrePostMarketData: nil,
            gmtoffset: nil,
            timezone: nil,
            exchangeTimezoneName: nil,
            regularMarketPrice: nil,
            fiftyTwoWeekHigh: nil,
            fiftyTwoWeekLow: nil,
            regularMarketDayHigh: nil,
            regularMarketDayLow: nil,
            regularMarketVolume: nil,
            longName: nil,
            shortName: nil,
            priceHint: nil,
            validRanges: nil
        )
    }
    
    @Test("빈 timestamp 배열을 받으면 빈 배열을 반환한다")
    func testEmptyTimestampReturnsEmptyArray() {
        // Given
        let converter = YFChartConverter()
        let result = ChartResult(
            meta: createMockMeta(),
            timestamp: nil,
            indicators: ChartIndicators(quote: [], adjclose: nil)
        )
        
        // When
        let prices = converter.convertToPrices(result)
        
        // Then
        #expect(prices.isEmpty)
    }
    
    @Test("단일 가격 데이터를 올바르게 변환한다")
    func testSinglePriceConversion() {
        // Given
        let converter = YFChartConverter()
        let timestamp = 1704067200 // 2024-01-01 00:00:00 UTC
        
        // ChartQuote는 커스텀 decoder가 있으므로 JSON을 통해 생성
        let quoteJSON = """
        {
            "open": [150.0],
            "high": [152.0],
            "low": [149.0],
            "close": [151.0],
            "volume": [1000000]
        }
        """.data(using: .utf8)!
        
        let quote = try! JSONDecoder().decode(ChartQuote.self, from: quoteJSON)
        
        let result = ChartResult(
            meta: createMockMeta(),
            timestamp: [timestamp],
            indicators: ChartIndicators(quote: [quote], adjclose: nil)
        )
        
        // When
        let prices = converter.convertToPrices(result)
        
        // Then
        #expect(prices.count == 1)
        let price = prices[0]
        #expect(price.open == 150.0)
        #expect(price.high == 152.0)
        #expect(price.low == 149.0)
        #expect(price.close == 151.0)
        #expect(price.volume == 1000000)
        #expect(price.adjClose == 151.0) // adjClose가 없으면 close 값 사용
        #expect(price.date == Date(timeIntervalSince1970: TimeInterval(timestamp)))
    }
    
    @Test("여러 가격 데이터를 올바르게 변환한다")
    func testMultiplePriceConversion() {
        // Given
        let converter = YFChartConverter()
        let timestamps = [1704067200, 1704153600] // 2024-01-01, 2024-01-02
        
        let quoteJSON = """
        {
            "open": [150.0, 151.5],
            "high": [152.0, 153.0],
            "low": [149.0, 150.5],
            "close": [151.0, 152.5],
            "volume": [1000000, 1200000]
        }
        """.data(using: .utf8)!
        
        let quote = try! JSONDecoder().decode(ChartQuote.self, from: quoteJSON)
        
        let result = ChartResult(
            meta: createMockMeta(),
            timestamp: timestamps,
            indicators: ChartIndicators(quote: [quote], adjclose: nil)
        )
        
        // When
        let prices = converter.convertToPrices(result)
        
        // Then
        #expect(prices.count == 2)
        #expect(prices[0].open == 150.0)
        #expect(prices[1].open == 151.5)
        #expect(prices[0].date < prices[1].date) // 날짜 순 정렬 확인
    }
    
    @Test("null 값(-1.0)을 포함한 데이터는 필터링된다")
    func testNullValueFiltering() {
        // Given
        let converter = YFChartConverter()
        let timestamps = [1704067200, 1704153600] // 2개 timestamp
        
        let quoteJSON = """
        {
            "open": [150.0, -1.0],
            "high": [152.0, 153.0],
            "low": [149.0, 150.5],
            "close": [151.0, 152.5],
            "volume": [1000000, 1200000]
        }
        """.data(using: .utf8)!
        
        let quote = try! JSONDecoder().decode(ChartQuote.self, from: quoteJSON)
        
        let result = ChartResult(
            meta: createMockMeta(),
            timestamp: timestamps,
            indicators: ChartIndicators(quote: [quote], adjclose: nil)
        )
        
        // When
        let prices = converter.convertToPrices(result)
        
        // Then
        #expect(prices.count == 1) // null 값 포함 데이터는 필터링
        #expect(prices[0].open == 150.0) // 유효한 데이터만 남음
    }
    
    @Test("조정 종가가 있으면 조정 종가를 사용한다")
    func testAdjustedCloseHandling() {
        // Given
        let converter = YFChartConverter()
        let timestamp = 1704067200
        
        let quoteJSON = """
        {
            "open": [150.0],
            "high": [152.0],
            "low": [149.0],
            "close": [151.0],
            "volume": [1000000]
        }
        """.data(using: .utf8)!
        
        let adjCloseJSON = """
        {
            "adjclose": [149.5]
        }
        """.data(using: .utf8)!
        
        let quote = try! JSONDecoder().decode(ChartQuote.self, from: quoteJSON)
        let adjClose = try! JSONDecoder().decode(ChartAdjClose.self, from: adjCloseJSON)
        
        let result = ChartResult(
            meta: createMockMeta(),
            timestamp: [timestamp],
            indicators: ChartIndicators(quote: [quote], adjclose: [adjClose])
        )
        
        // When
        let prices = converter.convertToPrices(result)
        
        // Then
        #expect(prices.count == 1)
        #expect(prices[0].close == 151.0) // 원래 종가
        #expect(prices[0].adjClose == 149.5) // 조정 종가 사용
    }
    
    @Test("데이터가 역순으로 들어와도 날짜순으로 정렬된다")
    func testDateSorting() {
        // Given
        let converter = YFChartConverter()
        let timestamps = [1704153600, 1704067200] // 역순: 2024-01-02, 2024-01-01
        
        let quoteJSON = """
        {
            "open": [151.5, 150.0],
            "high": [153.0, 152.0],
            "low": [150.5, 149.0],
            "close": [152.5, 151.0],
            "volume": [1200000, 1000000]
        }
        """.data(using: .utf8)!
        
        let quote = try! JSONDecoder().decode(ChartQuote.self, from: quoteJSON)
        
        let result = ChartResult(
            meta: createMockMeta(),
            timestamp: timestamps,
            indicators: ChartIndicators(quote: [quote], adjclose: nil)
        )
        
        // When
        let prices = converter.convertToPrices(result)
        
        // Then
        #expect(prices.count == 2)
        // 입력은 역순이지만 출력은 날짜 순으로 정렬
        #expect(prices[0].open == 150.0) // 2024-01-01 데이터가 첫 번째
        #expect(prices[1].open == 151.5) // 2024-01-02 데이터가 두 번째
        #expect(prices[0].date < prices[1].date)
    }
}