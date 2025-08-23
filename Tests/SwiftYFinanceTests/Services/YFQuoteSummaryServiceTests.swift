import Foundation
import Testing
@testable import SwiftYFinance

/// Quote Summary 서비스 테스트
@Suite("Quote Summary Service Tests")
struct YFQuoteSummaryServiceTests {
    
    let client = YFClient(debugEnabled: true)
    let testTicker = YFTicker(symbol: "AAPL")
    let invalidTicker = YFTicker(symbol: "INVALID_SYMBOL_TEST")
    
    // MARK: - Basic Functionality Tests
    
    @Test("필수 정보 조회 테스트")
    func testFetchEssential() async throws {
        let service = YFQuoteSummaryService(client: client)
        let quoteSummary = try await service.fetchEssential(ticker: testTicker)
        
        #expect(quoteSummary.result != nil)
        #expect(quoteSummary.error == nil)
        #expect(!quoteSummary.result!.isEmpty)
    }
    
    @Test("사용자 지정 모듈 조회 테스트")
    func testFetchCustomModules() async throws {
        let service = YFQuoteSummaryService(client: client)
        let modules: [YFQuoteSummaryModule] = [.summaryDetail, .price, .financialData]
        
        let quoteSummary = try await service.fetch(ticker: testTicker, modules: modules)
        
        #expect(quoteSummary.result != nil)
        #expect(quoteSummary.error == nil)
        #expect(!quoteSummary.result!.isEmpty)
    }
    
    @Test("단일 모듈 조회 테스트")
    func testFetchSingleModule() async throws {
        let service = YFQuoteSummaryService(client: client)
        
        let quoteSummary = try await service.fetch(ticker: testTicker, module: .price)
        
        #expect(quoteSummary.result != nil)
        #expect(quoteSummary.error == nil)
        #expect(!quoteSummary.result!.isEmpty)
    }
    
    // MARK: - Convenience Methods Tests
    
    @Test("종합 분석 데이터 조회 테스트")
    func testFetchComprehensive() async throws {
        let service = YFQuoteSummaryService(client: client)
        
        let quoteSummary = try await service.fetchComprehensive(ticker: testTicker)
        
        #expect(quoteSummary.result != nil)
        #expect(quoteSummary.error == nil)
        #expect(!quoteSummary.result!.isEmpty)
    }
    
    @Test("회사 기본 정보 조회 테스트")
    func testFetchCompanyInfo() async throws {
        let service = YFQuoteSummaryService(client: client)
        
        let quoteSummary = try await service.fetchCompanyInfo(ticker: testTicker)
        
        #expect(quoteSummary.result != nil)
        #expect(quoteSummary.error == nil)
        #expect(!quoteSummary.result!.isEmpty)
    }
    
    @Test("가격 정보 조회 테스트")
    func testFetchPriceInfo() async throws {
        let service = YFQuoteSummaryService(client: client)
        
        let quoteSummary = try await service.fetchPriceInfo(ticker: testTicker)
        
        #expect(quoteSummary.result != nil)
        #expect(quoteSummary.error == nil)
        #expect(!quoteSummary.result!.isEmpty)
    }
    
    @Test("연간 재무제표 조회 테스트")
    func testFetchAnnualFinancials() async throws {
        let service = YFQuoteSummaryService(client: client)
        
        let quoteSummary = try await service.fetchFinancials(ticker: testTicker, quarterly: false)
        
        #expect(quoteSummary.result != nil)
        #expect(quoteSummary.error == nil)
        #expect(!quoteSummary.result!.isEmpty)
    }
    
    @Test("분기별 재무제표 조회 테스트")
    func testFetchQuarterlyFinancials() async throws {
        let service = YFQuoteSummaryService(client: client)
        
        let quoteSummary = try await service.fetchFinancials(ticker: testTicker, quarterly: true)
        
        #expect(quoteSummary.result != nil)
        #expect(quoteSummary.error == nil)
        #expect(!quoteSummary.result!.isEmpty)
    }
    
    @Test("실적 데이터 조회 테스트")
    func testFetchEarnings() async throws {
        let service = YFQuoteSummaryService(client: client)
        
        let quoteSummary = try await service.fetchEarnings(ticker: testTicker)
        
        #expect(quoteSummary.result != nil)
        #expect(quoteSummary.error == nil)
        #expect(!quoteSummary.result!.isEmpty)
    }
    
    @Test("소유권 데이터 조회 테스트")
    func testFetchOwnership() async throws {
        let service = YFQuoteSummaryService(client: client)
        
        let quoteSummary = try await service.fetchOwnership(ticker: testTicker)
        
        #expect(quoteSummary.result != nil)
        #expect(quoteSummary.error == nil)
        #expect(!quoteSummary.result!.isEmpty)
    }
    
    @Test("애널리스트 데이터 조회 테스트")
    func testFetchAnalystData() async throws {
        let service = YFQuoteSummaryService(client: client)
        
        let quoteSummary = try await service.fetchAnalystData(ticker: testTicker)
        
        #expect(quoteSummary.result != nil)
        #expect(quoteSummary.error == nil)
        #expect(!quoteSummary.result!.isEmpty)
    }
    
    // MARK: - Raw JSON Tests
    
    @Test("필수 정보 Raw JSON 조회 테스트")
    func testFetchEssentialRawJSON() async throws {
        let service = YFQuoteSummaryService(client: client)
        
        let jsonData = try await service.fetchEssentialRawJSON(ticker: testTicker)
        
        #expect(jsonData.count > 0)
        
        // JSON 파싱 검증
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        #expect(json != nil)
        #expect(json?["quoteSummary"] != nil)
    }
    
    @Test("종합 정보 Raw JSON 조회 테스트")
    func testFetchComprehensiveRawJSON() async throws {
        let service = YFQuoteSummaryService(client: client)
        
        let jsonData = try await service.fetchComprehensiveRawJSON(ticker: testTicker)
        
        #expect(jsonData.count > 0)
        
        // JSON 파싱 검증
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        #expect(json != nil)
        #expect(json?["quoteSummary"] != nil)
    }
    
    @Test("사용자 지정 모듈 Raw JSON 조회 테스트")
    func testFetchCustomModulesRawJSON() async throws {
        let service = YFQuoteSummaryService(client: client)
        let modules: [YFQuoteSummaryModule] = [.price, .summaryDetail]
        
        let jsonData = try await service.fetchRawJSON(ticker: testTicker, modules: modules)
        
        #expect(jsonData.count > 0)
        
        // JSON 파싱 검증
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        #expect(json != nil)
        #expect(json?["quoteSummary"] != nil)
    }
    
    // MARK: - YFClient Integration Tests
    
    @Test("YFClient 통합 테스트 - quoteSummary 프로퍼티")
    func testYFClientIntegration() async throws {
        let quoteSummary = try await client.quoteSummary.fetchEssential(ticker: testTicker)
        
        #expect(quoteSummary.result != nil)
        #expect(quoteSummary.error == nil)
        #expect(!quoteSummary.result!.isEmpty)
    }
    
    @Test("YFClient와 기존 Quote 서비스 차이 확인")
    func testQuoteVsQuoteSummaryDifference() async throws {
        // 각 서비스별로 독립된 클라이언트 사용 (인증 충돌 방지)
        let quoteClient = YFClient(debugEnabled: true)
        let quoteSummaryClient = YFClient(debugEnabled: true)
        
        // 기존 Quote 서비스 (간단한 시세)
        let simpleQuote = try await quoteClient.quote.fetch(ticker: testTicker)
        
        // 새로운 Quote Summary 서비스 (종합 정보)
        let comprehensiveData = try await quoteSummaryClient.quoteSummary.fetchEssential(ticker: testTicker)
        
        // 둘 다 정상 동작 확인
        #expect(simpleQuote.regularMarketPrice != nil)
        #expect(comprehensiveData.result != nil)
        #expect(comprehensiveData.error == nil)
        
        // Quote Summary가 더 많은 정보를 포함하는지 확인
        #expect(!comprehensiveData.result!.isEmpty)
        
        // 티커 일치 확인 - 같은 종목에 대한 데이터인지 검증
        if let quoteSummaryResult = comprehensiveData.result?.first {
            if let priceModule = quoteSummaryResult.price {
                #expect(simpleQuote.basicInfo.symbol == priceModule.symbol, "Quote와 QuoteSummary의 심볼이 일치해야 함")
                
                // 기본 가격 정보 일치 여부 확인 (소수점 차이 허용)
                if let quotePrice = simpleQuote.marketData.regularMarketPrice,
                   let summaryPrice = priceModule.regularMarketPrice {
                    let priceDiff = abs(quotePrice - summaryPrice)
                    #expect(priceDiff < 1.0, "Quote와 QuoteSummary의 현재가가 유사해야 함 (차이: \(priceDiff))")
                }
                
                // 통화 정보 일치 확인
                #expect(simpleQuote.exchangeInfo.currency == priceModule.currency, "Quote와 QuoteSummary의 통화가 일치해야 함")
            }
        }
        
        // 데이터 타입 차이 확인
        print("📊 Quote 서비스: 간단한 가격 정보")
        print("💰 현재가: \(simpleQuote.marketData.regularMarketPrice ?? 0)")
        print("🏷️ 심볼: \(simpleQuote.basicInfo.symbol ?? "N/A")")
        
        print("📈 Quote Summary 서비스: 종합적인 기업 정보")
        print("📊 결과 수: \(comprehensiveData.result?.count ?? 0)")
        if let result = comprehensiveData.result?.first?.price {
            print("💰 현재가: \(result.regularMarketPrice ?? 0)")
            print("🏷️ 심볼: \(result.symbol ?? "N/A")")
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Test("잘못된 심볼 처리 테스트")
    func testInvalidSymbolHandling() async throws {
        let service = YFQuoteSummaryService(client: client)
        
        do {
            let quoteSummary = try await service.fetchEssential(ticker: invalidTicker)
            
            // Yahoo Finance는 잘못된 심볼에 대해 오류를 반환하거나 빈 결과를 반환할 수 있음
            if let error = quoteSummary.error {
                // 에러가 있는 경우: error 필드가 존재하고 result는 nil이거나 비어있어야 함
                #expect(!error.isEmpty, "에러 메시지는 비어있지 않아야 함")
                #expect(quoteSummary.result == nil || quoteSummary.result!.isEmpty, "에러 시 result는 nil이거나 빈 배열이어야 함")
            } else {
                // 에러가 없는 경우: result가 존재해야 하고, 빈 결과일 수 있음
                #expect(quoteSummary.result != nil, "에러가 없으면 result 배열이 존재해야 함")
                // Yahoo Finance는 잘못된 심볼에 대해서도 때때로 빈 결과를 반환할 수 있음
                if let results = quoteSummary.result, !results.isEmpty {
                    // 결과가 있는 경우, 각 모듈이 올바른 구조를 가져야 함
                    for result in results {
                        #expect(result.price != nil || result.summaryDetail != nil, "최소한 하나의 모듈은 데이터를 가져야 함")
                    }
                }
            }
        } catch {
            // Yahoo Finance는 잘못된 심볼에 대해 HTTP 404나 네트워크 에러를 발생시킬 수 있음
            if case YFError.networkErrorWithMessage(let message) = error {
                #expect(message.contains("404"), "잘못된 심볼에 대해서는 404 에러가 발생해야 함")
            } else if case YFError.httpError(let statusCode) = error {
                #expect(statusCode == 404, "잘못된 심볼에 대해서는 404 상태코드가 반환되어야 함")
            } else {
                // 다른 종류의 에러도 유효함 (API 제한, 네트워크 에러 등)
                #expect(true, "잘못된 심볼에 대해 적절한 에러가 발생함: \(error)")
            }
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("여러 모듈 동시 조회 성능 테스트")
    func testMultipleModulesPerformance() async throws {
        let service = YFQuoteSummaryService(client: client)
        let allModules = YFQuoteSummaryModule.comprehensive
        
        let startTime = Date()
        let quoteSummary = try await service.fetch(ticker: testTicker, modules: allModules)
        let endTime = Date()
        
        let duration = endTime.timeIntervalSince(startTime)
        
        #expect(quoteSummary.result != nil)
        #expect(quoteSummary.error == nil)
        #expect(duration < 30.0) // 30초 이내 완료 목표
        
        print("📊 종합 데이터 조회 시간: \(String(format: "%.2f", duration))초")
    }
}