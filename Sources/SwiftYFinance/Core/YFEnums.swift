import Foundation

/// Yahoo Finance에서 지원하는 기간 설정
///
/// 과거 데이터를 조회할 때 사용하는 기간 옵션으로, 현재 날짜를 기준으로 
/// 과거 얼마나 많은 데이터를 가져올지 결정합니다.
///
/// ## 지원 기간
/// - **단기**: 1일, 1주, 1개월
/// - **중기**: 3개월, 6개월, 1년
/// - **장기**: 2년, 5년, 10년
/// - **전체**: 사용 가능한 모든 데이터 (`max`)
///
/// ## 사용 예시
/// ```swift
/// let client = YFClient()
/// 
/// // 최근 1년간 일간 데이터
/// let yearData = try await client.fetchHistory(
///     ticker: YFTicker(symbol: "AAPL"),
///     period: .oneYear,
///     interval: .oneDay
/// )
/// 
/// // 전체 과거 데이터
/// let allData = try await client.fetchHistory(
///     ticker: YFTicker(symbol: "AAPL"),
///     period: .max
/// )
/// ```
///
/// ## 주의사항
/// - 짧은 interval(분 단위)의 경우 제한된 기간만 사용 가능
/// - `max`는 주식의 상장일부터 현재까지 모든 데이터를 반환
///
/// - SeeAlso: ``YFInterval``
/// - SeeAlso: yfinance-reference/yfinance/scrapers/history.py period 파라미터
public enum YFPeriod {
    /// 1일 데이터
    case oneDay
    
    /// 1주일 데이터 (5 거래일)
    case oneWeek
    
    /// 1개월 데이터 (약 22 거래일)
    case oneMonth
    
    /// 3개월 데이터 (약 66 거래일)
    case threeMonths
    
    /// 6개월 데이터 (약 132 거래일)
    case sixMonths
    
    /// 1년 데이터 (약 252 거래일)
    case oneYear
    
    /// 2년 데이터 (약 504 거래일)
    case twoYears
    
    /// 5년 데이터 (약 1260 거래일)
    case fiveYears
    
    /// 10년 데이터 (약 2520 거래일)
    case tenYears
    
    /// 사용 가능한 모든 과거 데이터
    case max
}

/// Yahoo Finance에서 지원하는 시간 간격 설정
///
/// 과거 데이터의 캔들 간격을 정의합니다. 분 단위부터 월 단위까지 
/// 다양한 시간 프레임을 지원하며, 각 간격마다 조회 가능한 기간에 제한이 있습니다.
///
/// ## 지원 간격
/// - **분 단위**: 1분, 2분, 5분, 15분, 30분, 60분, 90분
/// - **시간 단위**: 1시간
/// - **일 단위**: 1일, 5일
/// - **주/월 단위**: 1주, 1개월, 3개월
///
/// ## 사용 예시
/// ```swift
/// let client = YFClient()
/// 
/// // 1분 간격 데이터 (최근 7일까지만 가능)
/// let minuteData = try await client.fetchHistory(
///     ticker: YFTicker(symbol: "AAPL"),
///     period: .oneWeek,
///     interval: .oneMinute
/// )
/// 
/// // 일간 데이터 (장기간 가능)
/// let dailyData = try await client.fetchHistory(
///     ticker: YFTicker(symbol: "AAPL"),
///     period: .oneYear,
///     interval: .oneDay
/// )
/// ```
///
/// ## 제한사항
/// | Interval | 최대 조회 가능 기간 |
/// |----------|------------------|
/// | 1m       | 7일              |
/// | 2m-90m   | 60일             |
/// | 1h       | 730일 (2년)      |
/// | 1d 이상   | 제한 없음         |
///
/// ## API 매핑
/// 내부적으로 Yahoo Finance API 형식으로 자동 변환됩니다:
/// - `.oneMinute` → `"1m"`
/// - `.oneDay` → `"1d"`
/// - `.oneWeek` → `"1wk"`
///
/// - SeeAlso: ``YFPeriod``
/// - SeeAlso: ``stringValue``
/// - SeeAlso: yfinance-reference/yfinance/scrapers/history.py interval 파라미터
public enum YFInterval {
    /// 1분 간격 (최대 7일 데이터)
    case oneMinute
    
    /// 2분 간격 (최대 60일 데이터)
    case twoMinutes
    
    /// 5분 간격 (최대 60일 데이터)
    case fiveMinutes
    
    /// 15분 간격 (최대 60일 데이터)
    case fifteenMinutes
    
    /// 30분 간격 (최대 60일 데이터)
    case thirtyMinutes
    
    /// 60분 간격 (최대 60일 데이터)
    case sixtyMinutes
    
    /// 90분 간격 (최대 60일 데이터)
    case ninetyMinutes
    
    /// 1시간 간격 (최대 730일 데이터)
    case oneHour
    
    /// 1일 간격 (제한 없음)
    case oneDay
    
    /// 5일 간격 (제한 없음)
    case fiveDays
    
    /// 1주 간격 (제한 없음)
    case oneWeek
    
    /// 1개월 간격 (제한 없음)
    case oneMonth
    
    /// 3개월 간격 (제한 없음)
    case threeMonths
    
    /// Yahoo Finance API에서 사용하는 interval 문자열 값 반환
    ///
    /// 내부적으로 API 요청 시 사용되는 문자열 표현을 반환합니다.
    ///
    /// ## 변환 예시
    /// ```swift
    /// let interval = YFInterval.oneDay
    /// print(interval.stringValue) // "1d"
    /// 
    /// let minuteInterval = YFInterval.fiveMinutes
    /// print(minuteInterval.stringValue) // "5m"
    /// ```
    ///
    /// ## 반환값 매핑
    /// - 분 단위: `"1m"`, `"2m"`, `"5m"`, `"15m"`, `"30m"`, `"60m"`, `"90m"`
    /// - 시간 단위: `"1h"`
    /// - 일/주/월 단위: `"1d"`, `"5d"`, `"1wk"`, `"1mo"`, `"3mo"`
    public var stringValue: String {
        switch self {
        case .oneMinute: return "1m"
        case .twoMinutes: return "2m"
        case .fiveMinutes: return "5m"
        case .fifteenMinutes: return "15m"
        case .thirtyMinutes: return "30m"
        case .sixtyMinutes: return "60m"
        case .ninetyMinutes: return "90m"
        case .oneHour: return "1h"
        case .oneDay: return "1d"
        case .fiveDays: return "5d"
        case .oneWeek: return "1wk"
        case .oneMonth: return "1mo"
        case .threeMonths: return "3mo"
        }
    }
}