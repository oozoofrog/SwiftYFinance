import Foundation

/// 기술적 지표 기본 프로토콜
public protocol YFTechnicalIndicatorProtocol: Sendable {
    var ticker: YFTicker { get }
    var indicator: YFIndicatorType { get }
    var calculationDate: Date { get }
    var signal: YFTechnicalSignal { get }
    var period: Int { get }
}

/// 기술적 지표 유형
public enum YFIndicatorType: String, CaseIterable, Sendable {
    case sma = "SMA"                    // Simple Moving Average
    case ema = "EMA"                    // Exponential Moving Average
    case rsi = "RSI"                    // Relative Strength Index
    case macd = "MACD"                  // Moving Average Convergence Divergence
    case bollingerBands = "BB"          // Bollinger Bands
    case stochastic = "STOCH"           // Stochastic Oscillator
    case williams = "WILLIAMS"          // Williams %R
    case momentum = "MOM"               // Momentum
    case roc = "ROC"                    // Rate of Change
    case atr = "ATR"                    // Average True Range
    
    /// 지표 설명
    public var description: String {
        switch self {
        case .sma: return "단순이동평균"
        case .ema: return "지수이동평균"
        case .rsi: return "상대강도지수"
        case .macd: return "MACD"
        case .bollingerBands: return "볼린저 밴드"
        case .stochastic: return "스토캐스틱"
        case .williams: return "윌리엄스 %R"
        case .momentum: return "모멘텀"
        case .roc: return "변화율"
        case .atr: return "평균진폭"
        }
    }
    
    /// 지표 카테고리
    public var category: YFIndicatorCategory {
        switch self {
        case .sma, .ema, .bollingerBands:
            return .trend
        case .rsi, .stochastic, .williams:
            return .momentum
        case .macd, .momentum, .roc:
            return .momentum
        case .atr:
            return .volatility
        }
    }
}

/// 기술적 지표 카테고리
public enum YFIndicatorCategory: String, CaseIterable, Sendable {
    case trend = "trend"                // 추세 지표
    case momentum = "momentum"          // 모멘텀 지표  
    case volatility = "volatility"      // 변동성 지표
    case volume = "volume"              // 거래량 지표
    
    public var description: String {
        switch self {
        case .trend: return "추세"
        case .momentum: return "모멘텀"
        case .volatility: return "변동성"
        case .volume: return "거래량"
        }
    }
}

/// 기술적 신호
public enum YFTechnicalSignal: String, CaseIterable, Sendable {
    case buy = "BUY"                    // 매수 신호
    case sell = "SELL"                  // 매도 신호
    case hold = "HOLD"                  // 보유 신호
    case strongBuy = "STRONG_BUY"       // 강력 매수
    case strongSell = "STRONG_SELL"     // 강력 매도
    
    /// 신호 강도 (0.0 ~ 1.0)
    public var strength: Double {
        switch self {
        case .strongBuy: return 1.0
        case .buy: return 0.7
        case .hold: return 0.5
        case .sell: return 0.3
        case .strongSell: return 0.0
        }
    }
    
    public var description: String {
        switch self {
        case .buy: return "매수"
        case .sell: return "매도"
        case .hold: return "보유"
        case .strongBuy: return "강력매수"
        case .strongSell: return "강력매도"
        }
    }
}

/// 단순/지수 이동평균
public struct YFMovingAverage: YFTechnicalIndicatorProtocol {
    public let ticker: YFTicker
    public let indicator: YFIndicatorType
    public let period: Int
    public let values: [YFIndicatorValue]
    public let calculationDate: Date
    public let signal: YFTechnicalSignal
    
    public init(
        ticker: YFTicker,
        indicator: YFIndicatorType,
        period: Int,
        values: [YFIndicatorValue],
        calculationDate: Date = Date(),
        signal: YFTechnicalSignal = .hold
    ) {
        self.ticker = ticker
        self.indicator = indicator
        self.period = period
        self.values = values
        self.calculationDate = calculationDate
        self.signal = signal
    }
}

/// RSI (상대강도지수)
public struct YFRelativeStrengthIndex: YFTechnicalIndicatorProtocol {
    public let ticker: YFTicker
    public let indicator: YFIndicatorType = .rsi
    public let period: Int
    public let values: [YFIndicatorValue]
    public let calculationDate: Date
    public let signal: YFTechnicalSignal
    public let overboughtLevel: Double = 70.0
    public let oversoldLevel: Double = 30.0
    
    public init(
        ticker: YFTicker,
        period: Int,
        values: [YFIndicatorValue],
        calculationDate: Date = Date(),
        signal: YFTechnicalSignal = .hold
    ) {
        self.ticker = ticker
        self.period = period
        self.values = values
        self.calculationDate = calculationDate
        self.signal = signal
    }
}

/// MACD
public struct YFMacdIndicator: YFTechnicalIndicatorProtocol {
    public let ticker: YFTicker
    public let indicator: YFIndicatorType = .macd
    public let period: Int = 0 // MACD는 복합 기간 사용
    public let fastPeriod: Int
    public let slowPeriod: Int
    public let signalPeriod: Int
    public let values: [YFMacdValue]
    public let calculationDate: Date
    public let signal: YFTechnicalSignal
    
    public init(
        ticker: YFTicker,
        fastPeriod: Int,
        slowPeriod: Int,
        signalPeriod: Int,
        values: [YFMacdValue],
        calculationDate: Date = Date(),
        signal: YFTechnicalSignal = .hold
    ) {
        self.ticker = ticker
        self.fastPeriod = fastPeriod
        self.slowPeriod = slowPeriod
        self.signalPeriod = signalPeriod
        self.values = values
        self.calculationDate = calculationDate
        self.signal = signal
    }
}

/// 볼린저 밴드
public struct YFBollingerBands: YFTechnicalIndicatorProtocol {
    public let ticker: YFTicker
    public let indicator: YFIndicatorType = .bollingerBands
    public let period: Int
    public let standardDeviation: Double
    public let values: [YFBollingerValue]
    public let calculationDate: Date
    public let signal: YFTechnicalSignal
    
    public init(
        ticker: YFTicker,
        period: Int,
        standardDeviation: Double,
        values: [YFBollingerValue],
        calculationDate: Date = Date(),
        signal: YFTechnicalSignal = .hold
    ) {
        self.ticker = ticker
        self.period = period
        self.standardDeviation = standardDeviation
        self.values = values
        self.calculationDate = calculationDate
        self.signal = signal
    }
}

/// 스토캐스틱
public struct YFStochasticOscillator: YFTechnicalIndicatorProtocol {
    public let ticker: YFTicker
    public let indicator: YFIndicatorType = .stochastic
    public let period: Int = 0 // 복합 기간
    public let kPeriod: Int
    public let dPeriod: Int
    public let values: [YFStochasticValue]
    public let calculationDate: Date
    public let signal: YFTechnicalSignal
    public let overboughtLevel: Double = 80.0
    public let oversoldLevel: Double = 20.0
    
    public init(
        ticker: YFTicker,
        kPeriod: Int,
        dPeriod: Int,
        values: [YFStochasticValue],
        calculationDate: Date = Date(),
        signal: YFTechnicalSignal = .hold
    ) {
        self.ticker = ticker
        self.kPeriod = kPeriod
        self.dPeriod = dPeriod
        self.values = values
        self.calculationDate = calculationDate
        self.signal = signal
    }
}

/// 기본 지표 값
public struct YFIndicatorValue: Sendable {
    public let date: Date
    public let value: Double
    
    public init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
}

/// MACD 값
public struct YFMacdValue: Sendable {
    public let date: Date
    public let macdLine: Double        // MACD 라인
    public let signalLine: Double      // Signal 라인
    public let histogram: Double       // Histogram (MACD - Signal)
    
    public init(date: Date, macdLine: Double, signalLine: Double, histogram: Double) {
        self.date = date
        self.macdLine = macdLine
        self.signalLine = signalLine
        self.histogram = histogram
    }
}

/// 볼린저 밴드 값
public struct YFBollingerValue: Sendable {
    public let date: Date
    public let upperBand: Double       // 상단 밴드
    public let middleBand: Double      // 중간 밴드 (이동평균)
    public let lowerBand: Double       // 하단 밴드
    public let bandwidth: Double       // 밴드폭
    public let percentB: Double        // %B (가격의 밴드 내 위치)
    
    public init(
        date: Date,
        upperBand: Double,
        middleBand: Double,
        lowerBand: Double,
        bandwidth: Double,
        percentB: Double
    ) {
        self.date = date
        self.upperBand = upperBand
        self.middleBand = middleBand
        self.lowerBand = lowerBand
        self.bandwidth = bandwidth
        self.percentB = percentB
    }
}

/// 스토캐스틱 값
public struct YFStochasticValue: Sendable {
    public let date: Date
    public let percentK: Double        // %K
    public let percentD: Double        // %D
    
    public init(date: Date, percentK: Double, percentD: Double) {
        self.date = date
        self.percentK = percentK
        self.percentD = percentD
    }
}

/// 기술적 지표 요청 정의
public enum YFIndicatorRequest: Sendable {
    case sma(period: Int)
    case ema(period: Int)
    case rsi(period: Int)
    case macd(fast: Int, slow: Int, signal: Int)
    case bollingerBands(period: Int, stdDev: Double)
    case stochastic(kPeriod: Int, dPeriod: Int)
    
    public var type: YFIndicatorType {
        switch self {
        case .sma: return .sma
        case .ema: return .ema
        case .rsi: return .rsi
        case .macd: return .macd
        case .bollingerBands: return .bollingerBands
        case .stochastic: return .stochastic
        }
    }
}

/// 종합 기술적 신호 분석
public struct YFTechnicalSignals: Sendable {
    public let ticker: YFTicker
    public let analysisDate: Date
    public let indicators: [YFIndicatorSignal]
    public let overallSignal: YFTechnicalSignal
    public let confidence: Double
    public let recommendation: String
    
    public init(
        ticker: YFTicker,
        analysisDate: Date = Date(),
        indicators: [YFIndicatorSignal],
        overallSignal: YFTechnicalSignal,
        confidence: Double,
        recommendation: String
    ) {
        self.ticker = ticker
        self.analysisDate = analysisDate
        self.indicators = indicators
        self.overallSignal = overallSignal
        self.confidence = confidence
        self.recommendation = recommendation
    }
}

/// 개별 지표 신호
public struct YFIndicatorSignal: Sendable {
    public let indicator: YFIndicatorType
    public let signal: YFTechnicalSignal
    public let strength: Double        // 신호 강도 (0.0 ~ 1.0)
    public let currentValue: Double?   // 현재 지표 값
    public let description: String
    
    public init(
        indicator: YFIndicatorType,
        signal: YFTechnicalSignal,
        strength: Double,
        currentValue: Double? = nil,
        description: String = ""
    ) {
        self.indicator = indicator
        self.signal = signal
        self.strength = strength
        self.currentValue = currentValue
        self.description = description.isEmpty ? indicator.description : description
    }
}

/// 일반 기술적 지표 (타입별로 다른 구조체 통합)
public struct YFTechnicalIndicator: Sendable {
    public let ticker: YFTicker
    public let indicator: YFIndicatorType
    public let period: Int
    public let values: [YFIndicatorValue]
    public let calculationDate: Date
    public let signal: YFTechnicalSignal
    
    // MACD 전용 필드
    public let fastPeriod: Int?
    public let slowPeriod: Int?
    public let signalPeriod: Int?
    public let macdValues: [YFMacdValue]?
    
    // 볼린저 밴드 전용 필드
    public let standardDeviation: Double?
    public let bollingerValues: [YFBollingerValue]?
    
    // 스토캐스틱 전용 필드
    public let kPeriod: Int?
    public let dPeriod: Int?
    public let stochasticValues: [YFStochasticValue]?
    
    public init(
        ticker: YFTicker,
        indicator: YFIndicatorType,
        period: Int,
        values: [YFIndicatorValue] = [],
        calculationDate: Date = Date(),
        signal: YFTechnicalSignal = .hold,
        
        // MACD
        fastPeriod: Int? = nil,
        slowPeriod: Int? = nil,
        signalPeriod: Int? = nil,
        macdValues: [YFMacdValue]? = nil,
        
        // 볼린저 밴드
        standardDeviation: Double? = nil,
        bollingerValues: [YFBollingerValue]? = nil,
        
        // 스토캐스틱
        kPeriod: Int? = nil,
        dPeriod: Int? = nil,
        stochasticValues: [YFStochasticValue]? = nil
    ) {
        self.ticker = ticker
        self.indicator = indicator
        self.period = period
        self.values = values
        self.calculationDate = calculationDate
        self.signal = signal
        
        self.fastPeriod = fastPeriod
        self.slowPeriod = slowPeriod
        self.signalPeriod = signalPeriod
        self.macdValues = macdValues
        
        self.standardDeviation = standardDeviation
        self.bollingerValues = bollingerValues
        
        self.kPeriod = kPeriod
        self.dPeriod = dPeriod
        self.stochasticValues = stochasticValues
    }
}