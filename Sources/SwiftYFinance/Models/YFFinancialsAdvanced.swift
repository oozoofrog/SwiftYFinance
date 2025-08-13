import Foundation

/// 분기별 재무제표 데이터
public struct YFQuarterlyFinancials {
    public let ticker: YFTicker
    public let quarterlyReports: [YFQuarterlyReport]
    
    public init(ticker: YFTicker, quarterlyReports: [YFQuarterlyReport]) {
        self.ticker = ticker
        self.quarterlyReports = quarterlyReports.sorted { $0.reportDate > $1.reportDate }
    }
}

/// 분기별 재무 보고서
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

/// 위험 수준
public enum RiskLevel: String, CaseIterable {
    case veryLow = "Very Low"
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"
}