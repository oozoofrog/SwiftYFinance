import Foundation

// MARK: - Balance Sheet API Response Models

/// Balance Sheet 응답을 포함하는 QuoteSummary 결과 확장
struct BalanceSheetQuoteSummaryResult: Codable {
    /// Balance Sheet History 모듈 데이터
    let balanceSheetHistory: BalanceSheetHistory?
    /// Balance Sheet History Quarterly 모듈 데이터
    let balanceSheetHistoryQuarterly: BalanceSheetHistory?
}

/// Balance Sheet History 컨테이너
struct BalanceSheetHistory: Codable {
    /// Balance Sheet 명세서 배열
    let balanceSheetStatements: [BalanceSheetStatement]?
}

/// 개별 Balance Sheet 명세서
struct BalanceSheetStatement: Codable {
    /// 보고 날짜 (Unix timestamp)
    let endDate: TimeValue?
    
    // Assets
    /// 총 자산
    let totalAssets: LongValue?
    /// 유동 자산
    let totalCurrentAssets: LongValue?
    /// 현금 및 현금성 자산
    let cash: LongValue?
    /// 단기 투자
    let shortTermInvestments: LongValue?
    /// 순 매출채권
    let netReceivables: LongValue?
    /// 재고자산
    let inventory: LongValue?
    /// 기타 유동자산
    let otherCurrentAssets: LongValue?
    
    // Liabilities
    /// 총 부채
    let totalLiab: LongValue?
    /// 유동 부채
    let totalCurrentLiabilities: LongValue?
    /// 매입채무
    let accountsPayable: LongValue?
    /// 장기 부채
    let longTermDebt: LongValue?
    /// 기타 유동부채
    let otherCurrentLiab: LongValue?
    
    // Equity
    /// 총 주주 자본
    let totalStockholderEquity: LongValue?
    /// 이익잉여금
    let retainedEarnings: LongValue?
    /// 보통주
    let commonStock: LongValue?
    /// 자본잉여금
    let capitalSurplus: LongValue?
    
    /// 무형자산
    let intangibleAssets: LongValue?
    /// 영업권
    let goodWill: LongValue?
    /// 유형자산
    let propertyPlantEquipment: LongValue?
}

/// 날짜/시간 값을 담는 구조체
struct TimeValue: Codable {
    let raw: Int?
    let fmt: String?
}

/// Long 타입 값을 담는 구조체
struct LongValue: Codable {
    let raw: Double?
    let fmt: String?
    let longFmt: String?
}