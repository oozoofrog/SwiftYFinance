import Foundation

// MARK: - YFQuote Utility Extensions

extension YFQuote {
    /// 시세 데이터만 필요한 경우의 간소화된 표현
    public var essentialData: (symbol: String?, price: Double?, change: Double?, changePercent: Double?) {
        return (
            symbol: basicInfo.symbol,
            price: marketData.regularMarketPrice,
            change: marketData.regularMarketChange,
            changePercent: marketData.regularMarketChangePercent
        )
    }
    
    /// 시장 상태를 기반으로 한 적절한 가격 정보 반환
    public var currentPrice: Double? {
        switch volumeInfo.marketState {
        case "PRE":
            return extendedHours.preMarketPrice ?? marketData.regularMarketPrice
        case "POST":
            return extendedHours.postMarketPrice ?? marketData.regularMarketPrice
        default:
            return marketData.regularMarketPrice
        }
    }
    
    /// 현재 시세의 전일 대비 변동률 (시간외 거래 포함)
    public var currentChangePercent: Double? {
        switch volumeInfo.marketState {
        case "PRE":
            return extendedHours.preMarketChangePercent ?? marketData.regularMarketChangePercent
        case "POST":
            return extendedHours.postMarketChangePercent ?? marketData.regularMarketChangePercent
        default:
            return marketData.regularMarketChangePercent
        }
    }
    
    /// 시장 상태에 맞는 마지막 업데이트 시간
    public var lastUpdateTime: Date? {
        let timestamp: Int?
        switch volumeInfo.marketState {
        case "PRE":
            timestamp = extendedHours.preMarketTime ?? metadata.regularMarketTime
        case "POST":
            timestamp = extendedHours.postMarketTime ?? metadata.regularMarketTime
        default:
            timestamp = metadata.regularMarketTime
        }
        
        guard let timestamp = timestamp else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
}