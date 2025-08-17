import Foundation

// MARK: - Yahoo Finance News API Response Models

/// Yahoo Finance News API 응답 구조
struct YFNewsResponse: Codable {
    let explains: [String]?
    let count: Int?
    let quotes: [String]?
    let news: [YFNewsResponseItem]?
    let nav: [String]?
    let lists: [String]?
    let researchReports: [String]?
    let screenerFieldResults: [String]?
    let totalTime: Int?
    let timeTakenForQuotes: Int?
    let timeTakenForNews: Int?
    let timeTakenForAlgowatchlist: Int?
    let timeTakenForPredefinedScreener: Int?
    let timeTakenForCrunchbase: Int?
    let timeTakenForNav: Int?
    let timeTakenForResearchReports: Int?
    let timeTakenForScreenerField: Int?
    let timeTakenForCulturalAssets: Int?
    
    // Alternative response format
    let stream: [YFNewsStreamItem]?
}

/// News stream item
struct YFNewsStreamItem: Codable {
    let content: YFNewsContent?
    let id: String?
    let type: String?
}

/// News content
struct YFNewsContent: Codable {
    let clickThroughUrl: YFNewsClickThroughUrl?
    let summary: String?
    let thumbnail: YFNewsThumbnail?
    let title: String
    let type: String?
    let uuid: String?
    let link: String
    let pubDate: Int?
    let provider: YFNewsProvider?
    let category: String?
}

/// Click through URL
struct YFNewsClickThroughUrl: Codable {
    let desktop: String?
    let mobile: String?
}

/// Thumbnail
struct YFNewsThumbnail: Codable {
    let resolutions: [YFNewsResolution]?
}

/// Resolution
struct YFNewsResolution: Codable {
    let url: String?
    let width: Int?
    let height: Int?
    let tag: String?
}

/// Provider
struct YFNewsProvider: Codable {
    let displayName: String?
    let publishTime: Int?
}

/// Legacy news response item
struct YFNewsResponseItem: Codable {
    let uuid: String
    let title: String
    let publisher: String?
    let link: String
    let providerPublishTime: Int?
    let type: String?
    let thumbnail: YFNewsThumbnail?
    let relatedTickers: [String]?
}