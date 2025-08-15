import Foundation

// MARK: - Yahoo Finance Chart API Response Models

/// Yahoo Finance Chart API의 최상위 응답 구조체
///
/// Chart API는 주식의 과거 가격 데이터를 시계열 형태로 제공합니다.
/// 이 구조체는 API 응답의 최상위 레벨을 나타냅니다.
///
/// ## Topics
///
/// ### 속성
/// - ``chart``
struct ChartResponse: Codable {
    /// 차트 데이터를 포함하는 컨테이너
    let chart: Chart
}

/// 차트 데이터 컨테이너
///
/// 성공 시 결과 배열을, 실패 시 에러 정보를 포함합니다.
///
/// ## Topics
///
/// ### 속성
/// - ``result``
/// - ``error``
///
/// ## Note
/// `result`와 `error`는 상호 배타적입니다.
/// 성공 시에는 `result`가, 실패 시에는 `error`가 값을 가집니다.
struct Chart: Codable {
    /// 차트 결과 배열 (일반적으로 단일 요소)
    let result: [ChartResult]?
    
    /// API 에러 정보
    let error: ChartError?
}

/// Chart API 에러 정보
///
/// Yahoo Finance Chart API가 반환하는 에러 정보를 담는 구조체입니다.
///
/// ## Topics
///
/// ### 속성
/// - ``code``
/// - ``description``
///
/// ## Example
/// ```swift
/// // 에러 응답 예시
/// let error = ChartError(
///     code: "Not Found",
///     description: "No data found for symbol INVALID"
/// )
/// ```
struct ChartError: Codable {
    /// 에러 코드
    let code: String
    
    /// 에러에 대한 상세 설명
    let description: String
}

/// 차트 데이터 결과
///
/// 실제 가격 데이터와 메타데이터를 포함하는 구조체입니다.
///
/// ## Topics
///
/// ### 메타데이터
/// - ``meta``
///
/// ### 시계열 데이터
/// - ``timestamp``
/// - ``indicators``
///
/// ## Important
/// `timestamp` 배열의 각 요소는 Unix 타임스탬프(초 단위)이며,
/// `indicators` 내의 가격 데이터 배열과 1:1 대응됩니다.
struct ChartResult: Codable {
    /// 차트 메타데이터 (심볼, 거래소, 통화 등)
    let meta: ChartMeta
    
    /// Unix 타임스탬프 배열 (초 단위)
    let timestamp: [Int]?
    
    /// 가격 지표 데이터
    let indicators: ChartIndicators
}

/// 차트 메타데이터
///
/// 종목의 기본 정보와 현재 시장 데이터를 포함합니다.
///
/// ## Topics
///
/// ### 종목 정보
/// - ``symbol``
/// - ``longName``
/// - ``shortName``
/// - ``instrumentType``
///
/// ### 거래소 정보
/// - ``exchangeName``
/// - ``fullExchangeName``
/// - ``exchangeTimezoneName``
/// - ``timezone``
/// - ``gmtoffset``
///
/// ### 시장 데이터
/// - ``regularMarketPrice``
/// - ``regularMarketDayHigh``
/// - ``regularMarketDayLow``
/// - ``regularMarketVolume``
/// - ``fiftyTwoWeekHigh``
/// - ``fiftyTwoWeekLow``
///
/// ### 기타 정보
/// - ``currency``
/// - ``firstTradeDate``
/// - ``regularMarketTime``
/// - ``hasPrePostMarketData``
/// - ``priceHint``
/// - ``validRanges``
struct ChartMeta: Codable {
    /// 거래 통화 (예: "USD", "KRW")
    let currency: String?
    
    /// 종목 심볼
    let symbol: String
    
    /// 거래소 약칭
    let exchangeName: String?
    
    /// 거래소 전체 이름
    let fullExchangeName: String?
    
    /// 금융 상품 유형 (예: "EQUITY", "ETF")
    let instrumentType: String?
    
    /// 최초 거래일 (Unix 타임스탬프)
    let firstTradeDate: Int?
    
    /// 정규 시장 마감 시간 (Unix 타임스탬프)
    let regularMarketTime: Int?
    
    /// 시간외 거래 데이터 제공 여부
    let hasPrePostMarketData: Bool?
    
    /// GMT 오프셋 (초 단위)
    let gmtoffset: Int?
    
    /// 시간대 (예: "EST")
    let timezone: String?
    
    /// 거래소 시간대 이름 (예: "America/New_York")
    let exchangeTimezoneName: String?
    
    /// 현재 정규 시장 가격
    let regularMarketPrice: Double?
    
    /// 52주 최고가
    let fiftyTwoWeekHigh: Double?
    
    /// 52주 최저가
    let fiftyTwoWeekLow: Double?
    
    /// 당일 최고가
    let regularMarketDayHigh: Double?
    
    /// 당일 최저가
    let regularMarketDayLow: Double?
    
    /// 당일 거래량
    let regularMarketVolume: Int?
    
    /// 회사 전체 이름
    let longName: String?
    
    /// 회사 약칭
    let shortName: String?
    
    /// 가격 표시 소수점 자릿수
    let priceHint: Int?
    
    /// 유효한 기간 범위 (예: ["1d", "5d", "1mo"])
    let validRanges: [String]?
}

/// 차트 지표 데이터
///
/// OHLCV(Open, High, Low, Close, Volume) 데이터와
/// 조정 종가를 포함합니다.
///
/// ## Topics
///
/// ### 가격 데이터
/// - ``quote``
/// - ``adjclose``
///
/// ## Note
/// 배당과 주식 분할을 반영한 조정 종가는 선택적으로 제공됩니다.
struct ChartIndicators: Codable {
    /// OHLCV 데이터 배열
    let quote: [ChartQuote]
    
    /// 조정 종가 데이터 (선택적)
    let adjclose: [ChartAdjClose]?
}

/// OHLCV (Open, High, Low, Close, Volume) 데이터
///
/// 시계열 가격 데이터를 배열 형태로 저장합니다.
/// 각 배열의 동일한 인덱스가 같은 시점의 데이터를 나타냅니다.
///
/// ## Topics
///
/// ### 가격 데이터
/// - ``open``
/// - ``high``
/// - ``low``
/// - ``close``
///
/// ### 거래량
/// - ``volume``
///
/// ## Important
/// null 값은 -1.0 (가격) 또는 -1 (거래량)으로 변환됩니다.
/// 이는 휴장일이나 데이터가 없는 시점을 나타냅니다.
///
/// ## Example
/// ```swift
/// // 3일간의 OHLCV 데이터
/// let quote = ChartQuote(
///     open: [150.0, 151.5, 149.0],
///     high: [152.0, 153.0, 151.0],
///     low: [149.5, 150.0, 148.5],
///     close: [151.0, 150.5, 150.0],
///     volume: [1000000, 1200000, 950000]
/// )
/// ```
struct ChartQuote: Codable {
    /// 시가 배열
    let open: [Double]
    
    /// 고가 배열
    let high: [Double]
    
    /// 저가 배열
    let low: [Double]
    
    /// 종가 배열
    let close: [Double]
    
    /// 거래량 배열
    let volume: [Int]
    
    /// 커스텀 디코더 초기화
    ///
    /// Yahoo Finance API는 데이터가 없는 경우 null을 반환합니다.
    /// 이 초기화 메서드는 null 값을 -1.0 또는 -1로 변환합니다.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // null 값을 -1.0으로 처리
        let openOptional = try container.decode([Double?].self, forKey: .open)
        self.open = openOptional.map { $0 ?? -1.0 }
        
        let highOptional = try container.decode([Double?].self, forKey: .high)
        self.high = highOptional.map { $0 ?? -1.0 }
        
        let lowOptional = try container.decode([Double?].self, forKey: .low)
        self.low = lowOptional.map { $0 ?? -1.0 }
        
        let closeOptional = try container.decode([Double?].self, forKey: .close)
        self.close = closeOptional.map { $0 ?? -1.0 }
        
        let volumeOptional = try container.decode([Int?].self, forKey: .volume)
        self.volume = volumeOptional.map { $0 ?? -1 }
    }
}

/// 조정 종가 데이터
///
/// 배당과 주식 분할을 반영한 조정된 종가를 포함합니다.
/// 과거 수익률을 정확하게 계산하는 데 사용됩니다.
///
/// ## Topics
///
/// ### 속성
/// - ``adjclose``
///
/// ## Important
/// 조정 종가는 실제 거래 가격과 다를 수 있습니다.
/// 배당금과 주식 분할의 영향을 제거하여 시간에 따른
/// 실제 수익률을 반영합니다.
///
/// ## Example
/// ```swift
/// // 주식 분할 전후의 조정 종가
/// let adjClose = ChartAdjClose(
///     adjclose: [75.0, 76.0, 150.0, 152.0] // 2:1 분할 반영
/// )
/// ```
struct ChartAdjClose: Codable {
    /// 조정 종가 배열
    let adjclose: [Double]
    
    /// 커스텀 디코더 초기화
    ///
    /// null 값을 -1.0으로 변환하여 처리합니다.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // null 값을 -1.0으로 처리
        let adjcloseOptional = try container.decode([Double?].self, forKey: .adjclose)
        self.adjclose = adjcloseOptional.map { $0 ?? -1.0 }
    }
}