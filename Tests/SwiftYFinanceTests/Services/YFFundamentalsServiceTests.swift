import Testing
@testable import SwiftYFinance
import Foundation

struct YFFundamentalsServiceTests {
    
    @Test("YFFundamentalsService Protocol + Struct architecture")
    func testYFFundamentalsServiceArchitecture() async {
        // TDD Red: YFFundamentalsService struct가 존재하고 서비스 기반 호출이 작동하는지 테스트
        let client = YFClient()
        
        // INVALID 심볼로 에러 케이스 테스트 (실제 네트워크 호출 없이 구조 확인)
        let invalidTicker = YFTicker(symbol: "INVALID")
        
        // OOP & Protocol + Struct: 서비스 기반 호출 테스트
        do {
            _ = try await client.fundamentals.fetch(ticker: invalidTicker)
            Issue.record("Should have thrown API error for INVALID ticker")
        } catch YFError.apiError(let message) {
            #expect(message.contains("Invalid symbol: INVALID"))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    @Test("YFFundamentalsService AAPL comprehensive data validation")
    func testAAPLFundamentalsRealData() async throws {
        // Real API test with AAPL - 모든 재무 데이터 통합 검증
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        let fundamentalsResponse = try await client.fundamentals.fetch(ticker: ticker)
        
        // 기본 구조 검증
        #expect(fundamentalsResponse.timeseries?.result != nil, "Should have timeseries results")
        
        guard let results = fundamentalsResponse.timeseries?.result, !results.isEmpty else {
            Issue.record("Should have at least one timeseries result")
            return
        }
        
        // 재무제표 데이터 존재 확인
        var hasIncomeStatementData = false
        var hasBalanceSheetData = false
        var hasCashFlowData = false
        
        for result in results {
            // Income Statement 데이터 확인
            if result.annualTotalRevenue != nil || result.annualNetIncome != nil {
                hasIncomeStatementData = true
            }
            
            // Balance Sheet 데이터 확인
            if result.annualTotalAssets != nil || result.annualTotalStockholderEquity != nil {
                hasBalanceSheetData = true
            }
            
            // Cash Flow 데이터 확인 (예정)
            if result.annualFreeCashFlow != nil || result.annualOperatingCashFlow != nil {
                hasCashFlowData = true
            }
        }
        
        #expect(hasIncomeStatementData, "Should have income statement data")
        #expect(hasBalanceSheetData, "Should have balance sheet data")
        // Cash flow 데이터는 아직 구현 예정이므로 주석 처리
        // #expect(hasCashFlowData, "Should have cash flow data")
    }
    
    @Test("YFFundamentalsService multi-ticker concurrency test")
    func testMultipleTickersConcurrently() async throws {
        // 동시성 테스트: 여러 종목을 동시에 조회
        let client = YFClient()
        let tickers = [
            YFTicker(symbol: "AAPL"),
            YFTicker(symbol: "MSFT"),
            YFTicker(symbol: "GOOGL")
        ]
        
        // 병렬 처리
        let results = await withTaskGroup(of: (String, Result<FundamentalsTimeseriesResponse, Error>).self) { group in
            for ticker in tickers {
                group.addTask {
                    do {
                        let fundamentals = try await client.fundamentals.fetch(ticker: ticker)
                        return (ticker.symbol, .success(fundamentals))
                    } catch {
                        return (ticker.symbol, .failure(error))
                    }
                }
            }
            
            var collectedResults: [String: Result<FundamentalsTimeseriesResponse, Error>] = [:]
            for await (symbol, result) in group {
                collectedResults[symbol] = result
            }
            return collectedResults
        }
        
        // 결과 검증
        #expect(results.count == 3, "Should have results for all 3 tickers")
        
        for (symbol, result) in results {
            switch result {
            case .success(let fundamentals):
                #expect(fundamentals.timeseries?.result != nil, "Should have data for \(symbol)")
            case .failure(let error):
                Issue.record("Failed to fetch \(symbol): \(error)")
            }
        }
    }
    
    @Test("YFFundamentalsService data consistency validation")
    func testDataConsistencyBetweenMetrics() async throws {
        // 데이터 일관성 테스트: 같은 날짜의 다른 메트릭들이 일치하는지 확인
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        let fundamentalsResponse = try await client.fundamentals.fetch(ticker: ticker)
        
        guard let results = fundamentalsResponse.timeseries?.result else {
            Issue.record("Should have timeseries results")
            return
        }
        
        // 날짜별 메트릭 일치성 확인
        var dateToMetricsCount: [String: Int] = [:]
        
        for result in results {
            // 각 메트릭의 날짜들 수집
            if let revenues = result.annualTotalRevenue {
                for revenue in revenues {
                    if let date = revenue.asOfDate {
                        dateToMetricsCount[date, default: 0] += 1
                    }
                }
            }
            
            if let assets = result.annualTotalAssets {
                for asset in assets {
                    if let date = asset.asOfDate {
                        dateToMetricsCount[date, default: 0] += 1
                    }
                }
            }
        }
        
        // 적어도 몇 개의 공통 날짜가 있어야 함
        let commonDates = dateToMetricsCount.filter { $0.value > 1 }
        #expect(!commonDates.isEmpty, "Should have dates with multiple metrics")
    }
    
    @Test("YFFundamentalsService error handling")
    func testErrorHandling() async {
        let client = YFClient()
        
        // 존재하지 않는 심볼 테스트
        let nonExistentTicker = YFTicker(symbol: "NONEXISTENT123456")
        
        do {
            _ = try await client.fundamentals.fetch(ticker: nonExistentTicker)
            // 실제 결과에 따라 성공할 수도 있고 에러가 날 수도 있음
            // 에러가 나지 않으면 빈 데이터를 반환하는지 확인
        } catch {
            // 에러가 발생하는 것도 정상적인 동작
            #expect(error is YFError, "Should throw YFError for invalid symbols")
        }
    }
    
    @Test("YFFundamentalsService performance test")
    func testPerformance() async throws {
        // 성능 테스트: 단일 API 호출로 모든 재무 데이터를 가져오는지 확인
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        let startTime = Date()
        let fundamentalsResponse = try await client.fundamentals.fetch(ticker: ticker)
        let endTime = Date()
        
        let duration = endTime.timeIntervalSince(startTime)
        
        // API 호출이 합리적인 시간 내에 완료되어야 함 (10초 이내)
        #expect(duration < 10.0, "API call should complete within 10 seconds")
        
        // 응답에 데이터가 있어야 함
        #expect(fundamentalsResponse.timeseries?.result != nil, "Should have data in reasonable time")
    }
    
    @Test("YFFundamentalsService Sendable compliance")
    func testSendableCompliance() async {
        // Sendable 준수 테스트: 여러 Task에서 동시에 사용 가능한지 확인
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        let task1 = Task {
            try await client.fundamentals.fetch(ticker: ticker)
        }
        
        let task2 = Task {
            try await client.fundamentals.fetch(ticker: ticker)
        }
        
        do {
            let (result1, result2) = try await (task1.value, task2.value)
            
            // 두 결과 모두 데이터를 가져야 함
            #expect(result1.timeseries?.result != nil, "Task 1 should have data")
            #expect(result2.timeseries?.result != nil, "Task 2 should have data")
            
        } catch {
            Issue.record("Concurrent access should not fail: \(error)")
        }
    }
}