import Testing
import Foundation
@testable import SwiftYFinance

/// YFScreenerService의 TDD 기반 테스트
/// 
/// 개발 가이드의 TDD 원칙을 따라 구현:
/// - Red → Green → Refactor 사이클 준수
/// - 한 번에 하나의 테스트만 작업
/// - 실제 API 호출을 통한 end-to-end 테스트
/// - Mock 사용 금지
@Suite("YFScreenerService Tests")
struct YFScreenerServiceTests {
    
    let client = YFClient(debugEnabled: true)
    
    /// 기본 아키텍처 검증 - 가장 작은 테스트부터 시작
    @Test("YFScreenerService 기본 구조 검증")
    func testScreenerService_BasicArchitecture_FollowsProtocolStructPattern() async throws {
        // Given: YFClient가 준비되었을 때
        let client = YFClient()
        
        // When: screener 서비스에 접근할 때
        let screenerService = client.screener
        
        // Then: YFService 프로토콜을 따라야 함
        #expect(screenerService is YFService, "YFScreenerService는 YFService 프로토콜을 준수해야 함")
    }
    
    /// Raw JSON 조회 기능 - 사전 정의 스크리너
    @Test("사전 정의 스크리너 Raw JSON 조회")
    func testFetchRawJSON_WithPredefinedScreener_ReturnsJSONData() async throws {
        // Given: 유효한 사전 정의 스크리너
        let predefinedScreener = YFPredefinedScreener.dayGainers
        
        // When: Raw JSON을 조회할 때
        let jsonData = try await client.screener.fetchRawJSON(predefined: predefinedScreener, limit: 10)
        
        // Then: JSON 데이터가 반환되어야 함
        #expect(jsonData.count > 0, "Raw JSON 데이터가 반환되어야 함")
        
        // JSON 파싱 가능 여부 확인
        let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
        #expect(json is [String: Any], "유효한 JSON 구조여야 함")
    }
    
    /// 사전 정의 스크리너 파싱된 결과 조회
    @Test("사전 정의 스크리너 파싱된 결과 조회")
    func testScreenPredefined_WithDayGainers_ReturnsScreenResults() async throws {
        // Given: 유효한 사전 정의 스크리너
        let predefinedScreener = YFPredefinedScreener.dayGainers
        
        // When: 파싱된 스크리닝 결과를 조회할 때
        let results = try await client.screener.screenPredefined(predefinedScreener, limit: 10)
        
        // Then: 유효한 스크리닝 결과가 반환되어야 함
        #expect(!results.isEmpty, "스크리닝 결과가 있어야 함")
        #expect(results.count <= 10, "요청한 제한 수를 초과하지 않아야 함")
        
        // 첫 번째 결과 검증
        let firstResult = try #require(results.first)
        #expect(!(firstResult.symbol ?? "").isEmpty, "종목 심볼이 있어야 함")
        #expect(!(firstResult.shortName ?? "").isEmpty, "회사명이 있어야 함")
        #expect((firstResult.regularMarketPrice ?? 0) >= 0, "가격은 0 이상이어야 함")
    }
}