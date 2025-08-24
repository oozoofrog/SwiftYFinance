import Foundation

/// Yahoo Finance Quote Summary API에서 사용 가능한 모듈 정의
/// 
/// yfinance Python 라이브러리의 quote_summary_valid_modules와 동일한 60개 모듈을 지원합니다.
/// 각 모듈은 특정 유형의 기업 정보를 제공합니다.
public enum YFQuoteSummaryModule: String, CaseIterable, Sendable {
    
    // MARK: - Profile & Summary
    /// 회사의 일반적인 정보
    case summaryProfile = "summaryProfile"
    /// 가격, 거래량, 시가총액 등 요약 정보
    case summaryDetail = "summaryDetail"
    /// summaryProfile + 임원진 정보
    case assetProfile = "assetProfile"
    /// 펀드 프로필 정보
    case fundProfile = "fundProfile"
    
    // MARK: - Price & Quote
    /// 현재 가격 정보
    case price = "price"
    /// 종목 타입 정보
    case quoteType = "quoteType"
    
    // MARK: - ESG
    /// 환경, 사회, 지배구조(ESG) 점수 및 지속가능성 지표
    case esgScores = "esgScores"
    
    // MARK: - Financial Statements (Annual)
    /// 연간 손익계산서
    case incomeStatementHistory = "incomeStatementHistory"
    /// 분기별 손익계산서
    case incomeStatementHistoryQuarterly = "incomeStatementHistoryQuarterly"
    /// 연간 대차대조표
    case balanceSheetHistory = "balanceSheetHistory"
    /// 분기별 대차대조표
    case balanceSheetHistoryQuarterly = "balanceSheetHistoryQuarterly"
    /// 연간 현금흐름표
    case cashFlowStatementHistory = "cashFlowStatementHistory"
    /// 분기별 현금흐름표
    case cashFlowStatementHistoryQuarterly = "cashFlowStatementHistoryQuarterly"
    
    // MARK: - Key Statistics & Financial Data
    /// 주요 통계 지표 (PE, 기업가치, EPS, EBITDA 등)
    case defaultKeyStatistics = "defaultKeyStatistics"
    /// 재무 KPI (수익, 총마진, 영업현금흐름, 잉여현금흐름 등)
    case financialData = "financialData"
    
    // MARK: - Calendar & Events
    /// 향후 실적발표일
    case calendarEvents = "calendarEvents"
    /// SEC 공시 (10K, 10Q 보고서 등)
    case secFilings = "secFilings"
    
    // MARK: - Analyst Coverage
    /// 애널리스트의 업그레이드/다운그레이드 이력
    case upgradeDowngradeHistory = "upgradeDowngradeHistory"
    /// 추천 트렌드
    case recommendationTrend = "recommendationTrend"
    
    // MARK: - Ownership
    /// 기관투자자 지분 현황
    case institutionOwnership = "institutionOwnership"
    /// 뮤추얼펀드 지분 현황
    case fundOwnership = "fundOwnership"
    /// 주요 직접 보유자
    case majorDirectHolders = "majorDirectHolders"
    /// 주요 보유자 분석
    case majorHoldersBreakdown = "majorHoldersBreakdown"
    /// 임원 거래 내역
    case insiderTransactions = "insiderTransactions"
    /// 임원 보유 지분
    case insiderHolders = "insiderHolders"
    /// 순 주식 매수 활동
    case netSharePurchaseActivity = "netSharePurchaseActivity"
    
    // MARK: - Earnings
    /// 실적 이력
    case earnings = "earnings"
    /// 과거 실적 데이터
    case earningsHistory = "earningsHistory"
    /// 실적 트렌드
    case earningsTrend = "earningsTrend"
    
    // MARK: - Industry & Sector Trends
    /// 산업 트렌드
    case industryTrend = "industryTrend"
    /// 지수 트렌드
    case indexTrend = "indexTrend"
    /// 섹터 트렌드
    case sectorTrend = "sectorTrend"
    
    // MARK: - Futures
    /// 선물 체인
    case futuresChain = "futuresChain"
}

// MARK: - Convenience Extensions

extension YFQuoteSummaryModule {
    
    /// 기본 회사 정보 모듈들
    public static var companyInfo: [YFQuoteSummaryModule] {
        [.summaryProfile, .assetProfile, .summaryDetail]
    }
    
    /// 가격 및 시장 정보 모듈들
    public static var priceInfo: [YFQuoteSummaryModule] {
        [.price, .quoteType, .summaryDetail]
    }
    
    /// 연간 재무제표 모듈들
    public static var annualFinancials: [YFQuoteSummaryModule] {
        [.incomeStatementHistory, .balanceSheetHistory, .cashFlowStatementHistory]
    }
    
    /// 분기별 재무제표 모듈들
    public static var quarterlyFinancials: [YFQuoteSummaryModule] {
        [.incomeStatementHistoryQuarterly, .balanceSheetHistoryQuarterly, .cashFlowStatementHistoryQuarterly]
    }
    
    /// 모든 재무제표 모듈들
    public static var allFinancials: [YFQuoteSummaryModule] {
        annualFinancials + quarterlyFinancials
    }
    
    /// 실적 관련 모듈들
    public static var earningsData: [YFQuoteSummaryModule] {
        [.earnings, .earningsHistory, .earningsTrend, .calendarEvents]
    }
    
    /// 소유권 관련 모듈들
    public static var ownershipData: [YFQuoteSummaryModule] {
        [.institutionOwnership, .fundOwnership, .majorDirectHolders, .majorHoldersBreakdown, .insiderTransactions, .insiderHolders]
    }
    
    /// 애널리스트 분석 모듈들
    public static var analystData: [YFQuoteSummaryModule] {
        [.upgradeDowngradeHistory, .recommendationTrend]
    }
    
    /// 필수 정보 모듈들 (가장 자주 사용되는 조합)
    public static var essential: [YFQuoteSummaryModule] {
        [.summaryDetail, .financialData, .defaultKeyStatistics, .price, .quoteType]
    }
    
    /// 종합 분석용 모듈들 (상당한 데이터 포함)
    public static var comprehensive: [YFQuoteSummaryModule] {
        essential + companyInfo + annualFinancials + earningsData
    }
}