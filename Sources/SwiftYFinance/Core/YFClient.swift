import Foundation

/// SwiftYFinance의 메인 클라이언트 구조체
///
/// Yahoo Finance API와 상호작용하여 금융 데이터를 조회하는 핵심 인터페이스입니다.
/// Python yfinance 라이브러리의 Swift 포팅 버전으로, 동일한 API를 제공합니다.
/// Sendable 프로토콜을 준수하여 concurrent 환경에서 안전하게 사용할 수 있습니다.
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
/// // 시세 조회 (서비스 기반)
/// let quote = try await client.quote.fetch(ticker: ticker)
/// print("현재가: \(quote.regularMarketPrice)")
/// 
/// // 과거 데이터 조회
/// let history = try await client.history.fetch(ticker: ticker, period: .oneYear)
/// 
/// // 종목 검색
/// let results = try await client.search.find(companyName: "Apple")
/// ```
public struct YFClient: Sendable {
    /// 네트워크 세션 관리자
    public let session: YFSession
    
    /// API 응답 파서
    internal let responseParser: YFResponseParser
    
    /// 차트 데이터 변환기
    public let chartConverter: YFChartConverter
    
    /// 날짜 변환 헬퍼
    public let dateHelper: YFDateHelper
    
    /// 디버깅 모드 플래그
    private let debugEnabled: Bool
    
    /// YFClient 초기화
    ///
    /// 기본 설정으로 Yahoo Finance API 클라이언트를 생성합니다.
    /// 내부적으로 네트워크 세션, 요청 빌더, 응답 파서를 초기화합니다.
    ///
    /// - Parameter debugEnabled: 디버깅 로그 활성화 여부 (기본값: false)
    public init(debugEnabled: Bool = false) {
        self.debugEnabled = debugEnabled
        self.session = YFSession()
        self.responseParser = YFResponseParser()
        self.chartConverter = YFChartConverter()
        self.dateHelper = YFDateHelper()
    }
    
    // MARK: - Services
    
    /// 시세 조회 서비스
    public var quote: YFQuoteService {
        YFQuoteService(client: self, debugEnabled: debugEnabled)
    }
    
    /// 과거 가격 데이터 조회 서비스
    public var history: YFHistoryService {
        YFHistoryService(client: self, debugEnabled: debugEnabled)
    }
    
    /// 종목 검색 및 자동완성 서비스
    public var search: YFSearchService {
        YFSearchService(client: self, debugEnabled: debugEnabled)
    }
    
    /// 통합 재무제표 조회 서비스 (Income Statement, Balance Sheet, Cash Flow 포괄)
    public var fundamentals: YFFundamentalsService {
        YFFundamentalsService(client: self, debugEnabled: debugEnabled)
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