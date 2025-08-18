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
    
    /// 시세 조회 서비스
    public lazy var quote: YFQuoteService = {
        return YFQuoteService(client: self)
    }()
    
    /// YFClient 초기화
    ///
    /// 기본 설정으로 Yahoo Finance API 클라이언트를 생성합니다.
    /// 내부적으로 네트워크 세션, 요청 빌더, 응답 파서를 초기화합니다.
    public init() {
        self.session = YFSession()
        self.requestBuilder = YFRequestBuilder(session: session)
        self.responseParser = YFResponseParser()
        self.chartConverter = YFChartConverter()
        self.dateHelper = YFDateHelper()
    }
    
    /// 주어진 기간에 해당하는 시작 타임스탬프를 반환합니다 (YFDateHelper로 위임)
    ///
    /// - Parameter period: 조회할 기간 (oneDay, oneWeek, oneMonth 등)
    /// - Returns: Unix 타임스탬프 문자열 (초 단위)
    private func periodStart(for period: YFPeriod) -> String {
        return dateHelper.periodStart(for: period)
    }
    
    /// 현재 시점의 종료 타임스탬프를 반환합니다 (YFDateHelper로 위임)
    ///
    /// - Returns: 현재 시점의 Unix 타임스탬프 문자열 (초 단위)
    private func periodEnd() -> String {
        return dateHelper.periodEnd()
    }
    
    /// YFPeriod 열거형을 Yahoo Finance API의 range 파라미터 문자열로 변환합니다 (YFDateHelper로 위임)
    ///
    /// - Parameter period: 변환할 기간 열거형
    /// - Returns: Yahoo Finance API에서 사용하는 range 문자열 ("1d", "1mo", "1y" 등)
    private func periodToRangeString(_ period: YFPeriod) -> String {
        return dateHelper.periodToRangeString(period)
    }
    
    /// 주어진 기간에 해당하는 시작 날짜를 Date 객체로 반환합니다 (YFDateHelper로 위임)
    ///
    /// - Parameter period: 조회할 기간 (oneDay, oneWeek, oneMonth 등)
    /// - Returns: 해당 기간의 시작점에 해당하는 Date 객체
    private func dateFromPeriod(_ period: YFPeriod) -> Date {
        return dateHelper.dateFromPeriod(period)
    }
    
    /// Yahoo Finance Chart API 응답을 YFPrice 배열로 변환합니다
    ///
    /// 원시 Chart API 응답 데이터를 파싱하여 YFPrice 구조체 배열로 변환합니다.
    /// 유효하지 않은 데이터(-1.0 값)는 자동으로 필터링되며, 결과는 날짜 순으로 정렬됩니다.
    ///
    /// - Parameter result: Yahoo Finance Chart API의 응답 데이터
    /// - Returns: 파싱된 YFPrice 배열 (날짜 순 정렬)
    private func convertToPrices(_ result: ChartResult) -> [YFPrice] {
        return chartConverter.convertToPrices(result)
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