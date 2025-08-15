import Foundation

// MARK: - Yahoo Finance QuoteSummary API Response Models

/// Yahoo Finance QuoteSummary API의 최상위 응답 구조체
///
/// QuoteSummary API는 실시간 시세와 상세 정보를 제공합니다.
/// 이 구조체는 API 응답의 최상위 레벨을 나타냅니다.
///
/// ## Topics
///
/// ### 속성
/// - ``quoteSummary``
struct QuoteSummaryResponse: Codable {
    /// 실제 시세 요약 데이터를 포함하는 컨테이너
    let quoteSummary: QuoteSummary
}

/// 시세 요약 데이터 컨테이너
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
struct QuoteSummary: Codable {
    /// 시세 요약 결과 배열 (일반적으로 단일 요소)
    let result: [QuoteSummaryResult]?
    
    /// API 에러 정보
    let error: QuoteSummaryError?
}

/// QuoteSummary API 에러 정보
///
/// Yahoo Finance QuoteSummary API가 반환하는 에러 정보를 담는 구조체입니다.
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
/// let error = QuoteSummaryError(
///     code: "Not Found",
///     description: "No data found for symbol INVALID"
/// )
/// ```
struct QuoteSummaryError: Codable {
    /// 에러 코드
    let code: String
    
    /// 에러에 대한 상세 설명
    let description: String
}

/// 시세 요약 결과 데이터
///
/// 종목의 실시간 가격 정보와 요약 정보를 포함합니다.
///
/// ## Topics
///
/// ### 가격 데이터
/// - ``price``
///
/// ### 상세 정보
/// - ``summaryDetail``
///
/// ## Important
/// 모든 필드는 선택적(optional)이며, API 응답에 따라 일부만 제공될 수 있습니다.
struct QuoteSummaryResult: Codable {
    /// 실시간 가격 정보
    let price: PriceData?
    
    /// 종목 요약 상세 정보
    let summaryDetail: SummaryDetail?
}

/// 실시간 가격 데이터
///
/// Yahoo Finance에서 제공하는 실시간 및 시간외 거래 가격 정보를 포함합니다.
/// 모든 가격은 ``ValueContainer``로 래핑되어 원시값과 포맷된 문자열을 함께 제공합니다.
///
/// ## Topics
///
/// ### 기본 정보
/// - ``shortName``
///
/// ### 정규 시장 데이터
/// - ``regularMarketPrice``
/// - ``regularMarketVolume``
/// - ``regularMarketOpen``
/// - ``regularMarketDayHigh``
/// - ``regularMarketDayLow``
/// - ``regularMarketPreviousClose``
/// - ``regularMarketTime``
///
/// ### 시간외 거래
/// - ``postMarketPrice``
/// - ``postMarketTime``
/// - ``postMarketChangePercent``
/// - ``preMarketPrice``
/// - ``preMarketTime``
/// - ``preMarketChangePercent``
///
/// ### 기타
/// - ``marketCap``
///
/// ## Example
/// ```swift
/// if let price = priceData.regularMarketPrice {
///     print("현재 가격: \(price.raw)") // 150.25
///     print("포맷된 가격: \(price.fmt ?? "N/A")") // "$150.25"
/// }
/// ```
struct PriceData: Codable {
    /// 종목 약칭
    let shortName: String?
    
    /// 정규 시장 현재 가격
    let regularMarketPrice: ValueContainer<Double>?
    
    /// 정규 시장 거래량
    let regularMarketVolume: ValueContainer<Int>?
    
    /// 시가총액
    let marketCap: ValueContainer<Double>?
    
    /// 정규 시장 마감 시간 (Unix 타임스탬프)
    let regularMarketTime: ValueContainer<Int>?
    
    /// 정규 시장 시가
    let regularMarketOpen: ValueContainer<Double>?
    
    /// 정규 시장 당일 최고가
    let regularMarketDayHigh: ValueContainer<Double>?
    
    /// 정규 시장 당일 최저가
    let regularMarketDayLow: ValueContainer<Double>?
    
    /// 정규 시장 전일 종가
    let regularMarketPreviousClose: ValueContainer<Double>?
    
    /// 시간외 거래 가격 (장후)
    let postMarketPrice: ValueContainer<Double>?
    
    /// 시간외 거래 시간 (장후, Unix 타임스탬프)
    let postMarketTime: ValueContainer<Int>?
    
    /// 시간외 거래 변동률 (장후, %)
    let postMarketChangePercent: ValueContainer<Double>?
    
    /// 시간외 거래 가격 (장전)
    let preMarketPrice: ValueContainer<Double>?
    
    /// 시간외 거래 시간 (장전, Unix 타임스탬프)
    let preMarketTime: ValueContainer<Int>?
    
    /// 시간외 거래 변동률 (장전, %)
    let preMarketChangePercent: ValueContainer<Double>?
}

/// 종목 요약 상세 정보
///
/// 종목에 대한 추가적인 상세 정보를 포함합니다.
/// 현재는 기본 구조만 정의되어 있으며, 필요에 따라 필드가 추가될 수 있습니다.
///
/// ## Note
/// 이 구조체는 확장 가능하도록 설계되었습니다.
/// 향후 Yahoo Finance API의 추가 데이터 포인트를 지원할 수 있습니다.
struct SummaryDetail: Codable {
    // 필요시 추가 필드들
}

/// 값과 포맷된 문자열을 함께 보관하는 제네릭 컨테이너
///
/// Yahoo Finance API는 숫자 데이터를 원시값과 함께
/// 사람이 읽기 쉬운 포맷된 문자열로도 제공합니다.
/// 이 컨테이너는 두 값을 모두 보존합니다.
///
/// ## Type Parameters
/// - `T`: 원시 데이터의 타입 (Double, Int 등)
///
/// ## Topics
///
/// ### 속성
/// - ``raw``
/// - ``fmt``
///
/// ## Example
/// ```swift
/// // API 응답에서 가격 데이터
/// let priceContainer = ValueContainer<Double>(
///     raw: 150.25,
///     fmt: "$150.25"
/// )
///
/// // 계산에는 raw 값 사용
/// let change = priceContainer.raw - previousPrice
///
/// // 표시에는 포맷된 값 사용
/// print("현재 가격: \(priceContainer.fmt ?? "N/A")")
/// ```
struct ValueContainer<T: Codable>: Codable {
    /// 원시 데이터 값 (계산에 사용)
    let raw: T
    
    /// 포맷된 문자열 (표시용, 옵셔널)
    let fmt: String?
}