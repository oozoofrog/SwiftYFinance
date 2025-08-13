import Foundation

/// Yahoo Finance 주식 심볼 표현
///
/// 주식, ETF, 지수 등의 금융 상품을 식별하는 심볼을 안전하게 관리합니다.
/// 심볼 유효성 검증 및 정규화를 자동으로 수행합니다.
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
/// let ticker = try YFTicker(symbol: "AAPL")
/// print(ticker.symbol) // "AAPL"
/// 
/// // 자동 정규화
/// let ticker2 = try YFTicker(symbol: "  aapl  ")
/// print(ticker2.symbol) // "AAPL"
/// 
/// // 국제 주식
/// let hkTicker = try YFTicker(symbol: "0700.HK")
/// ```
///
/// ## 유효성 검증
/// 심볼은 다음 조건을 만족해야 합니다:
/// - 1-10자 길이
/// - 영숫자, 점(.), 하이픈(-), 캐럿(^) 문자만 허용
/// - 공백 문자 자동 제거
///
/// - Throws: ``YFError/invalidSymbol`` 유효하지 않은 심볼인 경우
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
    /// 제공된 심볼 문자열의 유효성을 검증하고 정규화합니다.
    ///
    /// - Parameter symbol: 주식 심볼 (예: "AAPL", "MSFT")
    /// - Throws: ``YFError/invalidSymbol`` 심볼이 유효하지 않은 경우
    public init(symbol: String) throws {
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw YFError.invalidSymbol
        }
        
        guard trimmed.count <= 10 else {
            throw YFError.invalidSymbol
        }
        
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-^"))
        guard trimmed.rangeOfCharacter(from: allowedCharacters.inverted) == nil else {
            throw YFError.invalidSymbol
        }
        
        self.symbol = trimmed.uppercased()
    }
}