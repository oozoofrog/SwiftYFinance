import Foundation
import Testing
@testable import SwiftYFinance

/// Quote Summary URL Builder 테스트
@Suite("Quote Summary URL Builder Tests")
struct YFQuoteSummaryURLBuilderTests {
    
    let session = YFSession()
    
    // MARK: - Basic URL Construction Tests
    
    @Test("기본 URL 구성 테스트")
    func testBasicURLConstruction() async throws {
        let url = try await YFAPIURLBuilder.quoteSummary(session: session)
            .symbol("AAPL")
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("https://query2.finance.yahoo.com/v10/finance/quoteSummary/AAPL"))
        #expect(urlString.contains("corsDomain=finance.yahoo.com"))
        #expect(urlString.contains("formatted=false"))
    }
    
    @Test("심볼 없이 빌드 시 에러 발생")
    func testBuildWithoutSymbol() async throws {
        await #expect(throws: YFError.invalidParameter("Symbol cannot be empty")) {
            _ = try await YFAPIURLBuilder.quoteSummary(session: session)
                .build()
        }
    }
    
    // MARK: - Module Parameter Tests
    
    @Test("단일 모듈 설정 테스트")
    func testSingleModule() async throws {
        let url = try await YFAPIURLBuilder.quoteSummary(session: session)
            .symbol("AAPL")
            .module(.summaryDetail)
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("modules=summaryDetail"))
    }
    
    @Test("여러 모듈 설정 테스트")
    func testMultipleModules() async throws {
        let modules: [YFQuoteSummaryModule] = [.summaryDetail, .financialData, .defaultKeyStatistics]
        let url = try await YFAPIURLBuilder.quoteSummary(session: session)
            .symbol("MSFT")
            .modules(modules)
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("modules=summaryDetail,financialData,defaultKeyStatistics"))
        #expect(urlString.contains("MSFT"))
    }
    
    @Test("필수 정보 모듈 설정 테스트")
    func testEssentialModules() async throws {
        let url = try await YFAPIURLBuilder.quoteSummary(session: session)
            .symbol("GOOGL")
            .essential()
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("modules="))
        #expect(urlString.contains("summaryDetail"))
        #expect(urlString.contains("financialData"))
        #expect(urlString.contains("defaultKeyStatistics"))
        #expect(urlString.contains("price"))
        #expect(urlString.contains("quoteType"))
    }
    
    @Test("종합 분석 모듈 설정 테스트")
    func testComprehensiveModules() async throws {
        let url = try await YFAPIURLBuilder.quoteSummary(session: session)
            .symbol("TSLA")
            .comprehensive()
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("modules="))
        #expect(urlString.contains("summaryDetail"))
        #expect(urlString.contains("incomeStatementHistory"))
        #expect(urlString.contains("earnings"))
    }
    
    // MARK: - Parameter Tests
    
    @Test("포맷팅 파라미터 테스트")
    func testFormattedParameter() async throws {
        let url = try await YFAPIURLBuilder.quoteSummary(session: session)
            .symbol("AAPL")
            .formatted(true)
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("formatted=true"))
    }
    
    @Test("CORS 도메인 파라미터 테스트")
    func testCorsDomainParameter() async throws {
        let customDomain = "custom.finance.com"
        let url = try await YFAPIURLBuilder.quoteSummary(session: session)
            .symbol("AAPL")
            .corsDomain(customDomain)
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("corsDomain=\(customDomain)"))
    }
    
    @Test("커스텀 파라미터 추가 테스트")
    func testCustomParameter() async throws {
        let url = try await YFAPIURLBuilder.quoteSummary(session: session)
            .symbol("AAPL")
            .parameter("customKey", "customValue")
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("customKey=customValue"))
    }
    
    // MARK: - Financial Modules Tests
    
    @Test("연간 재무제표 모듈 설정 테스트")
    func testAnnualFinancials() async throws {
        let url = try await YFAPIURLBuilder.quoteSummary(session: session)
            .symbol("AAPL")
            .financials(quarterly: false)
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("incomeStatementHistory"))
        #expect(urlString.contains("balanceSheetHistory"))
        #expect(urlString.contains("cashFlowStatementHistory"))
        #expect(!urlString.contains("Quarterly"))
    }
    
    @Test("분기별 포함 재무제표 모듈 설정 테스트")
    func testQuarterlyFinancials() async throws {
        let url = try await YFAPIURLBuilder.quoteSummary(session: session)
            .symbol("AAPL")
            .financials(quarterly: true)
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("incomeStatementHistory"))
        #expect(urlString.contains("incomeStatementHistoryQuarterly"))
        #expect(urlString.contains("balanceSheetHistoryQuarterly"))
        #expect(urlString.contains("cashFlowStatementHistoryQuarterly"))
    }
    
    // MARK: - Builder Chain Tests
    
    @Test("체이닝 메서드 조합 테스트")
    func testMethodChaining() async throws {
        let url = try await YFAPIURLBuilder.quoteSummary(session: session)
            .symbol("NVDA")
            .modules([.summaryDetail, .financialData])
            .formatted(true)
            .corsDomain("test.domain.com")
            .parameter("additional", "value")
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("NVDA"))
        #expect(urlString.contains("modules=summaryDetail,financialData"))
        #expect(urlString.contains("formatted=true"))
        #expect(urlString.contains("corsDomain=test.domain.com"))
        #expect(urlString.contains("additional=value"))
    }
    
    @Test("모듈 덮어쓰기 테스트")
    func testModuleOverride() async throws {
        let url = try await YFAPIURLBuilder.quoteSummary(session: session)
            .symbol("AAPL")
            .module(.summaryDetail)
            .modules([.financialData, .price]) // 이전 설정 덮어쓰기
            .build()
        
        let urlString = url.absoluteString
        #expect(urlString.contains("modules=financialData,price"))
        #expect(!urlString.contains("summaryDetail"))
    }
}