import Foundation

/// Yahoo Finance에서 지원하는 기간 설정
/// - SeeAlso: yfinance-reference/yfinance/scrapers/history.py period 파라미터
public enum YFPeriod {
    case oneDay
    case oneWeek
    case oneMonth
    case threeMonths
    case sixMonths
    case oneYear
    case twoYears
    case fiveYears
    case tenYears
    case max
}

/// Yahoo Finance에서 지원하는 시간 간격 설정
/// - SeeAlso: yfinance-reference/yfinance/scrapers/history.py interval 파라미터
public enum YFInterval {
    case oneMinute
    case twoMinutes
    case fiveMinutes
    case fifteenMinutes
    case thirtyMinutes
    case sixtyMinutes
    case ninetyMinutes
    case oneHour
    case oneDay
    case fiveDays
    case oneWeek
    case oneMonth
    case threeMonths
    
    /// interval 문자열 값 반환
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