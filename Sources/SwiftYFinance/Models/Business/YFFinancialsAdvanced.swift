import Foundation

/// 분기별 재무제표 데이터 컨테이너
///
/// 종목의 분기별 재무 보고서를 포함하는 구조체입니다.
/// 더 세밀한 분석을 위해 분기별 데이터를 제공합니다.
///
/// ## Topics
///
/// ### 속성
/// - ``ticker``
/// - ``quarterlyReports``
///
/// ### 초기화
/// - ``init(ticker:quarterlyReports:)``
///
/// ## Example
/// ```swift
/// let quarterlyFinancials = YFQuarterlyFinancials(
///     ticker: try YFTicker(symbol: "AAPL"),
///     quarterlyReports: [
///         // Q4 2023, Q3 2023, Q2 2023...
///     ]
/// )
/// ```
public struct YFQuarterlyFinancials {
    /// 재무 데이터의 종목
    public let ticker: YFTicker
    
    /// 분기별 재무 보고서 배열 (최신 순으로 정렬)
    public let quarterlyReports: [YFQuarterlyReport]
    
    /// YFQuarterlyFinancials 인스턴스를 생성합니다
    ///
    /// - Parameters:
    ///   - ticker: 재무 데이터의 종목
    ///   - quarterlyReports: 분기별 보고서 배열
    ///
    /// - Note: 보고서는 자동으로 최신 순(보고일 역순)으로 정렬됩니다.
    public init(ticker: YFTicker, quarterlyReports: [YFQuarterlyReport]) {
        self.ticker = ticker
        self.quarterlyReports = quarterlyReports.sorted { $0.reportDate > $1.reportDate }
    }
}

/// 분기별 재무 보고서
///
/// 한 분기에 대한 종합적인 재무 데이터를 포함합니다.
/// 손익계산서, 대차대조표, 현금흐름표의 핵심 지표들을 포함합니다.
///
/// ## Topics
///
/// ### 기본 정보
/// - ``quarter``
/// - ``reportDate``
/// - ``fiscalYear``
/// - ``fiscalQuarter``
///
/// ### 손익계산서
/// - ``totalRevenue``
/// - ``grossProfit``
/// - ``operatingIncome``
/// - ``netIncome``
/// - ``earningsPerShare``
/// - ``dilutedEPS``
///
/// ### 대차대조표 요약
/// - ``totalAssets``
/// - ``totalLiabilities``
/// - ``totalEquity``
/// - ``workingCapital``
///
/// ### 현금흐름 요약
/// - ``operatingCashFlow``
/// - ``freeCashFlow``
/// - ``capitalExpenditure``
///
/// ## Example
/// ```swift
/// let report = YFQuarterlyReport(
///     quarter: "Q4 2023",
///     reportDate: Date(),
///     fiscalYear: 2023,
///     fiscalQuarter: 4,
///     totalRevenue: 119_575_000_000,
///     grossProfit: 54_740_000_000,
///     operatingIncome: 40_290_000_000,
///     netIncome: 33_916_000_000,
///     earningsPerShare: 2.18,
///     // ...
/// )
/// ```
public struct YFQuarterlyReport {
    public let quarter: String // "Q1 2024", "Q4 2023" 등
    public let reportDate: Date
    public let fiscalYear: Int
    public let fiscalQuarter: Int
    
    // 손익계산서
    public let totalRevenue: Double
    public let grossProfit: Double
    public let operatingIncome: Double
    public let netIncome: Double
    public let earningsPerShare: Double
    public let dilutedEPS: Double?
    
    // 대차대조표 요약
    public let totalAssets: Double
    public let totalLiabilities: Double
    public let totalEquity: Double
    public let workingCapital: Double
    
    // 현금흐름 요약
    public let operatingCashFlow: Double
    public let freeCashFlow: Double?
    public let capitalExpenditure: Double?
    
    public init(
        quarter: String,
        reportDate: Date,
        fiscalYear: Int,
        fiscalQuarter: Int,
        totalRevenue: Double,
        grossProfit: Double,
        operatingIncome: Double,
        netIncome: Double,
        earningsPerShare: Double,
        dilutedEPS: Double? = nil,
        totalAssets: Double,
        totalLiabilities: Double,
        totalEquity: Double,
        workingCapital: Double,
        operatingCashFlow: Double,
        freeCashFlow: Double? = nil,
        capitalExpenditure: Double? = nil
    ) {
        self.quarter = quarter
        self.reportDate = reportDate
        self.fiscalYear = fiscalYear
        self.fiscalQuarter = fiscalQuarter
        self.totalRevenue = totalRevenue
        self.grossProfit = grossProfit
        self.operatingIncome = operatingIncome
        self.netIncome = netIncome
        self.earningsPerShare = earningsPerShare
        self.dilutedEPS = dilutedEPS
        self.totalAssets = totalAssets
        self.totalLiabilities = totalLiabilities
        self.totalEquity = totalEquity
        self.workingCapital = workingCapital
        self.operatingCashFlow = operatingCashFlow
        self.freeCashFlow = freeCashFlow
        self.capitalExpenditure = capitalExpenditure
    }
}

/// 재무 비율 분석
///
/// 기업의 재무 성과를 평가하는 다양한 비율지표들을 포함합니다.
/// 밸류에이션, 수익성, 유동성, 레버리지, 효율성 비율을 제공합니다.
///
/// ## Topics
///
/// ### 기본 정보
/// - ``ticker``
/// - ``calculationDate``
///
/// ### 밸류에이션 비율
/// - ``priceToEarnings``
/// - ``priceToBook``
/// - ``priceToSales``
/// - ``enterpriseValueToEbitda``
/// - ``pegRatio``
///
/// ### 수익성 비율
/// - ``returnOnEquity``
/// - ``returnOnAssets``
/// - ``returnOnInvestedCapital``
/// - ``grossMargin``
/// - ``operatingMargin``
/// - ``netMargin``
///
/// ### 유동성 비율
/// - ``currentRatio``
/// - ``quickRatio``
/// - ``cashRatio``
///
/// ### 레버리지 비율
/// - ``debtToEquityRatio``
/// - ``debtToAssetsRatio``
/// - ``interestCoverageRatio``
/// - ``debtServiceCoverageRatio``
///
/// ### 효율성 비율
/// - ``assetTurnover``
/// - ``inventoryTurnover``
/// - ``receivablesTurnover``
/// - ``payablesTurnover``
///
/// ## Important
/// 모든 비율은 표준적인 재무 분석 공식을 사용하여 계산됩니다.
/// 업종별로 비율의 정상 범위가 다를 수 있습니다.
///
/// ## Example
/// ```swift
/// let ratios = YFFinancialRatios(
///     ticker: try YFTicker(symbol: "AAPL"),
///     calculationDate: Date(),
///     priceToEarnings: 28.5,
///     priceToBook: 39.4,
///     returnOnEquity: 0.1475,
///     // ...
/// )
///
/// print("밸류에이션: P/E \(ratios.priceToEarnings), P/B \(ratios.priceToBook)")
/// print("수익성: ROE \(ratios.returnOnEquity * 100)%")
/// ```
public struct YFFinancialRatios {
    public let ticker: YFTicker
    public let calculationDate: Date
    
    // 밸류에이션 비율
    public let priceToEarnings: Double        // P/E
    public let priceToBook: Double            // P/B
    public let priceToSales: Double           // P/S
    public let enterpriseValueToEbitda: Double // EV/EBITDA
    public let pegRatio: Double?              // PEG
    
    // 수익성 비율
    public let returnOnEquity: Double         // ROE
    public let returnOnAssets: Double         // ROA
    public let returnOnInvestedCapital: Double // ROIC
    public let grossMargin: Double
    public let operatingMargin: Double
    public let netMargin: Double
    
    // 유동성 비율
    public let currentRatio: Double
    public let quickRatio: Double
    public let cashRatio: Double
    
    // 레버리지 비율
    public let debtToEquityRatio: Double
    public let debtToAssetsRatio: Double
    public let interestCoverageRatio: Double
    public let debtServiceCoverageRatio: Double?
    
    // 효율성 비율
    public let assetTurnover: Double
    public let inventoryTurnover: Double?
    public let receivablesTurnover: Double?
    public let payablesTurnover: Double?
    
    public init(
        ticker: YFTicker,
        calculationDate: Date = Date(),
        priceToEarnings: Double,
        priceToBook: Double,
        priceToSales: Double,
        enterpriseValueToEbitda: Double,
        pegRatio: Double? = nil,
        returnOnEquity: Double,
        returnOnAssets: Double,
        returnOnInvestedCapital: Double,
        grossMargin: Double,
        operatingMargin: Double,
        netMargin: Double,
        currentRatio: Double,
        quickRatio: Double,
        cashRatio: Double,
        debtToEquityRatio: Double,
        debtToAssetsRatio: Double,
        interestCoverageRatio: Double,
        debtServiceCoverageRatio: Double? = nil,
        assetTurnover: Double,
        inventoryTurnover: Double? = nil,
        receivablesTurnover: Double? = nil,
        payablesTurnover: Double? = nil
    ) {
        self.ticker = ticker
        self.calculationDate = calculationDate
        self.priceToEarnings = priceToEarnings
        self.priceToBook = priceToBook
        self.priceToSales = priceToSales
        self.enterpriseValueToEbitda = enterpriseValueToEbitda
        self.pegRatio = pegRatio
        self.returnOnEquity = returnOnEquity
        self.returnOnAssets = returnOnAssets
        self.returnOnInvestedCapital = returnOnInvestedCapital
        self.grossMargin = grossMargin
        self.operatingMargin = operatingMargin
        self.netMargin = netMargin
        self.currentRatio = currentRatio
        self.quickRatio = quickRatio
        self.cashRatio = cashRatio
        self.debtToEquityRatio = debtToEquityRatio
        self.debtToAssetsRatio = debtToAssetsRatio
        self.interestCoverageRatio = interestCoverageRatio
        self.debtServiceCoverageRatio = debtServiceCoverageRatio
        self.assetTurnover = assetTurnover
        self.inventoryTurnover = inventoryTurnover
        self.receivablesTurnover = receivablesTurnover
        self.payablesTurnover = payablesTurnover
    }
}

/// 성장 지표 분석
///
/// 기업의 성장성을 평가하는 다양한 지표들을 포함합니다.
/// 전년 대비(YoY), 전분기 대비(QoQ), 다년간 평균 성장률을 제공합니다.
///
/// ## Topics
///
/// ### 기본 정보
/// - ``ticker``
/// - ``calculationDate``
///
/// ### YoY 성장률
/// - ``revenueGrowthYoY``
/// - ``netIncomeGrowthYoY``
/// - ``epsGrowthYoY``
/// - ``totalAssetsGrowthYoY``
/// - ``equityGrowthYoY``
///
/// ### QoQ 성장률
/// - ``revenueGrowthQoQ``
/// - ``netIncomeGrowthQoQ``
/// - ``epsGrowthQoQ``
///
/// ### 평균 성장률
/// - ``avgRevenueGrowth3Y``
/// - ``avgRevenueGrowth5Y``
/// - ``avgEpsGrowth3Y``
/// - ``avgEpsGrowth5Y``
///
/// ### 성장 안정성
/// - ``revenueGrowthStability``
/// - ``epsGrowthStability``
///
/// ## Important
/// - YoY: Year-over-Year (전년 동기 대비)
/// - QoQ: Quarter-over-Quarter (전분기 대비)
/// - 성장 안정성: 변동계수(CV) 지표, 낮을수록 안정적
///
/// ## Example
/// ```swift
/// let growth = YFGrowthMetrics(
///     ticker: try YFTicker(symbol: "TSLA"),
///     revenueGrowthYoY: 0.19, // 19% 매출 성장
///     netIncomeGrowthYoY: 0.128, // 12.8% 순이익 성장
///     epsGrowthYoY: 0.125,
///     // ...
/// )
///
/// print("전년 대비 매출 성장: \(growth.revenueGrowthYoY * 100)%")
/// ```
public struct YFGrowthMetrics {
    public let ticker: YFTicker
    public let calculationDate: Date
    
    // Year-over-Year 성장률
    public let revenueGrowthYoY: Double
    public let netIncomeGrowthYoY: Double
    public let epsGrowthYoY: Double
    public let totalAssetsGrowthYoY: Double
    public let equityGrowthYoY: Double
    
    // Quarter-over-Quarter 성장률
    public let revenueGrowthQoQ: Double
    public let netIncomeGrowthQoQ: Double
    public let epsGrowthQoQ: Double
    
    // 평균 성장률
    public let avgRevenueGrowth3Y: Double?
    public let avgRevenueGrowth5Y: Double?
    public let avgEpsGrowth3Y: Double?
    public let avgEpsGrowth5Y: Double?
    
    // 성장 안정성
    public let revenueGrowthStability: Double // 변동계수
    public let epsGrowthStability: Double
    
    public init(
        ticker: YFTicker,
        calculationDate: Date = Date(),
        revenueGrowthYoY: Double,
        netIncomeGrowthYoY: Double,
        epsGrowthYoY: Double,
        totalAssetsGrowthYoY: Double,
        equityGrowthYoY: Double,
        revenueGrowthQoQ: Double,
        netIncomeGrowthQoQ: Double,
        epsGrowthQoQ: Double,
        avgRevenueGrowth3Y: Double? = nil,
        avgRevenueGrowth5Y: Double? = nil,
        avgEpsGrowth3Y: Double? = nil,
        avgEpsGrowth5Y: Double? = nil,
        revenueGrowthStability: Double,
        epsGrowthStability: Double
    ) {
        self.ticker = ticker
        self.calculationDate = calculationDate
        self.revenueGrowthYoY = revenueGrowthYoY
        self.netIncomeGrowthYoY = netIncomeGrowthYoY
        self.epsGrowthYoY = epsGrowthYoY
        self.totalAssetsGrowthYoY = totalAssetsGrowthYoY
        self.equityGrowthYoY = equityGrowthYoY
        self.revenueGrowthQoQ = revenueGrowthQoQ
        self.netIncomeGrowthQoQ = netIncomeGrowthQoQ
        self.epsGrowthQoQ = epsGrowthQoQ
        self.avgRevenueGrowth3Y = avgRevenueGrowth3Y
        self.avgRevenueGrowth5Y = avgRevenueGrowth5Y
        self.avgEpsGrowth3Y = avgEpsGrowth3Y
        self.avgEpsGrowth5Y = avgEpsGrowth5Y
        self.revenueGrowthStability = revenueGrowthStability
        self.epsGrowthStability = epsGrowthStability
    }
}

/// 재무 건전성 평가
///
/// 기업의 재무 건전성을 종합적으로 평가하는 지표들을 포함합니다.
/// 유동성, 부채 관리, 효율성, 수익성 등을 종합하여 건전성을 평가합니다.
///
/// ## Topics
///
/// ### 기본 정보
/// - ``ticker``
/// - ``assessmentDate``
///
/// ### 유동성 지표
/// - ``currentRatio``
/// - ``quickRatio``
/// - ``cashRatio``
/// - ``operatingCashFlowRatio``
///
/// ### 부채 관리
/// - ``debtToEquityRatio``
/// - ``debtToAssetsRatio``
/// - ``interestCoverageRatio``
/// - ``debtServiceCoverageRatio``
///
/// ### 효율성
/// - ``assetTurnover``
/// - ``inventoryTurnover``
/// - ``receivablesTurnover``
///
/// ### 수익성
/// - ``returnOnEquity``
/// - ``returnOnAssets``
/// - ``returnOnInvestedCapital``
/// - ``operatingMargin``
///
/// ### 종합 평가
/// - ``overallHealthScore``
/// - ``creditRating``
/// - ``riskLevel``
///
/// ## Important
/// 건전성 점수는 1-10 점 척도로, 10점에 가까울수록 우수합니다.
/// 신용등급은 AAA(최상)부터 D(부도)까지의 범위를 가집니다.
///
/// ## Example
/// ```swift
/// let health = YFFinancialHealth(
///     ticker: try YFTicker(symbol: "JNJ"),
///     currentRatio: 1.32,
///     quickRatio: 0.97,
///     debtToEquityRatio: 0.46,
///     returnOnEquity: 0.248,
///     overallHealthScore: 8.5,
///     creditRating: "AAA",
///     riskLevel: .low
/// )
///
/// print("재무 건전성: \(health.overallHealthScore)/10")
/// print("신용등급: \(health.creditRating)")
/// ```
public struct YFFinancialHealth {
    public let ticker: YFTicker
    public let assessmentDate: Date
    
    // 유동성 지표
    public let currentRatio: Double
    public let quickRatio: Double
    public let cashRatio: Double
    public let operatingCashFlowRatio: Double
    
    // 부채 관리
    public let debtToEquityRatio: Double
    public let debtToAssetsRatio: Double
    public let interestCoverageRatio: Double
    public let debtServiceCoverageRatio: Double
    
    // 효율성
    public let assetTurnover: Double
    public let inventoryTurnover: Double
    public let receivablesTurnover: Double
    
    // 수익성
    public let returnOnEquity: Double
    public let returnOnAssets: Double
    public let returnOnInvestedCapital: Double
    public let operatingMargin: Double
    
    // 종합 평가
    public let overallHealthScore: Double // 1-10 점수
    public let creditRating: String // AAA, AA, A, BBB, BB, B, CCC, CC, C, D
    public let riskLevel: RiskLevel
    
    public init(
        ticker: YFTicker,
        assessmentDate: Date = Date(),
        currentRatio: Double,
        quickRatio: Double,
        cashRatio: Double,
        operatingCashFlowRatio: Double,
        debtToEquityRatio: Double,
        debtToAssetsRatio: Double,
        interestCoverageRatio: Double,
        debtServiceCoverageRatio: Double,
        assetTurnover: Double,
        inventoryTurnover: Double,
        receivablesTurnover: Double,
        returnOnEquity: Double,
        returnOnAssets: Double,
        returnOnInvestedCapital: Double,
        operatingMargin: Double,
        overallHealthScore: Double,
        creditRating: String,
        riskLevel: RiskLevel
    ) {
        self.ticker = ticker
        self.assessmentDate = assessmentDate
        self.currentRatio = currentRatio
        self.quickRatio = quickRatio
        self.cashRatio = cashRatio
        self.operatingCashFlowRatio = operatingCashFlowRatio
        self.debtToEquityRatio = debtToEquityRatio
        self.debtToAssetsRatio = debtToAssetsRatio
        self.interestCoverageRatio = interestCoverageRatio
        self.debtServiceCoverageRatio = debtServiceCoverageRatio
        self.assetTurnover = assetTurnover
        self.inventoryTurnover = inventoryTurnover
        self.receivablesTurnover = receivablesTurnover
        self.returnOnEquity = returnOnEquity
        self.returnOnAssets = returnOnAssets
        self.returnOnInvestedCapital = returnOnInvestedCapital
        self.operatingMargin = operatingMargin
        self.overallHealthScore = overallHealthScore
        self.creditRating = creditRating
        self.riskLevel = riskLevel
    }
}

/// 산업 비교 분석
///
/// 기업의 재무 성과를 동일 산업 및 섹터 대비 비교분석합니다.
/// 상대적 위치와 경쟁력을 평가할 수 있는 지표들을 제공합니다.
///
/// ## Topics
///
/// ### 기본 정보
/// - ``ticker``
/// - ``industry``
/// - ``sector``
/// - ``comparisonDate``
///
/// ### 산업 대비 비율
/// - ``peRatioVsIndustry``
/// - ``roaVsIndustry``
/// - ``roeVsIndustry``
/// - ``profitMarginVsIndustry``
/// - ``debtRatioVsIndustry``
///
/// ### 순위 백분위
/// - ``industryRankPercentile``
/// - ``sectorRankPercentile``
///
/// ### 시장 대비
/// - ``betaVsMarket``
/// - ``correlationWithMarket``
///
/// ### 밸류에이션 비교
/// - ``valuationVsIndustry``
/// - ``valuationVsSector``
///
/// ## Important
/// - 백분위 순위: 0-100 범위, 100에 가까울수록 상위권
/// - 밸류에이션 비교: 양수는 고평가, 음수는 저평가
/// - 베타: 1보다 클수록 시장 대비 변동성이 큼
///
/// ## Example
/// ```swift
/// let comparison = YFIndustryComparison(
///     ticker: try YFTicker(symbol: "NVDA"),
///     industry: "Semiconductors",
///     sector: "Technology",
///     peRatioVsIndustry: 15.2, // 산업 평균대비 15.2% 높음
///     industryRankPercentile: 85, // 산업 내 상위 15%
///     betaVsMarket: 1.65
/// )
/// ```
public struct YFIndustryComparison {
    public let ticker: YFTicker
    public let industry: String
    public let sector: String
    public let comparisonDate: Date
    
    // 산업 대비 비율 차이 (%)
    public let peRatioVsIndustry: Double
    public let roaVsIndustry: Double
    public let roeVsIndustry: Double
    public let profitMarginVsIndustry: Double
    public let debtRatioVsIndustry: Double
    
    // 순위 (백분위)
    public let industryRankPercentile: Double // 0-100
    public let sectorRankPercentile: Double   // 0-100
    
    // 시장 대비
    public let betaVsMarket: Double
    public let correlationWithMarket: Double
    
    // 밸류에이션 비교
    public let valuationVsIndustry: Double // 고평가(+) / 저평가(-)
    public let valuationVsSector: Double
    
    public init(
        ticker: YFTicker,
        industry: String,
        sector: String,
        comparisonDate: Date = Date(),
        peRatioVsIndustry: Double,
        roaVsIndustry: Double,
        roeVsIndustry: Double,
        profitMarginVsIndustry: Double,
        debtRatioVsIndustry: Double,
        industryRankPercentile: Double,
        sectorRankPercentile: Double,
        betaVsMarket: Double,
        correlationWithMarket: Double,
        valuationVsIndustry: Double,
        valuationVsSector: Double
    ) {
        self.ticker = ticker
        self.industry = industry
        self.sector = sector
        self.comparisonDate = comparisonDate
        self.peRatioVsIndustry = peRatioVsIndustry
        self.roaVsIndustry = roaVsIndustry
        self.roeVsIndustry = roeVsIndustry
        self.profitMarginVsIndustry = profitMarginVsIndustry
        self.debtRatioVsIndustry = debtRatioVsIndustry
        self.industryRankPercentile = industryRankPercentile
        self.sectorRankPercentile = sectorRankPercentile
        self.betaVsMarket = betaVsMarket
        self.correlationWithMarket = correlationWithMarket
        self.valuationVsIndustry = valuationVsIndustry
        self.valuationVsSector = valuationVsSector
    }
}

/// 위험 수준 열거형
///
/// 재무 건전성 평가에서 사용되는 위험 수준을 나타냅니다.
/// 5단계로 구분되어 있으며, 전반적인 투자 위험도를 나타냅니다.
///
/// ## Cases
///
/// ### 위험 단계
/// - ``veryLow``: 매우 낮음 - 안정적인 대형 기업
/// - ``low``: 낮음 - 우량 기업, 안정적 수익
/// - ``moderate``: 보통 - 일반적 시장 위험
/// - ``high``: 높음 - 성장주, 고변동성
/// - ``veryHigh``: 매우 높음 - 스타트업, 투기주
///
/// ## Usage
/// 이 열거형은 ``YFFinancialHealth`` 구조체에서 사용되어
/// 종합적인 위험 평가를 제공합니다.
///
/// ## Example
/// ```swift
/// let riskLevel: RiskLevel = .moderate
/// print("위험 수준: \(riskLevel.rawValue)")
///
/// // 모든 위험 수준 확인
/// for level in RiskLevel.allCases {
///     print(level.rawValue)
/// }
/// ```
public enum RiskLevel: String, CaseIterable {
    /// 매우 낮음 - 최고 등급 우량기업
    case veryLow = "Very Low"
    
    /// 낮음 - 안정적인 우량기업
    case low = "Low"
    
    /// 보통 - 일반적인 시장 위험
    case moderate = "Moderate"
    
    /// 높음 - 성장주, 고변동성
    case high = "High"
    
    /// 매우 높음 - 고위험 투기주
    case veryHigh = "Very High"
}