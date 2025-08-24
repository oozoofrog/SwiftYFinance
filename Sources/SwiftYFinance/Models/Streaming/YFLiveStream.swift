import Foundation

/// Yahoo Finance Live Stream 메시지 타입
/// 
/// WebSocket을 통해 수신되는 실시간 가격 데이터의 메시지 구조를 정의합니다.
public struct YFLiveStreamMessage: Sendable {
    /// 심볼 (예: "AAPL", "BTC-USD")
    public let symbol: String?
    
    /// 현재 가격
    public let price: Double?
    
    /// 가격 변동
    public let change: Double?
    
    /// 가격 변동률 (%)
    public let changePercent: Double?
    
    /// 거래량
    public let volume: Int64?
    
    /// 시장 상태 (예: "REGULAR", "PRE", "POST")
    public let marketState: String?
    
    /// 마지막 거래 시간 (Unix 타임스탬프)
    public let lastTradeTime: Int64?
    
    /// 일중 최고가
    public let dayHigh: Double?
    
    /// 일중 최저가
    public let dayLow: Double?
    
    /// 원시 메시지 (디버깅용)
    public let raw: [String: Sendable]?
    
    /// 에러 메시지 (파싱 실패 시)
    public let error: String?
    
    public init(
        symbol: String? = nil,
        price: Double? = nil,
        change: Double? = nil,
        changePercent: Double? = nil,
        volume: Int64? = nil,
        marketState: String? = nil,
        lastTradeTime: Int64? = nil,
        dayHigh: Double? = nil,
        dayLow: Double? = nil,
        raw: [String: Sendable]? = nil,
        error: String? = nil
    ) {
        self.symbol = symbol
        self.price = price
        self.change = change
        self.changePercent = changePercent
        self.volume = volume
        self.marketState = marketState
        self.lastTradeTime = lastTradeTime
        self.dayHigh = dayHigh
        self.dayLow = dayLow
        self.raw = raw
        self.error = error
    }
}

/// WebSocket 구독 상태
/// 
/// 구독된 심볼들의 상태를 관리합니다.
public struct YFSubscription: Sendable {
    /// 구독된 심볼들
    public let symbols: Set<String>
    
    /// 구독 시작 시간
    public let subscribedAt: Date
    
    public init(symbols: Set<String>, subscribedAt: Date = Date()) {
        self.symbols = symbols
        self.subscribedAt = subscribedAt
    }
    
    /// 새 심볼 추가
    public func adding(_ newSymbols: [String]) -> YFSubscription {
        var updatedSymbols = self.symbols
        updatedSymbols.formUnion(newSymbols)
        return YFSubscription(symbols: updatedSymbols, subscribedAt: self.subscribedAt)
    }
    
    /// 심볼 제거
    public func removing(_ symbolsToRemove: [String]) -> YFSubscription {
        var updatedSymbols = self.symbols
        updatedSymbols.subtract(symbolsToRemove)
        return YFSubscription(symbols: updatedSymbols, subscribedAt: self.subscribedAt)
    }
}

/// WebSocket 연결 상태
public enum YFWebSocketState: Sendable, Equatable {
    /// 연결되지 않음
    case disconnected
    /// 연결 중
    case connecting
    /// 연결됨
    case connected
    /// 에러 발생
    case error(String)
    
    public static func == (lhs: YFWebSocketState, rhs: YFWebSocketState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected), (.connecting, .connecting), (.connected, .connected):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

/// WebSocket 메시지 핸들러
/// 
/// 실시간 데이터를 받을 때 호출되는 핸들러 타입입니다.
public typealias YFLiveStreamHandler = @Sendable (YFLiveStreamMessage) -> Void

/// WebSocket 상태 변경 핸들러
/// 
/// 연결 상태가 변경될 때 호출되는 핸들러 타입입니다.
public typealias YFWebSocketStateHandler = @Sendable (YFWebSocketState) -> Void