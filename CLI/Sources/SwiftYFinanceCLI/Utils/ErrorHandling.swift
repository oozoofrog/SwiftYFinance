import Foundation
import SwiftYFinance

func printError(_ message: String, error: Error) {
    print("❌ \(message)")
    
    if let yfError = error as? YFError {
        switch yfError {
        case .networkError:
            print("💡 Please check your internet connection.")
        case .apiError(let apiMessage):
            print("💡 API Error: \(apiMessage)")
        case .invalidRequest:
            print("💡 Please check if the ticker symbol is valid.")
        default:
            print("💡 Please try again later.")
        }
    } else {
        print("💡 \(error.localizedDescription)")
    }
}