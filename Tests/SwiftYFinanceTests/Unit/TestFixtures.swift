import Foundation
@testable import SwiftYFinance

/// 공통 테스트 데이터 중앙화 열거체
///
/// 여러 테스트 파일에서 반복적으로 사용되는 테스트 상수들을 중앙에서 관리합니다.
/// 하드코딩된 심볼/URL을 여기서 관리하여 변경 시 한 곳만 수정하면 됩니다.
///
/// ## 사용 예시
/// ```swift
/// let ticker = TestFixtures.Tickers.apple
/// let session = YFSession(networkProvider: TestFixtures.mocks.successMock)
/// ```
enum TestFixtures {

    // MARK: - 심볼 상수

    /// 자주 사용되는 주식 티커들
    enum Tickers {
        /// Apple Inc.
        static let apple = YFTicker(symbol: "AAPL")
        /// Microsoft Corporation
        static let microsoft = YFTicker(symbol: "MSFT")
        /// Alphabet Inc. (Google)
        static let google = YFTicker(symbol: "GOOGL")
        /// Tesla Inc.
        static let tesla = YFTicker(symbol: "TSLA")
        /// Amazon.com Inc.
        static let amazon = YFTicker(symbol: "AMZN")
        /// NVIDIA Corporation
        static let nvidia = YFTicker(symbol: "NVDA")
        /// Bitcoin/USD
        static let bitcoinUSD = YFTicker(symbol: "BTC-USD")
        /// S&P 500 지수
        static let sp500 = YFTicker(symbol: "^GSPC")
    }

    // MARK: - 심볼 문자열 배열

    /// 자주 사용되는 심볼 문자열들
    enum Symbols {
        /// 미국 대형주 5종목
        static let largeCaps = ["AAPL", "MSFT", "GOOGL", "AMZN", "NVDA"]
        /// 암호화폐
        static let crypto = ["BTC-USD", "ETH-USD"]
        /// 테스트 심볼 (존재하지 않는 심볼)
        static let invalid = "INVALID_SYMBOL_XYZ_999"
    }

    // MARK: - Mock JSON 응답 데이터

    /// 테스트용 JSON 응답 템플릿들
    enum MockJSON {

        /// 빈 Quote 응답 (result 없음)
        static let emptyQuoteResponse = """
            {
                "quoteResponse": {
                    "result": [],
                    "error": null
                }
            }
            """

        /// 단일 Quote 응답 (AAPL)
        static let singleQuoteResponse = """
            {
                "quoteResponse": {
                    "result": [{
                        "symbol": "AAPL",
                        "regularMarketPrice": 150.0,
                        "regularMarketVolume": 50000000,
                        "marketCap": 2500000000000
                    }],
                    "error": null
                }
            }
            """

        /// Crumb 토큰 응답
        static let validCrumb = "abc123XYZ_crumb"

        /// 에러 응답
        static let apiError = """
            {
                "finance": {
                    "result": null,
                    "error": {
                        "code": "Not Found",
                        "description": "No fundamentals data found for any of the summaryTypes=..."
                    }
                }
            }
            """
    }

    // MARK: - Mock 네트워크 제공자

    /// 미리 설정된 MockNetworkProvider 인스턴스들
    enum Mocks {
        /// 성공 응답 (빈 데이터)
        static var success: MockNetworkProvider { .success }

        /// 유효한 Crumb 토큰 응답
        static var crumbResponse: MockNetworkProvider {
            MockNetworkProvider(
                data: MockJSON.validCrumb.data(using: .utf8)!,
                statusCode: 200
            )
        }

        /// 빈 Quote 응답
        static var emptyQuoteResponse: MockNetworkProvider {
            MockNetworkProvider.json(MockJSON.emptyQuoteResponse)
        }

        /// 401 Unauthorized
        static var unauthorized: MockNetworkProvider { .unauthorized }

        /// 429 Too Many Requests
        static var rateLimited: MockNetworkProvider { .rateLimited }

        /// 네트워크 에러
        static var networkError: MockNetworkProvider {
            MockNetworkProvider(error: URLError(.notConnectedToInternet))
        }
    }

    // MARK: - YFSession 팩토리

    /// Mock 기반 YFSession 생성
    static func mockSession(provider: MockNetworkProvider = .success) -> YFSession {
        YFSession(networkProvider: provider)
    }

    /// Mock 기반 YFClient 생성 (네트워크 없이 테스트 가능)
    static func mockClient(provider: MockNetworkProvider = .success) -> YFClient {
        let session = mockSession(provider: provider)
        return YFClient(session: session)
    }
}
