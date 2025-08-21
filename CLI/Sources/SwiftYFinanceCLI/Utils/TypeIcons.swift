import Foundation
import SwiftYFinance

func getTypeIcon(_ type: YFQuoteType) -> String {
    switch type {
    case .equity: return "📈"
    case .etf: return "📊"
    case .mutualFund: return "🏦"
    case .index: return "📉"
    case .future: return "⚡"
    case .currency: return "💱"
    case .cryptocurrency: return "₿"
    default: return "📋"
    }
}