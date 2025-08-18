import Testing
import Foundation
@testable import SwiftYFinance

struct PriceHistoryTests {
    @Test
    func testFetchPriceHistory1Day() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate)!
        
        let history = try await client.history.fetch(ticker: ticker, period: .oneDay)
        
        #expect(history.prices.count > 0)
        #expect(history.ticker.symbol == "AAPL")
        #expect(history.startDate <= history.endDate)
    }
    
    @Test
    func testFetchPriceHistory1Week() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "MSFT")
        
        let history = try await client.history.fetch(ticker: ticker, period: .oneWeek)
        
        #expect(history.prices.count > 0)
        #expect(history.ticker.symbol == "MSFT")
        #expect(history.startDate <= history.endDate)
        
        let expectedStartDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
        let timeDifference = abs(history.startDate.timeIntervalSince(expectedStartDate))
        #expect(timeDifference < 86400) // 1일 이내 오차 허용
    }
    
    @Test
    func testFetchPriceHistoryCustomRange() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "GOOGL")
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -3, to: endDate)!
        
        let history = try await client.history.fetch(ticker: ticker, from: startDate, to: endDate)
        
        #expect(history.prices.count > 0)
        #expect(history.ticker.symbol == "GOOGL")
        #expect(history.startDate <= history.endDate)
        
        // 시작일과 종료일이 요청한 범위와 유사한지 확인
        let startDiff = abs(history.startDate.timeIntervalSince(startDate))
        let endDiff = abs(history.endDate.timeIntervalSince(endDate))
        #expect(startDiff < 86400 * 7) // 1주일 이내 오차 허용
        #expect(endDiff < 86400 * 7) // 1주일 이내 오차 허용
    }
    
    @Test
    func testFetchPriceHistoryInvalidSymbol() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "INVALID_SYMBOL_XYZ")
        
        // 실제 API는 invalid symbol에 대해 다양한 응답을 할 수 있음
        // 에러를 던지거나, 빈 결과를 반환할 수 있음
        do {
            let history = try await client.history.fetch(ticker: ticker, period: .oneDay)
            // 빈 결과가 반환된 경우
            #expect(history.prices.isEmpty)
        } catch {
            // 에러가 발생한 경우
            #expect(error is YFError)
        }
    }
    
    @Test
    func testFetchPriceHistoryEmptyResult() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        // 미래 날짜로 설정하여 빈 결과를 유도
        let futureDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        let moreFutureDate = Calendar.current.date(byAdding: .day, value: 1, to: futureDate)!
        
        // 실제 API는 미래 날짜에 대해 에러를 던지거나 빈 결과를 반환할 수 있음
        do {
            let history = try await client.history.fetch(ticker: ticker, from: futureDate, to: moreFutureDate)
            // 빈 결과가 반환된 경우
            #expect(history.prices.isEmpty)
        } catch {
            // 에러가 발생한 경우 (더 일반적)
            #expect(error is YFError)
        }
    }
    
}