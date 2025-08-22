import Foundation

// MARK: - Yahoo Finance News Models

/// Yahoo Finance 뉴스 API 응답 구조
public struct YFNewsResponse: Decodable, Sendable {
    public let timeTakenForScreenerField: Int?
    public let timeTakenForResearchReports: Int?
    public let lists: [String]?
    public let news: [YFNewsArticle]?
}

/// Yahoo Finance 뉴스 기사 - 모든 API 필드 노출
public struct YFNewsArticle: Decodable, Sendable {
    public let providerPublishTime: Int?
    public let thumbnail: YFNewsThumbnail?
    public let title: String?
    public let uuid: String?
    public let link: String?
    public let publisher: String?
    public let type: String?
    public let relatedTickers: [String]?
    public let summary: String?
    public let isBreaking: Bool?
    public let isPremium: Bool?
    public let hasPublisherVideo: Bool?
    public let hasEntityInTitle: Bool?
    public let entityTokens: [YFNewsEntityToken]?
    public let mentions: [YFNewsMention]?
    public let offNetwork: Bool?
    public let content: String?
    public let streams: [YFNewsStream]?
    public let ignoreMainBodyClick: Bool?
    public let clickThroughUrl: String?
    public let referenceId: String?
}

/// 뉴스 썸네일 구조
public struct YFNewsThumbnail: Decodable, Sendable {
    public let resolutions: [YFNewsThumbnailResolution]?
}

/// 뉴스 썸네일 해상도 정보
public struct YFNewsThumbnailResolution: Decodable, Sendable {
    public let tag: String?
    public let url: String?
    public let width: Int?
    public let height: Int?
}

/// 뉴스 엔티티 토큰
public struct YFNewsEntityToken: Decodable, Sendable {
    public let text: String?
    public let type: String?
    public let startIndex: Int?
    public let endIndex: Int?
}

/// 뉴스 멘션
public struct YFNewsMention: Decodable, Sendable {
    public let symbol: String?
    public let name: String?
}

/// 뉴스 스트림
public struct YFNewsStream: Decodable, Sendable {
    public let uuid: String?
    public let publisher: String?
    public let offNetwork: Bool?
}