import Foundation

/// Yahoo Finance 주식 심볼 표현
///
/// 주식, ETF, 지수 등의 금융 상품을 식별하는 심볼을 관리합니다.
/// 심볼 정규화(대문자 변환, 공백 제거)를 자동으로 수행합니다.
///
/// ## 지원되는 심볼 형식
/// - **미국 주식**: AAPL, MSFT, GOOGL
/// - **ETF**: SPY, QQQ, VTI  
/// - **지수**: ^GSPC (S&P 500), ^IXIC (NASDAQ)
/// - **국제 주식**: 0700.HK (텐센트), ASML.AS (ASML)
///
/// ## 사용 예시
/// ```swift
/// // 기본 사용법
/// let ticker = YFTicker(symbol: "AAPL")
/// print(ticker.symbol) // "AAPL"
/// 
/// // 자동 정규화
/// let ticker2 = YFTicker(symbol: "  aapl  ")
/// print(ticker2.symbol) // "AAPL"
/// 
/// // 국제 주식
/// let hkTicker = YFTicker(symbol: "0700.HK")
/// ```
///
/// ## 심볼 처리
/// - 공백 문자 자동 제거
/// - 소문자를 대문자로 자동 변환
/// - 심볼 유효성은 Yahoo Finance API에서 검증됨
///
/// ## 오류 처리
/// 잘못된 심볼의 경우 API 호출 시 적절한 에러가 반환됩니다.
/// 클라이언트 측에서는 기본적인 정리만 수행하고 서버 검증에 의존합니다.
public struct YFTicker: CustomStringConvertible, Codable, Hashable, Sendable {
    
    /// 정규화된 심볼 문자열
    ///
    /// 항상 대문자로 변환되고 공백이 제거된 상태입니다.
    public let symbol: String
    
    /// 심볼의 문자열 표현
    public var description: String {
        "YFTicker(symbol: \(symbol))"
    }
    
    /// YFTicker 초기화
    ///
    /// 제공된 심볼 문자열을 정규화합니다.
    /// 심볼 유효성은 Yahoo Finance API 호출 시 서버에서 검증됩니다.
    ///
    /// - Parameter symbol: 주식 심볼 (예: "AAPL", "MSFT")
    public init(symbol: String) {
        // 기본적인 정리만 수행: 공백 제거 및 대문자 변환
        self.symbol = symbol
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }
}