import Foundation

/// Yahoo Finance Chart 데이터 변환 유틸리티 클래스
///
/// ChartResult를 YFPrice 배열로 변환하는 기능을 제공합니다.
/// 단일 책임 원칙에 따라 차트 데이터 변환 로직만 담당합니다.
public final class YFChartConverter {
    
    /// YFChartConverter 초기화
    public init() {}
    
    /// ChartResult를 YFPrice 배열로 변환합니다
    ///
    /// - Parameter result: Yahoo Finance Chart API의 응답 데이터
    /// - Returns: 파싱된 YFPrice 배열 (날짜 순 정렬)
    func convertToPrices(_ result: ChartResult) -> [YFPrice] {
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