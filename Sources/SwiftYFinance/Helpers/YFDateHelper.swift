import Foundation

/// Yahoo Finance API를 위한 날짜 관련 유틸리티 클래스
///
/// YFPeriod를 날짜와 타임스탬프로 변환하는 헬퍼 메서드들을 제공합니다.
/// 단일 책임 원칙에 따라 날짜 변환 로직만 담당합니다.
public final class YFDateHelper {
    
    /// YFDateHelper 초기화
    public init() {}
    
    /// 주어진 기간에 해당하는 시작 타임스탬프를 반환합니다
    ///
    /// - Parameter period: 조회할 기간 (oneDay, oneWeek, oneMonth 등)
    /// - Returns: Unix 타임스탬프 문자열 (초 단위)
    public func periodStart(for period: YFPeriod) -> String {
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
    public func periodEnd() -> String {
        return String(Int(Date().timeIntervalSince1970))
    }
    
    /// YFPeriod 열거형을 Yahoo Finance API의 range 파라미터 문자열로 변환합니다
    ///
    /// - Parameter period: 변환할 기간 열거형
    /// - Returns: Yahoo Finance API에서 사용하는 range 문자열 ("1d", "1mo", "1y" 등)
    public func periodToRangeString(_ period: YFPeriod) -> String {
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
    public func dateFromPeriod(_ period: YFPeriod) -> Date {
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
}