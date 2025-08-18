import Foundation

/// SwiftYFinance의 메인 클라이언트 클래스
///
/// Yahoo Finance API와 상호작용하여 금융 데이터를 조회하는 핵심 인터페이스입니다.
/// Python yfinance 라이브러리의 Swift 포팅 버전으로, 동일한 API를 제공합니다.
///
/// ## 주요 기능
/// - **과거 가격 데이터**: 일간/분간 OHLCV 데이터
/// - **실시간 시세**: 현재 가격 및 시장 정보
/// - **WebSocket 스트리밍**: 실시간 가격 데이터 스트리밍 (Python yfinance의 `live` 기능)
/// - **재무제표**: 손익계산서, 대차대조표, 현금흐름표
/// - **실적 데이터**: 분기별/연간 실적 정보
///
/// ## 사용 예시
/// ```swift
/// let client = YFClient()
/// 
/// // 애플 주식 1년간 일간 데이터
/// let history = try await client.fetchPriceHistory(
///     symbol: "AAPL", 
///     period: .oneYear
/// )
/// 
/// // 실시간 시세 조회
/// let quote = try await client.fetchQuote(symbol: "AAPL")
/// print("현재가: \(quote.regularMarketPrice)")
/// 
/// // WebSocket 실시간 스트리밍
/// let stream = try await client.startRealTimeStreaming(symbols: ["AAPL", "TSLA"])
/// for await quote in stream {
///     print("\(quote.symbol): $\(quote.price)")
/// }
/// ```
public class YFClient {
    /// 네트워크 세션 관리자
    internal let session: YFSession
    
    /// HTTP 요청 빌더
    internal let requestBuilder: YFRequestBuilder
    
    /// API 응답 파서
    internal let responseParser: YFResponseParser
    
    /// 차트 데이터 변환기
    internal let chartConverter: YFChartConverter
    
    /// 날짜 변환 헬퍼
    internal let dateHelper: YFDateHelper
    
    /// 디버깅 모드 플래그
    private let debugEnabled: Bool
    
    /// 시세 조회 서비스
    public lazy var quote = YFQuoteService(client: self, debugEnabled: debugEnabled)
    
    /// 과거 가격 데이터 조회 서비스
    public lazy var history = YFHistoryService(client: self, debugEnabled: debugEnabled)
    
    /// 종목 검색 및 자동완성 서비스
    public lazy var search = YFSearchService(client: self, debugEnabled: debugEnabled)
    
    /// YFClient 초기화
    ///
    /// 기본 설정으로 Yahoo Finance API 클라이언트를 생성합니다.
    /// 내부적으로 네트워크 세션, 요청 빌더, 응답 파서를 초기화합니다.
    ///
    /// - Parameter debugEnabled: 디버깅 로그 활성화 여부 (기본값: false)
    public init(debugEnabled: Bool = false) {
        self.debugEnabled = debugEnabled
        self.session = YFSession()
        self.requestBuilder = YFRequestBuilder(session: session)
        self.responseParser = YFResponseParser()
        self.chartConverter = YFChartConverter()
        self.dateHelper = YFDateHelper()
    }
}

// 실제 Yahoo Finance Chart API 응답 구조에 맞춘 구조체들


// MARK: - Debug Methods
/// YFClient의 디버깅을 위한 공개 메서드들
extension YFClient {
    
    /// 현재 CSRF 인증 상태를 확인합니다
    /// - Returns: 인증 여부
    public var isCSRFAuthenticated: Bool {
        get async {
            await session.isCSRFAuthenticated
        }
    }
    
    /// CSRF 인증을 수행합니다
    /// - Throws: 인증 실패 시 YFError
    public func authenticateCSRF() async throws {
        try await session.authenticateCSRF()
    }
    
    /// 현재 crumb 토큰 상태를 확인합니다
    /// - Returns: crumb 토큰 (옵셔널)
    public var crumbToken: String? {
        get async {
            await session.crumbToken
        }
    }
    
    /// 현재 쿠키 전략을 확인합니다
    /// - Returns: 현재 사용 중인 쿠키 전략
    public var cookieStrategy: CookieStrategy {
        get async {
            await session.cookieStrategy
        }
    }
}