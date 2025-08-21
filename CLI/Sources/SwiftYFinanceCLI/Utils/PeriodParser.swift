import Foundation
import SwiftYFinance

func parseYFPeriod(_ periodString: String) -> YFPeriod? {
    switch periodString.lowercased() {
    case "1d": return .oneDay
    case "5d": return .oneWeek
    case "1mo": return .oneMonth
    case "3mo": return .threeMonths
    case "6mo": return .sixMonths
    case "1y": return .oneYear
    case "2y": return .twoYears
    case "5y": return .fiveYears
    case "10y": return .tenYears
    case "max": return .max
    default: return nil
    }
}