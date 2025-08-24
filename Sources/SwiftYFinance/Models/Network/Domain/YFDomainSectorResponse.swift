import Foundation

/// Yahoo Finance Domain Sector API 응답 모델
///
/// 실제 섹터 API 응답 구조에 맞춘 모델입니다.
public struct YFDomainSectorResponse: Codable, Sendable {
    /// 섹터 데이터
    public let data: YFSectorData?
    
    enum CodingKeys: String, CodingKey {
        case data
    }
}

/// 섹터 데이터 컨테이너
public struct YFSectorData: Codable, Sendable {
    /// 섹터 심볼
    public let symbol: String?
    
    /// 섹터 키 (technology, healthcare 등)
    public let key: String?
    
    /// 섹터 이름
    public let name: String?
    
    /// 섹터 개요 정보
    public let overview: YFSectorOverview?
    
    /// 성과 지표
    public let performance: YFSectorPerformance?
    
    /// 벤치마크와의 성과 비교
    public let performanceOverviewBenchmark: YFSectorPerformance?
    
    /// 상위 기업들
    public let topCompanies: [YFSectorCompany]?
    
    /// 상위 ETF들
    public let topETFs: [YFSectorETF]?
    
    /// 상위 뮤추얼 펀드들
    public let topMutualFunds: [YFSectorMutualFund]?
    
    /// 산업 세부 분류
    public let industries: [YFSectorIndustry]?
    
    /// 리서치 보고서
    public let researchReports: [YFSectorResearchReport]?
    
    enum CodingKeys: String, CodingKey {
        case symbol, key, name, overview, performance
        case performanceOverviewBenchmark
        case topCompanies, topETFs, topMutualFunds
        case industries, researchReports
    }
}

/// 섹터 개요 정보
public struct YFSectorOverview: Codable, Sendable {
    /// 총 시가총액
    public let marketCap: YFFormattedValue?
    
    /// 시장에서의 비중
    public let marketWeight: YFFormattedValue?
    
    /// 기업 수
    public let companiesCount: Int?
    
    /// 산업 분류 수
    public let industriesCount: Int?
    
    /// 총 직원 수
    public let employeeCount: YFFormattedValue?
    
    /// 설명
    public let description: String?
    
    /// 메시지 보드 ID
    public let messageBoardId: String?
    
    enum CodingKeys: String, CodingKey {
        case marketCap, marketWeight, companiesCount
        case industriesCount, employeeCount, description
        case messageBoardId
    }
}

/// 성과 지표
public struct YFSectorPerformance: Codable, Sendable {
    /// YTD 변화율
    public let ytdChangePercent: YFFormattedValue?
    
    /// 1년 변화율
    public let oneYearChangePercent: YFFormattedValue?
    
    /// 3년 변화율
    public let threeYearChangePercent: YFFormattedValue?
    
    /// 5년 변화율
    public let fiveYearChangePercent: YFFormattedValue?
    
    /// 정규 시장 변화율
    public let regMarketChangePercent: YFFormattedValue?
    
    /// 이름 (벤치마크용)
    public let name: String?
    
    enum CodingKeys: String, CodingKey {
        case ytdChangePercent, oneYearChangePercent
        case threeYearChangePercent, fiveYearChangePercent
        case regMarketChangePercent, name
    }
}

/// 상위 기업 정보
public struct YFSectorCompany: Codable, Sendable {
    /// 심볼
    public let symbol: String?
    
    /// 기업명
    public let name: String?
    
    /// 현재 가격
    public let lastPrice: YFFormattedValue?
    
    /// 시가총액
    public let marketCap: YFFormattedValue?
    
    /// 정규 시장 변화율
    public let regMarketChangePercent: YFFormattedValue?
    
    /// 시장 비중
    public let marketWeight: YFFormattedValue?
    
    /// YTD 수익률
    public let ytdReturn: YFFormattedValue?
    
    /// 애널리스트 평가
    public let rating: String?
    
    /// 목표 가격
    public let targetPrice: YFFormattedValue?
    
    enum CodingKeys: String, CodingKey {
        case symbol, name, lastPrice, marketCap
        case regMarketChangePercent, marketWeight
        case ytdReturn, rating, targetPrice
    }
}

/// ETF 정보
public struct YFSectorETF: Codable, Sendable {
    /// 심볼
    public let symbol: String?
    
    /// 펀드명
    public let name: String?
    
    /// 현재 가격
    public let lastPrice: YFFormattedValue?
    
    /// 순자산
    public let netAssets: YFFormattedValue?
    
    /// 비용 비율
    public let expenseRatio: YFFormattedValue?
    
    /// YTD 수익률
    public let ytdReturn: YFFormattedValue?
    
    enum CodingKeys: String, CodingKey {
        case symbol, name, lastPrice, netAssets
        case expenseRatio, ytdReturn
    }
}

/// 뮤추얼 펀드 정보
public struct YFSectorMutualFund: Codable, Sendable {
    /// 심볼
    public let symbol: String?
    
    /// 펀드명
    public let name: String?
    
    /// 현재 가격
    public let lastPrice: YFFormattedValue?
    
    /// 순자산
    public let netAssets: YFFormattedValue?
    
    /// 비용 비율
    public let expenseRatio: YFFormattedValue?
    
    /// YTD 수익률
    public let ytdReturn: YFFormattedValue?
    
    enum CodingKeys: String, CodingKey {
        case symbol, name, lastPrice, netAssets
        case expenseRatio, ytdReturn
    }
}

/// 산업 세부 분류
public struct YFSectorIndustry: Codable, Sendable {
    /// 산업 키
    public let key: String?
    
    /// 산업 심볼
    public let symbol: String?
    
    /// 산업명
    public let name: String?
    
    /// 시장 비중
    public let marketWeight: YFFormattedValue?
    
    /// 정규 시장 변화율
    public let regMarketChangePercent: YFFormattedValue?
    
    /// YTD 수익률
    public let ytdReturn: YFFormattedValue?
    
    enum CodingKeys: String, CodingKey {
        case key, symbol, name, marketWeight
        case regMarketChangePercent, ytdReturn
    }
}

/// 리서치 보고서 정보
public struct YFSectorResearchReport: Codable, Sendable {
    /// 보고서 ID
    public let id: String?
    
    /// 제공자
    public let provider: String?
    
    /// 보고서 타입
    public let reportType: String?
    
    /// 보고서 제목
    public let reportTitle: String?
    
    /// 헤드 HTML
    public let headHtml: String?
    
    /// 보고서 날짜
    public let reportDate: String?
    
    /// 투자 등급
    public let investmentRating: String?
    
    /// 목표 가격
    public let targetPrice: Double?
    
    /// 목표 가격 상태
    public let targetPriceStatus: String?
    
    enum CodingKeys: String, CodingKey {
        case id, provider, reportType, reportTitle
        case headHtml, reportDate, investmentRating
        case targetPrice, targetPriceStatus
    }
}

/// 포맷된 값 (raw, fmt, longFmt)
public struct YFFormattedValue: Codable, Sendable {
    /// 원시 값
    public let raw: Double?
    
    /// 포맷된 값
    public let fmt: String?
    
    /// 긴 포맷 값
    public let longFmt: String?
    
    enum CodingKeys: String, CodingKey {
        case raw, fmt, longFmt
    }
}