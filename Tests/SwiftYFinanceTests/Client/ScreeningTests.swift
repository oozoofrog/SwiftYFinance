import Testing
import Foundation
@testable import SwiftYFinance

struct ScreeningTests {
    @Test
    func testBasicScreening() async throws {
        let client = YFClient()
        
        // 기본 스크리닝 - 시가총액 20억 이상, 미국 주식
        let screener = YFScreener.equity()
            .marketCap(min: 2_000_000_000)
            .region(.us)
            .minPrice(5.0)
        
        let results = try await client.screen(screener)
        
        #expect(results.count > 0)
        #expect(results.count <= 100) // 기본 제한
        
        // 결과 검증
        for result in results.prefix(5) {
            #expect(!result.ticker.symbol.isEmpty)
            #expect(result.marketCap >= 2_000_000_000)
            #expect(result.price >= 5.0)
            #expect(result.region == "US")
        }
    }
    
    @Test
    func testScreeningWithSorting() async throws {
        let client = YFClient()
        
        // 시가총액 기준 내림차순 정렬
        let screener = YFScreener.equity()
            .marketCap(min: 10_000_000_000) // 100억 이상
            .sortBy(.marketCap, ascending: false)
            .limit(10)
        
        let results = try await client.screen(screener)
        
        #expect(results.count > 0)
        #expect(results.count <= 10)
        
        // 시가총액 내림차순 정렬 검증
        if results.count >= 2 {
            for i in 0..<(results.count - 1) {
                #expect(results[i].marketCap >= results[i + 1].marketCap)
            }
        }
    }
    
    @Test
    func testSectorFiltering() async throws {
        let client = YFClient()
        
        // 기술주 필터링
        let screener = YFScreener.equity()
            .sector(.technology)
            .marketCap(min: 1_000_000_000)
            .limit(15)
        
        let results = try await client.screen(screener)
        
        #expect(results.count > 0)
        #expect(results.count <= 15)
        
        // 섹터 검증
        for result in results {
            #expect(result.sector == "Technology")
            #expect(result.marketCap >= 1_000_000_000)
        }
    }
    
    @Test
    func testFinancialRatiosFiltering() async throws {
        let client = YFClient()
        
        // P/E 비율과 수익성 필터링
        let screener = YFScreener.equity()
            .peRatio(min: 5, max: 25)
            .returnOnEquity(min: 0.15) // 15% 이상
            .region(.us)
            .limit(20)
        
        let results = try await client.screen(screener)
        
        #expect(results.count > 0)
        #expect(results.count <= 20)
        
        // 재무 비율 검증
        for result in results {
            if let pe = result.peRatio {
                #expect(pe >= 5 && pe <= 25)
            }
            if let roe = result.returnOnEquity {
                #expect(roe >= 0.15)
            }
        }
    }
    
    @Test
    func testPredefinedScreeners() async throws {
        let client = YFClient()
        
        // 사전 정의된 스크리너 - Day Gainers
        let results = try await client.screenPredefined(.dayGainers, limit: 25)
        
        #expect(results.count > 0)
        #expect(results.count <= 25)
        
        // Day Gainers 특성 검증
        for result in results {
            #expect(result.percentChange > 3.0) // 3% 이상 상승
            #expect(result.price >= 5.0)
            #expect(result.dayVolume > 15000)
        }
    }
    
    @Test
    func testComplexQuery() async throws {
        let client = YFClient()
        
        // 복합 조건 - 성장주 + 저평가
        let screener = YFScreener.equity()
            .marketCap(min: 5_000_000_000) // 50억 이상
            .revenueGrowth(min: 0.10) // 10% 이상 매출 성장
            .peRatio(max: 30) // P/E 30 이하
            .debtToEquity(max: 0.5) // 부채비율 50% 이하
            .sector(.technology)
            .sortBy(.revenueGrowth, ascending: false)
            .limit(10)
        
        let results = try await client.screen(screener)
        
        #expect(results.count >= 0) // 복합 조건이므로 결과가 없을 수도 있음
        
        // 조건 만족 검증
        for result in results {
            #expect(result.marketCap >= 5_000_000_000)
            #expect(result.sector == "Technology")
            if let revenueGrowth = result.revenueGrowth {
                #expect(revenueGrowth >= 0.10)
            }
            if let pe = result.peRatio {
                #expect(pe <= 30)
            }
            if let debtRatio = result.debtToEquity {
                #expect(debtRatio <= 0.5)
            }
        }
    }
    
    @Test
    func testScreeningPagination() async throws {
        let client = YFClient()
        
        // 페이지네이션 테스트
        let screener = YFScreener.equity()
            .marketCap(min: 1_000_000_000)
            .offset(0)
            .limit(10)
        
        let firstPage = try await client.screen(screener)
        
        let secondPageScreener = YFScreener.equity()
            .marketCap(min: 1_000_000_000)
            .offset(10)
            .limit(10)
        
        let secondPage = try await client.screen(secondPageScreener)
        
        #expect(firstPage.count > 0)
        #expect(secondPage.count >= 0) // 두 번째 페이지는 없을 수도 있음
        
        // 중복 없음 검증 (첫 번째 페이지와 두 번째 페이지)
        if !secondPage.isEmpty {
            let firstPageSymbols = Set(firstPage.map { $0.ticker.symbol })
            let secondPageSymbols = Set(secondPage.map { $0.ticker.symbol })
            let intersection = firstPageSymbols.intersection(secondPageSymbols)
            #expect(intersection.isEmpty)
        }
    }
    
    @Test
    func testInvalidScreenerError() async throws {
        let client = YFClient()
        
        // 잘못된 조건 - 불가능한 조건 조합
        let screener = YFScreener.equity()
            .marketCap(min: 1_000_000_000_000) // 1조 이상 (현실적으로 매우 적음)
            .peRatio(min: -10, max: 0) // 음수 P/E (불가능)
        
        do {
            let results = try await client.screen(screener)
            // 결과가 없어도 에러는 아님
            #expect(results.count == 0)
        } catch {
            // 또는 적절한 에러 처리
            #expect(error is YFError)
        }
    }
}