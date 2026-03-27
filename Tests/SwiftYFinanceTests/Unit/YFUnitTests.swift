import Testing
import Foundation
@testable import SwiftYFinance

/// MockNetworkProvider를 사용한 단위 테스트
///
/// 실제 Yahoo Finance API 연결 없이 서비스 로직을 검증합니다.
/// 모든 테스트는 MockNetworkProvider를 통해 미리 정의된 응답을 사용합니다.
///
/// @Suite의 init/deinit에서 TestHelper.setUp/tearDown을 자동 호출합니다.
@Suite("Unit Tests - MockNetworkProvider 기반 단위 테스트")
struct YFUnitTests {

    init() async {
        await TestHelper.setUp()
    }

    // MARK: - YFSession Mock 주입 테스트

    @Test("TestFixtures 티커 상수 검증")
    func testTestFixturesTickers() {
        #expect(TestFixtures.Tickers.apple.symbol == "AAPL")
        #expect(TestFixtures.Tickers.microsoft.symbol == "MSFT")
        #expect(TestFixtures.Tickers.google.symbol == "GOOGL")
        #expect(TestFixtures.Tickers.bitcoinUSD.symbol == "BTC-USD")
    }

    @Test("TestFixtures 심볼 배열 검증")
    func testTestFixturesSymbols() {
        #expect(TestFixtures.Symbols.largeCaps.count == 5)
        #expect(TestFixtures.Symbols.largeCaps.contains("AAPL"))
        #expect(!TestFixtures.Symbols.invalid.isEmpty)
    }

    @Test("TestFixtures Mock 팩토리 검증")
    func testTestFixturesMocks() async throws {
        let session = TestFixtures.mockSession(provider: .success)
        let isAuthenticated = await session.isAuthenticated
        #expect(!isAuthenticated)
    }

    @Test("MockNetworkProvider 기본 동작 검증")
    func testMockNetworkProviderBasicBehavior() async throws {
        let json = "{\"test\": \"value\"}"
        let mock = MockNetworkProvider.json(json)
        let request = URLRequest(url: URL(string: "https://example.com")!)

        let (data, response) = try await mock.data(for: request)
        let httpResponse = try #require(response as? HTTPURLResponse)

        #expect(httpResponse.statusCode == 200)
        #expect(!data.isEmpty)

        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: String]
        #expect(decoded?["test"] == "value")
    }

    @Test("MockNetworkProvider 에러 시뮬레이션")
    func testMockNetworkProviderErrorSimulation() async throws {
        let networkError = URLError(.notConnectedToInternet)
        let mock = MockNetworkProvider(error: networkError)
        let request = URLRequest(url: URL(string: "https://example.com")!)

        do {
            _ = try await mock.data(for: request)
            #expect(false, "에러가 던져져야 함")
        } catch let error as URLError {
            #expect(error.code == .notConnectedToInternet)
        }
    }

    @Test("MockNetworkProvider HTTP 상태 코드 검증")
    func testMockNetworkProviderStatusCodes() async throws {
        let request = URLRequest(url: URL(string: "https://example.com")!)

        // 401 Unauthorized
        let (_, unauthorizedResponse) = try await MockNetworkProvider.unauthorized.data(for: request)
        let httpUnauthorized = try #require(unauthorizedResponse as? HTTPURLResponse)
        #expect(httpUnauthorized.statusCode == 401)

        // 429 Too Many Requests
        let (_, rateLimitedResponse) = try await MockNetworkProvider.rateLimited.data(for: request)
        let httpRateLimited = try #require(rateLimitedResponse as? HTTPURLResponse)
        #expect(httpRateLimited.statusCode == 429)

        // 500 Server Error
        let (_, serverErrorResponse) = try await MockNetworkProvider.serverError.data(for: request)
        let httpServerError = try #require(serverErrorResponse as? HTTPURLResponse)
        #expect(httpServerError.statusCode == 500)
    }

    // MARK: - YFSession + MockNetworkProvider 통합

    @Test("YFSession Mock 주입 초기화 검증")
    func testYFSessionMockInjection() async {
        let mock = MockNetworkProvider.success
        let session = YFSession(networkProvider: mock)

        // 세션이 정상 초기화되었는지 확인
        let isAuthenticated = await session.isAuthenticated
        #expect(!isAuthenticated) // 초기에는 미인증 상태

        let crumb = await session.crumbToken
        #expect(crumb == nil) // 초기에는 crumb 없음
    }

    @Test("YFSession Mock으로 인증 응답 처리")
    func testYFSessionWithMockCrumbResponse() async throws {
        // 크럼 응답을 시뮬레이션하는 Mock
        let crumbValue = "test-crumb-abc123"
        let mock = MockNetworkProvider(
            data: crumbValue.data(using: .utf8)!,
            statusCode: 200
        )
        let session = YFSession(networkProvider: mock)

        // crumb 획득 시도 (Mock 응답 사용)
        let success = await session.getCrumbToken(strategy: .basic)

        // Mock이 유효한 crumb 데이터를 반환하므로 성공해야 함
        #expect(success)

        let crumb = await session.crumbToken
        #expect(crumb == crumbValue)
    }

    @Test("YFSession Mock으로 인증 실패 처리")
    func testYFSessionWithMockAuthFailure() async throws {
        // 401 응답으로 인증 실패 시뮬레이션
        let mock = MockNetworkProvider.unauthorized
        let session = YFSession(networkProvider: mock)

        // crumb 획득 실패
        let success = await session.getCrumbToken(strategy: .basic)
        #expect(!success)

        let crumb = await session.crumbToken
        #expect(crumb == nil)
    }

    // MARK: - YFError Mock 테스트

    @Test("getBasicCookie는 DNS 에러만 실패 처리 (타임아웃은 성공 처리)")
    func testBasicCookieErrorHandling() async {
        // timedOut 에러는 DNS 에러가 아니므로 getBasicCookie는 성공으로 처리
        // 그러나 crumb 요청도 실패하면 attemptBasicAuthentication은 false 반환
        let networkError = URLError(.timedOut)
        let mock = MockNetworkProvider(error: networkError)
        let session = YFSession(networkProvider: mock)

        // getCrumbToken은 에러 시 false 반환
        let crumbResult = await session.getCrumbToken(strategy: .basic)
        #expect(!crumbResult)
    }

    @Test("DNS 에러 발생 시 basic 인증 실패")
    func testBasicAuthenticationFailsOnDNSError() async {
        let dnsError = URLError(.cannotFindHost)
        let mock = MockNetworkProvider(error: dnsError)
        let session = YFSession(networkProvider: mock)

        // DNS 에러는 getBasicCookie에서 false 반환 → attemptBasicAuthentication도 false
        let result = await session.attemptBasicAuthentication()
        #expect(!result)
    }

    // MARK: - YFTicker 단위 테스트 (네트워크 불필요)

    @Test("YFTicker 심볼 정규화 검증")
    func testYFTickerSymbolNormalization() {
        // YFTicker는 throw하지 않으며 자동 정규화 수행
        let ticker = YFTicker(symbol: "aapl")
        #expect(ticker.symbol == "AAPL") // 대문자로 정규화

        let paddedTicker = YFTicker(symbol: "  MSFT  ")
        #expect(paddedTicker.symbol == "MSFT") // 공백 제거

        let btcTicker = YFTicker(symbol: "BTC-USD")
        #expect(btcTicker.symbol == "BTC-USD")
    }

    @Test("YFTicker 빈 심볼 정규화 동작 확인")
    func testYFTickerEmptySymbolNormalized() {
        // YFTicker는 빈 심볼을 서버 검증에 위임하므로 throw하지 않음
        let emptyTicker = YFTicker(symbol: "")
        // 빈 심볼은 정규화 후에도 빈 문자열
        #expect(emptyTicker.symbol == "")
    }
}
