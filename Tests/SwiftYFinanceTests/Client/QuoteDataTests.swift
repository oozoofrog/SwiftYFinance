import Testing
import Foundation
@testable import SwiftYFinance

struct QuoteDataTests {
    @Test
    func testFetchQuoteBasic() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        let quote = try await client.fetchQuote(ticker: ticker)
        
        #expect(quote.ticker.symbol == "AAPL")
        #expect(quote.regularMarketPrice > 0)
        #expect(quote.regularMarketVolume > 0)
        #expect(quote.marketCap > 0)
        #expect(!quote.shortName.isEmpty)
    }
    
    @Test
    func testFetchQuoteRealtime() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "TSLA")
        
        let quote = try await client.fetchQuote(ticker: ticker, realtime: true)
        
        #expect(quote.ticker.symbol == "TSLA")
        #expect(quote.regularMarketPrice > 0)
        #expect(quote.isRealtime == true)
        
        // 실시간 데이터는 최근 시간이어야 함
        let now = Date()
        let timeDifference = now.timeIntervalSince(quote.regularMarketTime)
        #expect(timeDifference < 300) // 5분 이내
    }
    
    @Test
    func testFetchQuoteAfterHours() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "NVDA")
        
        let quote = try await client.fetchQuote(ticker: ticker)
        
        #expect(quote.ticker.symbol == "NVDA")
        #expect(quote.regularMarketPrice > 0)
        
        // 시간외 거래 데이터 확인
        if let afterHoursPrice = quote.postMarketPrice {
            #expect(afterHoursPrice > 0)
            #expect(quote.postMarketTime != nil)
            #expect(quote.postMarketChangePercent != nil)
        }
        
        if let preMarketPrice = quote.preMarketPrice {
            #expect(preMarketPrice > 0)
            #expect(quote.preMarketTime != nil)
            #expect(quote.preMarketChangePercent != nil)
        }
    }
}