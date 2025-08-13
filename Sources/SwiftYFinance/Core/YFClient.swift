import Foundation

public class YFClient {
    internal let session: YFSession
    internal let requestBuilder: YFRequestBuilder
    internal let responseParser: YFResponseParser
    
    public init() {
        self.session = YFSession()
        self.requestBuilder = YFRequestBuilder(session: session)
        self.responseParser = YFResponseParser()
    }
    
    
    
    
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
    
    private func periodEnd() -> String {
        return String(Int(Date().timeIntervalSince1970))
    }
    
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
extension YFClient {
}