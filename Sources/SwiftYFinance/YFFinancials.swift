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

/// A container for cash flow statement data from Yahoo Finance.
///
/// This structure holds both annual and quarterly cash flow reports for a given ticker.
/// Cash flow statements track how changes in balance sheet accounts and income affect
/// cash and cash equivalents, breaking the analysis down to operating, investing, and financing activities.
///
/// ## Related Types
/// - ``YFCashFlowReport``: Individual cash flow report data
/// - ``YFTicker``: The stock ticker identifier
///
/// ## Usage Example
/// ```swift
/// let client = YFClient()
/// let ticker = try YFTicker(symbol: "AAPL")
/// let cashFlow = try await client.fetchCashFlow(ticker: ticker)
///
/// for report in cashFlow.annualReports {
///     print("Year: \(report.reportDate)")
///     print("Operating Cash Flow: $\(report.operatingCashFlow / 1_000_000)M")
/// }
/// ```
public struct YFCashFlow: Codable {
    /// The ticker symbol this cash flow data belongs to
    public let ticker: YFTicker
    /// Annual cash flow reports, typically spanning multiple years
    public let annualReports: [YFCashFlowReport]
    /// Quarterly cash flow reports for more granular analysis
    public let quarterlyReports: [YFCashFlowReport]
    
    /// Creates a new cash flow data container.
    /// - Parameters:
    ///   - ticker: The ticker symbol
    ///   - annualReports: Array of annual cash flow reports
    ///   - quarterlyReports: Array of quarterly reports (defaults to empty)
    public init(ticker: YFTicker, annualReports: [YFCashFlowReport], quarterlyReports: [YFCashFlowReport] = []) {
        self.ticker = ticker
        self.annualReports = annualReports
        self.quarterlyReports = quarterlyReports
    }
}

/// A single cash flow statement report containing key cash flow metrics.
///
/// This structure represents cash flow data for a specific reporting period,
/// including operating activities, investing activities, and financing activities.
/// All monetary values are in the reporting currency (typically USD) as absolute amounts.
///
/// ## Key Metrics
/// - **Operating Cash Flow**: Cash generated from core business operations
/// - **Free Cash Flow**: Operating cash flow minus capital expenditures  
/// - **Capital Expenditure**: Money spent on property, plant, and equipment
/// - **Net PPE Purchase And Sale**: Net changes in property, plant, and equipment
///
/// ## Usage Example
/// ```swift
/// let report = YFCashFlowReport(
///     reportDate: Date(),
///     operatingCashFlow: 110_543_000_000,  // $110.5B
///     freeCashFlow: 99_584_000_000         // $99.6B
/// )
/// print("FCF Margin: \(report.freeCashFlow! / report.operatingCashFlow * 100)%")
/// ```
public struct YFCashFlowReport: Codable {
    /// The date this cash flow report covers (typically end of fiscal period)
    public let reportDate: Date
    /// Cash generated from operating activities (always present)
    public let operatingCashFlow: Double
    /// Net cash flow from purchasing/selling property, plant & equipment
    public let netPPEPurchaseAndSale: Double?
    /// Operating cash flow minus capital expenditures (key profitability metric)
    public let freeCashFlow: Double?
    /// Cash spent on property, plant, and equipment purchases (negative value)
    public let capitalExpenditure: Double?
    /// Net cash flow from financing activities (debt, equity, dividends)
    public let financingCashFlow: Double?
    /// Net cash flow from investing activities (acquisitions, investments)
    public let investingCashFlow: Double?
    /// Net change in cash and cash equivalents for the period
    public let changeInCash: Double?
    /// Cash and cash equivalents at the beginning of the period
    public let beginningCashPosition: Double?
    /// Cash and cash equivalents at the end of the period
    public let endCashPosition: Double?
    
    /// Creates a new cash flow report.
    /// - Parameters:
    ///   - reportDate: The reporting period end date
    ///   - operatingCashFlow: Cash from operating activities (required)
    ///   - netPPEPurchaseAndSale: Net PPE transactions (optional)
    ///   - freeCashFlow: Free cash flow calculation (optional)
    ///   - capitalExpenditure: Capital spending (optional)
    ///   - financingCashFlow: Financing activities cash flow (optional)
    ///   - investingCashFlow: Investing activities cash flow (optional)
    ///   - changeInCash: Period change in cash (optional)
    ///   - beginningCashPosition: Starting cash position (optional)
    ///   - endCashPosition: Ending cash position (optional)
    public init(
        reportDate: Date,
        operatingCashFlow: Double,
        netPPEPurchaseAndSale: Double? = nil,
        freeCashFlow: Double? = nil,
        capitalExpenditure: Double? = nil,
        financingCashFlow: Double? = nil,
        investingCashFlow: Double? = nil,
        changeInCash: Double? = nil,
        beginningCashPosition: Double? = nil,
        endCashPosition: Double? = nil
    ) {
        self.reportDate = reportDate
        self.operatingCashFlow = operatingCashFlow
        self.netPPEPurchaseAndSale = netPPEPurchaseAndSale
        self.freeCashFlow = freeCashFlow
        self.capitalExpenditure = capitalExpenditure
        self.financingCashFlow = financingCashFlow
        self.investingCashFlow = investingCashFlow
        self.changeInCash = changeInCash
        self.beginningCashPosition = beginningCashPosition
        self.endCashPosition = endCashPosition
    }
}