import Testing
import Foundation
@testable import SwiftYFinance

struct QuoteDataTests {
    @Test
    func testFetchQuoteBasic() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        let quote = try await client.quote.fetch(ticker: ticker)
        
        #expect(quote.basicInfo.symbol == "AAPL")
        #expect((quote.marketData.regularMarketPrice ?? 0) > 0)
        #expect((quote.volumeInfo.regularMarketVolume ?? 0) > 0)
        #expect((quote.volumeInfo.marketCap ?? 0) > 0)
        #expect(!(quote.basicInfo.shortName ?? "").isEmpty)
    }
    
    @Test
    func testFetchQuoteWithoutRealtime() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "TSLA")
        
        let quote = try await client.quote.fetch(ticker: ticker)
        
        #expect(quote.basicInfo.symbol == "TSLA")
        #expect((quote.marketData.regularMarketPrice ?? 0) > 0)
        
        // 시장 시간 데이터 유효성 검증 (과거 데이터일 수 있으므로 현재 시간과 비교하지 않음)
        if let marketTime = quote.metadata.regularMarketTime {
            let marketDate = Date(timeIntervalSince1970: TimeInterval(marketTime))
            #expect(marketDate > Date(timeIntervalSince1970: 0)) // 유효한 타임스탬프
        }
    }
    
    @Test
    func testFetchQuoteAfterHours() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "NVDA")
        
        let quote = try await client.quote.fetch(ticker: ticker)
        
        #expect(quote.basicInfo.symbol == "NVDA")
        #expect((quote.marketData.regularMarketPrice ?? 0) > 0)
        
        // 시간외 거래 데이터 확인
        if let afterHoursPrice = quote.extendedHours.postMarketPrice {
            #expect(afterHoursPrice > 0)
            #expect(quote.extendedHours.postMarketTime != nil)
            #expect(quote.extendedHours.postMarketChangePercent != nil)
        }
        
        if let preMarketPrice = quote.extendedHours.preMarketPrice {
            #expect(preMarketPrice > 0)
            #expect(quote.extendedHours.preMarketTime != nil)
            #expect(quote.extendedHours.preMarketChangePercent != nil)
        }
    }
}