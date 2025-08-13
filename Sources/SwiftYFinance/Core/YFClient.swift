import Foundation

/// SwiftYFinance의 메인 클라이언트 클래스
///
/// Yahoo Finance API와 상호작용하여 금융 데이터를 조회하는 핵심 인터페이스입니다.
/// Python yfinance 라이브러리의 Swift 포팅 버전으로, 동일한 API를 제공합니다.
///
/// ## 주요 기능
/// - **과거 가격 데이터**: 일간/분간 OHLCV 데이터
/// - **실시간 시세**: 현재 가격 및 시장 정보
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
/// ```
public class YFClient {
    /// 네트워크 세션 관리자
    internal let session: YFSession
    
    /// HTTP 요청 빌더
    internal let requestBuilder: YFRequestBuilder
    
    /// API 응답 파서
    internal let responseParser: YFResponseParser
    
    /// YFClient 초기화
    ///
    /// 기본 설정으로 Yahoo Finance API 클라이언트를 생성합니다.
    /// 내부적으로 네트워크 세션, 요청 빌더, 응답 파서를 초기화합니다.
    public init() {
        self.session = YFSession()
        self.requestBuilder = YFRequestBuilder(session: session)
        self.responseParser = YFResponseParser()
    }
    
    /// 주어진 기간에 해당하는 시작 타임스탬프를 반환합니다
    ///
    /// - Parameter period: 조회할 기간 (oneDay, oneWeek, oneMonth 등)
    /// - Returns: Unix 타임스탬프 문자열 (초 단위)
    private func periodStart(for period: YFPeriod) -> String {
        let date: Date
        let calendar = Calendar.current
        
        switch period {
        case .oneDay:
            date = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        case .oneWeek:
            date = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        case .oneMonth:
            date = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .threeMonths:
            date = calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        case .sixMonths:
            date = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        case .oneYear:
            date = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        case .twoYears:
            date = calendar.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        case .fiveYears:
            date = calendar.date(byAdding: .year, value: -5, to: Date()) ?? Date()
        case .tenYears:
            date = calendar.date(byAdding: .year, value: -10, to: Date()) ?? Date()
        case .max:
            date = Calendar.current.date(from: DateComponents(year: 1970, month: 1, day: 1)) ?? Date()
        }
        
        return String(Int(date.timeIntervalSince1970))
    }
    
    /// 현재 시점의 종료 타임스탬프를 반환합니다
    ///
    /// - Returns: 현재 시점의 Unix 타임스탬프 문자열 (초 단위)
    private func periodEnd() -> String {
        return String(Int(Date().timeIntervalSince1970))
    }
    
    /// YFPeriod 열거형을 Yahoo Finance API의 range 파라미터 문자열로 변환합니다
    ///
    /// - Parameter period: 변환할 기간 열거형
    /// - Returns: Yahoo Finance API에서 사용하는 range 문자열 ("1d", "1mo", "1y" 등)
    private func periodToRangeString(_ period: YFPeriod) -> String {
        switch period {
        case .oneDay:
            return "1d"
        case .oneWeek:
            return "5d"
        case .oneMonth:
            return "1mo"
        case .threeMonths:
            return "3mo"
        case .sixMonths:
            return "6mo"
        case .oneYear:
            return "1y"
        case .twoYears:
            return "2y"
        case .fiveYears:
            return "5y"
        case .tenYears:
            return "10y"
        case .max:
            return "max"
        }
    }
    
    /// 주어진 기간에 해당하는 시작 날짜를 Date 객체로 반환합니다
    ///
    /// - Parameter period: 조회할 기간 (oneDay, oneWeek, oneMonth 등)
    /// - Returns: 해당 기간의 시작점에 해당하는 Date 객체
    private func dateFromPeriod(_ period: YFPeriod) -> Date {
        let calendar = Calendar.current
        
        switch period {
        case .oneDay:
            return calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        case .oneWeek:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        case .oneMonth:
            return calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        case .twoYears:
            return calendar.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        case .fiveYears:
            return calendar.date(byAdding: .year, value: -5, to: Date()) ?? Date()
        case .tenYears:
            return calendar.date(byAdding: .year, value: -10, to: Date()) ?? Date()
        case .max:
            return Calendar.current.date(from: DateComponents(year: 1970, month: 1, day: 1)) ?? Date()
        }
    }
    
    /// Yahoo Finance Chart API 응답을 YFPrice 배열로 변환합니다
    ///
    /// 원시 Chart API 응답 데이터를 파싱하여 YFPrice 구조체 배열로 변환합니다.
    /// 유효하지 않은 데이터(-1.0 값)는 자동으로 필터링되며, 결과는 날짜 순으로 정렬됩니다.
    ///
    /// - Parameter result: Yahoo Finance Chart API의 응답 데이터
    /// - Returns: 파싱된 YFPrice 배열 (날짜 순 정렬)
    private func convertToPrices(_ result: ChartResult) -> [YFPrice] {
        guard let quote = result.indicators.quote.first,
              let timestamps = result.timestamp else {
            return []
        }
        
        var prices: [YFPrice] = []
        let adjCloseArray = result.indicators.adjclose?.first?.adjclose
        
        for i in 0..<timestamps.count {
            guard i < quote.open.count,
                  i < quote.high.count,
                  i < quote.low.count,
                  i < quote.close.count,
                  i < quote.volume.count else {
                continue
            }
            
            let open = quote.open[i]
            let high = quote.high[i]
            let low = quote.low[i]
            let close = quote.close[i]
            let volume = quote.volume[i]
            
            // -1.0 값 (null)은 건너뛰기
            if open == -1.0 || high == -1.0 || low == -1.0 || close == -1.0 || volume == -1 {
                continue
            }
            
            let date = Date(timeIntervalSince1970: TimeInterval(timestamps[i]))
            let adjClose = (adjCloseArray != nil && i < adjCloseArray!.count) ? 
                          (adjCloseArray![i] == -1.0 ? close : adjCloseArray![i]) : close
            
            let price = YFPrice(
                date: date,
                open: open,
                high: high,
                low: low,
                close: close,
                adjClose: adjClose,
                volume: volume
            )
            
            prices.append(price)
        }
        
        return prices.sorted(by: { $0.date < $1.date })
    }
}

// 실제 Yahoo Finance Chart API 응답 구조에 맞춘 구조체들


// MARK: - Private Helper Methods
/// YFClient의 내부 헬퍼 메서드들을 위한 확장
extension YFClient {
}