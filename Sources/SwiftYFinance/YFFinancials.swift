import Foundation

public struct YFFinancials: Codable {
    public let ticker: YFTicker
    public let annualReports: [YFFinancialReport]
    public let quarterlyReports: [YFFinancialReport]
    
    public init(ticker: YFTicker, annualReports: [YFFinancialReport], quarterlyReports: [YFFinancialReport] = []) {
        self.ticker = ticker
        self.annualReports = annualReports
        self.quarterlyReports = quarterlyReports
    }
}

public struct YFFinancialReport: Codable {
    public let reportDate: Date
    public let totalRevenue: Double
    public let netIncome: Double
    public let totalAssets: Double
    public let totalLiabilities: Double
    public let grossProfit: Double?
    public let operatingIncome: Double?
    public let totalCash: Double?
    public let totalDebt: Double?
    
    public init(
        reportDate: Date,
        totalRevenue: Double,
        netIncome: Double,
        totalAssets: Double,
        totalLiabilities: Double,
        grossProfit: Double? = nil,
        operatingIncome: Double? = nil,
        totalCash: Double? = nil,
        totalDebt: Double? = nil
    ) {
        self.reportDate = reportDate
        self.totalRevenue = totalRevenue
        self.netIncome = netIncome
        self.totalAssets = totalAssets
        self.totalLiabilities = totalLiabilities
        self.grossProfit = grossProfit
        self.operatingIncome = operatingIncome
        self.totalCash = totalCash
        self.totalDebt = totalDebt
    }
}

public struct YFBalanceSheet: Codable {
    public let ticker: YFTicker
    public let annualReports: [YFBalanceSheetReport]
    public let quarterlyReports: [YFBalanceSheetReport]
    
    public init(ticker: YFTicker, annualReports: [YFBalanceSheetReport], quarterlyReports: [YFBalanceSheetReport] = []) {
        self.ticker = ticker
        self.annualReports = annualReports
        self.quarterlyReports = quarterlyReports
    }
}

public struct YFBalanceSheetReport: Codable {
    public let reportDate: Date
    public let totalCurrentAssets: Double
    public let totalCurrentLiabilities: Double
    public let totalStockholderEquity: Double
    public let retainedEarnings: Double
    public let totalAssets: Double?
    public let totalLiabilities: Double?
    public let cash: Double?
    public let shortTermInvestments: Double?
    
    public init(
        reportDate: Date,
        totalCurrentAssets: Double,
        totalCurrentLiabilities: Double,
        totalStockholderEquity: Double,
        retainedEarnings: Double,
        totalAssets: Double? = nil,
        totalLiabilities: Double? = nil,
        cash: Double? = nil,
        shortTermInvestments: Double? = nil
    ) {
        self.reportDate = reportDate
        self.totalCurrentAssets = totalCurrentAssets
        self.totalCurrentLiabilities = totalCurrentLiabilities
        self.totalStockholderEquity = totalStockholderEquity
        self.retainedEarnings = retainedEarnings
        self.totalAssets = totalAssets
        self.totalLiabilities = totalLiabilities
        self.cash = cash
        self.shortTermInvestments = shortTermInvestments
    }
}