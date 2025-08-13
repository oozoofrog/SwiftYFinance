import Foundation

/// Yahoo Finance 뉴스 기사 모델
///
/// 종목 관련 뉴스, 보도자료, 분석 리포트 등의 정보를 담는 구조체입니다.
/// Python yfinance의 news API를 참조하여 구현되었습니다.
///
/// ## 사용 예시
/// ```swift
/// let news = try await client.fetchNews(ticker: ticker)
/// for article in news {
///     print("제목: \(article.title)")
///     print("요약: \(article.summary)")
///     print("감성: \(article.sentiment?.classification ?? .neutral)")
/// }
/// ```
public struct YFNewsArticle: Sendable {
    /// 뉴스 기사 제목
    public let title: String
    /// 뉴스 기사 요약/내용
    public let summary: String
    /// 기사 전문 링크
    public let link: String
    /// 발행 일시
    public let publishedDate: Date
    /// 뉴스 소스 (Reuters, Bloomberg 등)
    public let source: String
    /// 기사 카테고리
    public let category: YFNewsCategory
    /// 속보 여부
    public let isBreaking: Bool
    
    // 선택적 정보
    /// 기사 대표 이미지 URL
    public let imageURL: String?
    /// 이미지 메타데이터
    public let imageInfo: YFNewsImageInfo?
    /// 감성 분석 결과
    public let sentiment: YFNewsSentiment?
    /// 관련 종목들
    public let relatedTickers: [YFTicker]
    /// 뉴스 태그들
    public let tags: [String]
    
    public init(
        title: String,
        summary: String,
        link: String,
        publishedDate: Date,
        source: String,
        category: YFNewsCategory = .general,
        isBreaking: Bool = false,
        imageURL: String? = nil,
        imageInfo: YFNewsImageInfo? = nil,
        sentiment: YFNewsSentiment? = nil,
        relatedTickers: [YFTicker] = [],
        tags: [String] = []
    ) {
        self.title = title
        self.summary = summary
        self.link = link
        self.publishedDate = publishedDate
        self.source = source
        self.category = category
        self.isBreaking = isBreaking
        self.imageURL = imageURL
        self.imageInfo = imageInfo
        self.sentiment = sentiment
        self.relatedTickers = relatedTickers
        self.tags = tags
    }
}

/// 뉴스 카테고리
public enum YFNewsCategory: String, CaseIterable, Sendable {
    case breaking = "breaking"        // 속보
    case earnings = "earnings"        // 실적 관련
    case general = "general"          // 일반 뉴스
    case pressRelease = "press_release" // 보도자료
    case analyst = "analyst"          // 애널리스트 리포트
    case insider = "insider"          // 내부자 거래
    case merger = "merger"            // 인수합병
    case dividend = "dividend"        // 배당 관련
    case regulatory = "regulatory"    // 규제 관련
    
    /// 카테고리 설명
    public var description: String {
        switch self {
        case .breaking: return "속보"
        case .earnings: return "실적 발표"
        case .general: return "일반 뉴스"
        case .pressRelease: return "보도자료"
        case .analyst: return "애널리스트 리포트"
        case .insider: return "내부자 거래"
        case .merger: return "인수합병"
        case .dividend: return "배당"
        case .regulatory: return "규제"
        }
    }
}

/// 뉴스 조회 카테고리 (API 요청용)
public enum YFNewsRequestCategory: String {
    case all = "all"                  // 모든 뉴스
    case news = "news"                // 최신 뉴스
    case pressReleases = "press releases" // 보도자료만
    
    /// Yahoo API queryRef 매핑
    var queryRef: String {
        switch self {
        case .all: return "newsAll"
        case .news: return "latestNews"
        case .pressReleases: return "pressRelease"
        }
    }
}

/// 뉴스 이미지 정보
public struct YFNewsImageInfo: Sendable {
    /// 이미지 너비 (픽셀)
    public let width: Int
    /// 이미지 높이 (픽셀)
    public let height: Int
    /// 이미지 설명/Alt 텍스트
    public let altText: String?
    /// 이미지 저작권 정보
    public let copyright: String?
    
    public init(width: Int, height: Int, altText: String? = nil, copyright: String? = nil) {
        self.width = width
        self.height = height
        self.altText = altText
        self.copyright = copyright
    }
}

/// 뉴스 감성 분석 결과
public struct YFNewsSentiment: Sendable {
    /// 감성 점수 (-1.0: 매우 부정적, 0.0: 중립, 1.0: 매우 긍정적)
    public let score: Double
    /// 감성 분류
    public let classification: YFSentimentClassification
    /// 신뢰도 (0.0 ~ 1.0)
    public let confidence: Double
    /// 키워드 감성 분석
    public let keywords: [YFSentimentKeyword]
    
    public init(
        score: Double,
        classification: YFSentimentClassification,
        confidence: Double,
        keywords: [YFSentimentKeyword] = []
    ) {
        self.score = score
        self.classification = classification
        self.confidence = confidence
        self.keywords = keywords
    }
}

/// 감성 분류
public enum YFSentimentClassification: String, CaseIterable, Sendable {
    case positive = "positive"   // 긍정적
    case negative = "negative"   // 부정적
    case neutral = "neutral"     // 중립
    
    /// 분류 설명
    public var description: String {
        switch self {
        case .positive: return "긍정적"
        case .negative: return "부정적"
        case .neutral: return "중립"
        }
    }
    
    /// 점수 범위에서 분류 결정
    static func from(score: Double) -> YFSentimentClassification {
        if score > 0.1 {
            return .positive
        } else if score < -0.1 {
            return .negative
        } else {
            return .neutral
        }
    }
}

/// 키워드별 감성 분석
public struct YFSentimentKeyword: Sendable {
    /// 키워드
    public let keyword: String
    /// 키워드 감성 점수
    public let score: Double
    /// 키워드 빈도
    public let frequency: Int
    
    public init(keyword: String, score: Double, frequency: Int) {
        self.keyword = keyword
        self.score = score
        self.frequency = frequency
    }
}

/// 뉴스 필터 옵션
public struct YFNewsFilter {
    /// 시작 날짜
    public let fromDate: Date?
    /// 종료 날짜
    public let toDate: Date?
    /// 뉴스 카테고리
    public let categories: [YFNewsCategory]
    /// 최소 감성 점수
    public let minSentimentScore: Double?
    /// 최대 감성 점수
    public let maxSentimentScore: Double?
    /// 특정 소스만 포함
    public let includeSources: [String]
    /// 특정 소스 제외
    public let excludeSources: [String]
    /// 속보만 포함
    public let breakingOnly: Bool
    /// 키워드 필터
    public let keywords: [String]
    
    public init(
        fromDate: Date? = nil,
        toDate: Date? = nil,
        categories: [YFNewsCategory] = [],
        minSentimentScore: Double? = nil,
        maxSentimentScore: Double? = nil,
        includeSources: [String] = [],
        excludeSources: [String] = [],
        breakingOnly: Bool = false,
        keywords: [String] = []
    ) {
        self.fromDate = fromDate
        self.toDate = toDate
        self.categories = categories
        self.minSentimentScore = minSentimentScore
        self.maxSentimentScore = maxSentimentScore
        self.includeSources = includeSources
        self.excludeSources = excludeSources
        self.breakingOnly = breakingOnly
        self.keywords = keywords
    }
}

/// 뉴스 소스 정보
public struct YFNewsSource: Sendable {
    /// 소스 이름
    public let name: String
    /// 소스 웹사이트
    public let website: String?
    /// 소스 신뢰도 (0.0 ~ 1.0)
    public let reliability: Double
    /// 소스 편향성 (-1.0: 좌편향, 0.0: 중립, 1.0: 우편향)
    public let bias: Double
    
    public init(name: String, website: String? = nil, reliability: Double = 0.5, bias: Double = 0.0) {
        self.name = name
        self.website = website
        self.reliability = reliability
        self.bias = bias
    }
}

/// 인기 뉴스 소스들
public extension YFNewsSource {
    static let reuters = YFNewsSource(
        name: "Reuters",
        website: "https://www.reuters.com",
        reliability: 0.95,
        bias: 0.1
    )
    
    static let bloomberg = YFNewsSource(
        name: "Bloomberg",
        website: "https://www.bloomberg.com",
        reliability: 0.92,
        bias: 0.2
    )
    
    static let cnbc = YFNewsSource(
        name: "CNBC",
        website: "https://www.cnbc.com",
        reliability: 0.88,
        bias: 0.3
    )
    
    static let marketWatch = YFNewsSource(
        name: "MarketWatch",
        website: "https://www.marketwatch.com",
        reliability: 0.85,
        bias: 0.1
    )
    
    static let seekingAlpha = YFNewsSource(
        name: "Seeking Alpha",
        website: "https://seekingalpha.com",
        reliability: 0.78,
        bias: 0.0
    )
}