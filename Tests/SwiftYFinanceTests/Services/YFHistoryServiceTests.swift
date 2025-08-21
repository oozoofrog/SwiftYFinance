import Testing
@testable import SwiftYFinance
import Foundation

struct YFHistoryServiceTests {
    
    @Test("YFHistoryService Protocol + Struct architecture")
    func testYFHistoryServiceArchitecture() async {
        // TDD Red: YFHistoryService struct가 존재하고 서비스 기반 호출이 작동하는지 테스트
        let client = YFClient()
        
        // 무효한 심볼로 에러 케이스 테스트 (실제 네트워크 호출 없이 구조 확인)
        let invalidTicker = YFTicker(symbol: "INVALID_XYZ")
        
        // OOP & Protocol + Struct: 서비스 기반 호출 테스트
        do {
            let history = try await client.history.fetch(ticker: invalidTicker, period: .oneDay)
            // 빈 결과가 반환되어야 함
            #expect(history.prices.isEmpty, "Invalid ticker should return empty prices")
            #expect(history.ticker.symbol == "INVALID_XYZ", "Ticker should be preserved")
        } catch {
            // 에러가 발생해도 정상적인 동작
            #expect(error is YFError, "Should throw YFError for invalid symbols")
        }
    }
    
    @Test("YFHistoryService AAPL 1 day period data validation")
    func testAAPL1DayHistory() async throws {
        // Real API test with AAPL - 1일 기간 데이터 검증
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        let history = try await client.history.fetch(ticker: ticker, period: .oneDay)
        
        // 기본 구조 검증
        #expect(history.ticker.symbol == "AAPL", "Ticker should match request")
        #expect(history.startDate <= history.endDate, "Start date should be before end date")
        
        // 1일 기간에는 최소한의 데이터가 있어야 함
        if !history.prices.isEmpty {
            let firstPrice = history.prices.first!
            #expect(firstPrice.open > 0, "Open price should be positive")
            #expect(firstPrice.high >= firstPrice.low, "High should be >= low")
            #expect(firstPrice.volume >= 0, "Volume should be non-negative")
        }
    }
    
    @Test("YFHistoryService MSFT 1 week period data validation")
    func testMSFT1WeekHistory() async throws {
        // Real API test with MSFT - 1주 기간 데이터 검증
        let client = YFClient()
        let ticker = YFTicker(symbol: "MSFT")
        
        let history = try await client.history.fetch(ticker: ticker, period: .oneWeek)
        
        // 기본 구조 검증
        #expect(history.ticker.symbol == "MSFT", "Ticker should match request")
        #expect(history.startDate <= history.endDate, "Start date should be before end date")
        
        // 1주일 기간에는 여러 일의 데이터가 있을 가능성
        if history.prices.count > 1 {
            let prices = history.prices.sorted { $0.date < $1.date }
            for i in 0..<prices.count-1 {
                #expect(prices[i].date <= prices[i+1].date, "Prices should be chronologically ordered")
            }
        }
        
        // 기간 검증 (대략적)
        let expectedStartDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
        let timeDifference = abs(history.startDate.timeIntervalSince(expectedStartDate))
        #expect(timeDifference < 86400 * 2, "Start date should be approximately 1 week ago")
    }
    
    @Test("YFHistoryService custom date range validation")
    func testCustomDateRangeHistory() async throws {
        // Custom date range test with GOOGL - 3개월 범위 검증
        let client = YFClient()
        let ticker = YFTicker(symbol: "GOOGL")
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -3, to: endDate)!
        
        let history = try await client.history.fetch(ticker: ticker, from: startDate, to: endDate)
        
        // 기본 구조 검증
        #expect(history.ticker.symbol == "GOOGL", "Ticker should match request")
        #expect(history.startDate <= history.endDate, "Start date should be before end date")
        
        // 날짜 범위 검증 (어느 정도 오차 허용)
        let startDiff = abs(history.startDate.timeIntervalSince(startDate))
        let endDiff = abs(history.endDate.timeIntervalSince(endDate))
        #expect(startDiff < 86400 * 7, "Start date should be within 1 week of requested")
        #expect(endDiff < 86400 * 7, "End date should be within 1 week of requested")
        
        // 3개월 기간에는 상당한 데이터가 있을 것으로 예상
        if !history.prices.isEmpty {
            #expect(history.prices.count >= 10, "3 months should have at least 10 trading days")
        }
    }
    
    @Test("YFHistoryService multi-ticker concurrency test")
    func testMultipleTickersConcurrently() async throws {
        // 동시성 테스트: 여러 종목을 동시에 조회
        let client = YFClient()
        let tickers = [
            YFTicker(symbol: "AAPL"),
            YFTicker(symbol: "MSFT"),
            YFTicker(symbol: "GOOGL")
        ]
        
        // 병렬 처리
        let results = await withTaskGroup(of: (String, Result<YFHistoricalData, Error>).self) { group in
            for ticker in tickers {
                group.addTask {
                    do {
                        let history = try await client.history.fetch(ticker: ticker, period: .oneWeek)
                        return (ticker.symbol, .success(history))
                    } catch {
                        return (ticker.symbol, .failure(error))
                    }
                }
            }
            
            var collectedResults: [String: Result<YFHistoricalData, Error>] = [:]
            for await (symbol, result) in group {
                collectedResults[symbol] = result
            }
            return collectedResults
        }
        
        // 결과 검증
        #expect(results.count == 3, "Should have results for all 3 tickers")
        
        for (symbol, result) in results {
            switch result {
            case .success(let history):
                #expect(history.ticker.symbol == symbol, "Ticker should match for \(symbol)")
                #expect(history.startDate <= history.endDate, "Valid date range for \(symbol)")
            case .failure(let error):
                // 네트워크 에러 등은 허용하지만 기록
                print("⚠️ Failed to fetch \(symbol): \(error)")
            }
        }
    }
    
    @Test("YFHistoryService error handling with invalid symbols")
    func testErrorHandlingInvalidSymbols() async {
        let client = YFClient()
        
        let invalidTickers = [
            YFTicker(symbol: "NONEXISTENT123"),
            YFTicker(symbol: ""),
            YFTicker(symbol: "INVALID_SYMBOL_XYZ")
        ]
        
        for ticker in invalidTickers {
            do {
                let history = try await client.history.fetch(ticker: ticker, period: .oneDay)
                // 빈 결과가 반환되는 경우
                #expect(history.prices.isEmpty, "Invalid ticker \(ticker.symbol) should return empty data")
            } catch {
                // 에러가 발생하는 경우도 정상
                #expect(error is YFError, "Should throw YFError for invalid ticker \(ticker.symbol)")
            }
        }
    }
    
    @Test("YFHistoryService performance test")
    func testHistoryServicePerformance() async throws {
        // 성능 테스트: 단일 API 호출이 합리적인 시간 내에 완료되는지 확인
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        let startTime = Date()
        let history = try await client.history.fetch(ticker: ticker, period: .oneMonth)
        let endTime = Date()
        
        let duration = endTime.timeIntervalSince(startTime)
        
        // API 호출이 합리적인 시간 내에 완료되어야 함 (15초 이내)
        #expect(duration < 15.0, "History API call should complete within 15 seconds")
        
        // 응답에 데이터가 있어야 함
        #expect(history.ticker.symbol == "AAPL", "Should return data for requested ticker")
    }
    
    @Test("YFHistoryService Sendable compliance")
    func testSendableCompliance() async {
        // Sendable 준수 테스트: 여러 Task에서 동시에 사용 가능한지 확인
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        let task1 = Task {
            try await client.history.fetch(ticker: ticker, period: .oneWeek)
        }
        
        let task2 = Task {
            try await client.history.fetch(ticker: ticker, period: .oneMonth)
        }
        
        do {
            let (result1, result2) = try await (task1.value, task2.value)
            
            // 두 결과 모두 올바른 ticker를 가져야 함
            #expect(result1.ticker.symbol == "AAPL", "Task 1 should have correct ticker")
            #expect(result2.ticker.symbol == "AAPL", "Task 2 should have correct ticker")
            
            // 두 결과의 기간이 달라야 함 (서로 다른 요청)
            let duration1 = result1.endDate.timeIntervalSince(result1.startDate)
            let duration2 = result2.endDate.timeIntervalSince(result2.startDate)
            #expect(abs(duration1 - duration2) > 86400, "Different periods should have different durations")
            
        } catch {
            // 동시 접근으로 인한 실패는 없어야 함
            Issue.record("Concurrent access should not fail: \(error)")
        }
    }
}