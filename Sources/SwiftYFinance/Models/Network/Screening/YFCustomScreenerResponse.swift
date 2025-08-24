import Foundation

/// Yahoo Finance Custom Screener API 응답 모델
///
/// Custom Screener API의 JSON 응답 구조를 파싱하기 위한 모델입니다.
/// 실제 API 응답에 맞춰 구조를 정의하며, 추후 JSON 파일 생성을 통해 개선될 예정입니다.
public struct YFCustomScreenerResponse: Codable, Sendable {
    /// Finance 응답 컨테이너
    public let finance: YFCustomScreenerFinanceContainer?
    
    /// 에러 정보 (있는 경우)
    public let error: YFCustomScreenerError?
    
    enum CodingKeys: String, CodingKey {
        case finance
        case error
    }
}

/// Custom Screener API Finance 컨테이너
public struct YFCustomScreenerFinanceContainer: Codable, Sendable {
    /// 스크리너 결과 배열
    public let result: [YFCustomScreenerResultContainer]?
    
    /// API 에러 정보
    public let error: YFCustomScreenerError?
    
    enum CodingKeys: String, CodingKey {
        case result
        case error
    }
}

/// 커스텀 스크리너 결과 컨테이너
public struct YFCustomScreenerResultContainer: Codable, Sendable {
    /// 스크리너 ID
    public let id: String?
    
    /// 제목
    public let title: String?
    
    /// 설명
    public let description: String?
    
    /// 총 결과 개수
    public let total: Int?
    
    /// 시작 인덱스
    public let start: Int?
    
    /// 결과 개수
    public let count: Int?
    
    /// 검색 결과 배열
    public let quotes: [YFCustomScreenerResult]?
    
    /// 기준 정보
    public let criteria: YFCustomScreenerCriteria?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case total
        case start
        case count
        case quotes
        case criteria
    }
}

/// 개별 커스텀 스크리너 결과 모델
public struct YFCustomScreenerResult: Codable, Sendable {
    /// 심볼
    public let symbol: String?
    
    /// 회사명
    public let shortName: String?
    
    /// 긴 회사명
    public let longName: String?
    
    /// 현재 가격
    public let regularMarketPrice: Double?
    
    /// 가격 변화
    public let regularMarketChange: Double?
    
    /// 가격 변화율 (%)
    public let regularMarketChangePercent: Double?
    
    /// 시가총액
    public let marketCap: Double?
    
    /// P/E 비율
    public let trailingPE: Double?
    
    /// 거래량
    public let regularMarketVolume: Int?
    
    /// 평균 거래량
    public let averageVolume: Int?
    
    /// 52주 최고가
    public let fiftyTwoWeekHigh: Double?
    
    /// 52주 최저가
    public let fiftyTwoWeekLow: Double?
    
    /// 섹터
    public let sector: String?
    
    /// 산업
    public let industry: String?
    
    /// 거래소
    public let exchange: String?
    
    /// 통화
    public let currency: String?
    
    /// EPS (주당순이익)
    public let trailingEps: Double?
    
    /// Forward P/E
    public let forwardPE: Double?
    
    /// PEG 비율
    public let pegRatio: Double?
    
    /// Price to Book
    public let priceToBook: Double?
    
    /// ROE (자기자본이익률)
    public let returnOnEquity: Double?
    
    /// 수익 성장률
    public let earningsQuarterlyGrowth: Double?
    
    /// 배당 수익률
    public let dividendYield: Double?
    
    /// Beta
    public let beta: Double?
    
    enum CodingKeys: String, CodingKey {
        case symbol
        case shortName
        case longName
        case regularMarketPrice
        case regularMarketChange
        case regularMarketChangePercent
        case marketCap
        case trailingPE
        case regularMarketVolume
        case averageVolume
        case fiftyTwoWeekHigh
        case fiftyTwoWeekLow
        case sector
        case industry
        case exchange
        case currency
        case trailingEps
        case forwardPE
        case pegRatio
        case priceToBook
        case returnOnEquity
        case earningsQuarterlyGrowth
        case dividendYield
        case beta
    }
}

/// 커스텀 스크리너 기준 정보
public struct YFCustomScreenerCriteria: Codable, Sendable {
    /// 원본 쿼리
    public let rawCriteria: String?
    
    /// 필터 개수
    public let size: Int?
    
    /// 오프셋
    public let offset: Int?
    
    /// 정렬 필드
    public let sortField: String?
    
    /// 정렬 타입
    public let sortType: String?
    
    /// Quote 타입
    public let quoteType: String?
    
    /// Top 연산자
    public let topOperator: String?
    
    /// 조건 목록
    public let criteria: [YFCustomScreenerCriterion]?
    
    enum CodingKeys: String, CodingKey {
        case rawCriteria
        case size
        case offset
        case sortField
        case sortType
        case quoteType
        case topOperator
        case criteria
    }
}

/// 개별 스크리너 조건
public struct YFCustomScreenerCriterion: Codable, Sendable {
    /// 필드명
    public let field: String?
    
    /// 연산자 목록
    public let operators: [String]?
    
    /// 값 목록
    public let values: [Double]?
    
    /// 레이블 선택
    public let labelsSelected: [Int]?
    
    /// 종속 값들
    public let dependentValues: [String]?
    
    enum CodingKeys: String, CodingKey {
        case field
        case `operators`
        case values
        case labelsSelected
        case dependentValues
    }
}

/// Custom Screener API 에러 모델
public struct YFCustomScreenerError: Codable, Sendable {
    /// 에러 코드
    public let code: String?
    
    /// 에러 메시지
    public let description: String?
    
    enum CodingKeys: String, CodingKey {
        case code
        case description
    }
}