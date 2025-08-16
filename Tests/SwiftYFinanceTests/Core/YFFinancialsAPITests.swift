import Testing
@testable import SwiftYFinance

struct YFFinancialsAPITests {
    
    @Test("YFFinancialsAPI file exists")
    func testYFFinancialsAPIFileExists() async {
        // TDD Red: YFFinancialsAPI.swift 파일이 존재하고 financial 메서드들이 분리되어 있는지 테스트
        let client = YFClient()
        
        // INVALID 심볼로 에러 케이스 테스트 (실제 네트워크 호출 없이 구조 확인)
        let invalidTicker = YFTicker(symbol: "INVALID")
        
        // fetchFinancials 테스트
        do {
            _ = try await client.fetchFinancials(ticker: invalidTicker)
            Issue.record("Should have thrown API error")
        } catch YFError.apiError(_) {
            #expect(Bool(true)) // fetchFinancials method works from YFFinancialsAPI extension
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
        
        // fetchBalanceSheet 테스트
        do {
            _ = try await client.fetchBalanceSheet(ticker: invalidTicker)
            Issue.record("Should have thrown API error")
        } catch YFError.apiError(_) {
            #expect(Bool(true)) // fetchBalanceSheet method works from YFFinancialsAPI extension
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
        
        // fetchCashFlow 테스트
        do {
            _ = try await client.fetchCashFlow(ticker: invalidTicker)
            Issue.record("Should have thrown API error")
        } catch YFError.apiError(_) {
            #expect(Bool(true)) // fetchCashFlow method works from YFFinancialsAPI extension
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
        
        // fetchEarnings 테스트
        do {
            _ = try await client.fetchEarnings(ticker: invalidTicker)
            Issue.record("Should have thrown API error")
        } catch YFError.apiError(_) {
            #expect(Bool(true)) // fetchEarnings method works from YFFinancialsAPI extension
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}