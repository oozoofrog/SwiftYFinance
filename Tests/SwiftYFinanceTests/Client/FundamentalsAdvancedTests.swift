import Testing
import Foundation
@testable import SwiftYFinance

struct FundamentalsAdvancedTests {
    @Test
    func testFetchQuarterlyFinancials() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        // 분기별 재무제표 조회
        let quarterlyFinancials = try await client.fetchQuarterlyFinancials(ticker: ticker)
        
        #expect(quarterlyFinancials.ticker.symbol == "AAPL")
        #expect(quarterlyFinancials.quarterlyReports.count > 0)
        
        // 최근 분기 데이터 확인
        let latestQuarter = quarterlyFinancials.quarterlyReports.first!
        #expect(latestQuarter.totalRevenue > 0)
        #expect(latestQuarter.netIncome != 0) // 손실 가능
        #expect(latestQuarter.quarter.contains("Q")) // Q1, Q2, Q3, Q4
        
        // 분기 순서 확인 (최신순)
        if quarterlyFinancials.quarterlyReports.count >= 2 {
            let firstQuarter = quarterlyFinancials.quarterlyReports[0]
            let secondQuarter = quarterlyFinancials.quarterlyReports[1]
            #expect(firstQuarter.reportDate > secondQuarter.reportDate)
        }
    }
    
    @Test
    func testFinancialRatios() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "MSFT")
        
        // 재무 비율 계산
        let ratios = try await client.calculateFinancialRatios(ticker: ticker)
        
        #expect(ratios.ticker.symbol == "MSFT")
        
        // P/E 비율 확인
        #expect(ratios.priceToEarnings > 0)
        #expect(ratios.priceToEarnings < 100) // 합리적 범위
        
        // P/B 비율 확인
        #expect(ratios.priceToBook > 0)
        
        // ROE, ROA 확인
        #expect(ratios.returnOnEquity > 0)
        #expect(ratios.returnOnEquity < 1) // 100% 미만
        #expect(ratios.returnOnAssets > 0)
        #expect(ratios.returnOnAssets < ratios.returnOnEquity) // ROA < ROE
        
        // 부채 비율 확인
        #expect(ratios.debtToEquityRatio >= 0)
        #expect(ratios.currentRatio > 0)
        
        // 마진 비율 확인
        #expect(ratios.grossMargin > 0)
        #expect(ratios.grossMargin < 1) // 100% 미만
        #expect(ratios.operatingMargin >= 0)
        #expect(ratios.netMargin >= 0)
    }
    
    @Test
    func testGrowthMetrics() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "GOOGL")
        
        // 성장 지표 계산
        let growth = try await client.calculateGrowthMetrics(ticker: ticker)
        
        #expect(growth.ticker.symbol == "GOOGL")
        
        // YoY 성장률 확인
        #expect(growth.revenueGrowthYoY != 0) // 양수/음수 모두 가능
        #expect(growth.netIncomeGrowthYoY != 0)
        #expect(growth.epsGrowthYoY != 0)
        
        // QoQ 성장률 확인 (분기별)
        #expect(growth.revenueGrowthQoQ != 0)
        #expect(growth.netIncomeGrowthQoQ != 0)
        
        // 성장률 합리성 검증 (-100% ~ 500% 범위)
        #expect(growth.revenueGrowthYoY > -1.0)
        #expect(growth.revenueGrowthYoY < 5.0)
        
        // 평균 성장률 (3년, 5년)
        if let avgGrowth3Y = growth.avgRevenueGrowth3Y {
            #expect(avgGrowth3Y > -1.0 && avgGrowth3Y < 5.0)
        }
        
        if let avgGrowth5Y = growth.avgRevenueGrowth5Y {
            #expect(avgGrowth5Y > -1.0 && avgGrowth5Y < 5.0)
        }
    }
    
    @Test
    func testFinancialHealthMetrics() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        // 재무 건전성 지표
        let health = try await client.assessFinancialHealth(ticker: ticker)
        
        #expect(health.ticker.symbol == "AAPL")
        
        // 유동성 지표
        #expect(health.currentRatio > 0)
        #expect(health.quickRatio >= 0)
        #expect(health.quickRatio <= health.currentRatio) // Quick <= Current
        
        // 부채 관련 지표
        #expect(health.debtToEquityRatio >= 0)
        #expect(health.interestCoverageRatio > 0)
        
        // 효율성 지표
        #expect(health.assetTurnover > 0)
        #expect(health.inventoryTurnover >= 0)
        
        // 수익성 지표
        #expect(health.returnOnEquity > 0)
        #expect(health.returnOnAssets > 0)
        #expect(health.returnOnInvestedCapital > 0)
        
        // 전체 건전성 점수 (1-10)
        #expect(health.overallHealthScore >= 1)
        #expect(health.overallHealthScore <= 10)
        
        // 신용등급 (AAA, AA, A, BBB, BB, B, CCC, CC, C, D)
        let validRatings = ["AAA", "AA", "A", "BBB", "BB", "B", "CCC", "CC", "C", "D"]
        #expect(validRatings.contains(health.creditRating))
    }
    
    @Test
    func testIndustryComparison() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "AAPL")
        
        // 산업 평균 대비 비교
        let comparison = try await client.compareToIndustry(ticker: ticker)
        
        #expect(comparison.ticker.symbol == "AAPL")
        #expect(!comparison.industry.isEmpty)
        #expect(!comparison.sector.isEmpty)
        
        // 비교 지표들
        #expect(comparison.peRatioVsIndustry != 0) // +/- 차이
        #expect(comparison.roaVsIndustry != 0)
        #expect(comparison.roeVsIndustry != 0)
        #expect(comparison.profitMarginVsIndustry != 0)
        
        // 순위 (1-100 백분위)
        #expect(comparison.industryRankPercentile >= 0)
        #expect(comparison.industryRankPercentile <= 100)
        
        // 베타 비교
        #expect(comparison.betaVsMarket > 0)
        
        // 밸류에이션 비교 (-100% ~ +500%)
        #expect(comparison.valuationVsIndustry > -1.0)
        #expect(comparison.valuationVsIndustry < 5.0)
    }
    
    @Test
    func testAdvancedFinancialsInvalidSymbol() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "INVALID")
        
        // 잘못된 심볼에 대한 에러 처리
        do {
            _ = try await client.fetchQuarterlyFinancials(ticker: ticker)
            Issue.record("Should throw error for invalid symbol")
        } catch {
            #expect(error is YFError)
        }
    }
    
    @Test
    func testFinancialDataConsistency() async throws {
        let client = YFClient()
        let ticker = YFTicker(symbol: "MSFT")
        
        // 연간 vs 분기별 데이터 일관성 확인
        let annualFinancials = try await client.fetchFinancials(ticker: ticker)
        let quarterlyFinancials = try await client.fetchQuarterlyFinancials(ticker: ticker)
        
        // 최근 4분기 합계가 연간 데이터와 유사한지 확인
        if quarterlyFinancials.quarterlyReports.count >= 4 {
            let last4Quarters = quarterlyFinancials.quarterlyReports.prefix(4)
            let quarterlyRevenueSum = last4Quarters.reduce(0) { $0 + $1.totalRevenue }
            let annualRevenue = annualFinancials.annualReports.first!.totalRevenue
            
            // 10% 오차 허용
            let difference = abs(quarterlyRevenueSum - annualRevenue) / annualRevenue
            #expect(difference < 0.1) // 10% 미만 차이
        }
    }
}