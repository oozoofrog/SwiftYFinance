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

/// A container for earnings data from Yahoo Finance.
///
/// This structure holds both annual and quarterly earnings reports for a given ticker,
/// along with earnings estimates and historical earnings data. Earnings data provides
/// key profitability metrics including revenue, earnings per share (EPS), and other
/// income statement highlights.
///
/// ## Related Types
/// - ``YFEarningsReport``: Individual earnings report data
/// - ``YFEarningsEstimate``: Future earnings estimates
/// - ``YFTicker``: The stock ticker identifier
///
/// ## Usage Example
/// ```swift
/// let client = YFClient()
/// let ticker = try YFTicker(symbol: "AAPL")
/// let earnings = try await client.fetchEarnings(ticker: ticker)
///
/// for report in earnings.annualReports {
///     print("Year: \(report.reportDate)")
///     print("Revenue: $\(report.totalRevenue / 1_000_000_000)B")
///     print("EPS: $\(report.earningsPerShare)")
/// }
/// ```
public struct YFEarnings: Codable {
    /// The ticker symbol this earnings data belongs to
    public let ticker: YFTicker
    /// Annual earnings reports, typically spanning multiple years
    public let annualReports: [YFEarningsReport]
    /// Quarterly earnings reports for more granular analysis
    public let quarterlyReports: [YFEarningsReport]
    /// Future earnings estimates from analysts
    public let estimates: [YFEarningsEstimate]
    
    /// Creates a new earnings data container.
    /// - Parameters:
    ///   - ticker: The ticker symbol
    ///   - annualReports: Array of annual earnings reports
    ///   - quarterlyReports: Array of quarterly reports (defaults to empty)
    ///   - estimates: Array of earnings estimates (defaults to empty)
    public init(ticker: YFTicker, annualReports: [YFEarningsReport], quarterlyReports: [YFEarningsReport] = [], estimates: [YFEarningsEstimate] = []) {
        self.ticker = ticker
        self.annualReports = annualReports
        self.quarterlyReports = quarterlyReports
        self.estimates = estimates
    }
}

/// A single earnings report containing key profitability metrics.
///
/// This structure represents earnings data for a specific reporting period,
/// including revenue, earnings per share, and other income statement highlights.
/// All monetary values are in the reporting currency (typically USD) as absolute amounts.
///
/// ## Key Metrics
/// - **Total Revenue**: Total sales/revenue for the period
/// - **Earnings Per Share (EPS)**: Net income divided by shares outstanding
/// - **Diluted EPS**: EPS calculated with all potential shares included
/// - **EBITDA**: Earnings before interest, taxes, depreciation, and amortization
///
/// ## Usage Example
/// ```swift
/// let report = YFEarningsReport(
///     reportDate: Date(),
///     totalRevenue: 394_328_000_000,  // $394.3B
///     earningsPerShare: 6.13          // $6.13 EPS
/// )
/// print("Revenue Growth: \(report.totalRevenue)")
/// ```
public struct YFEarningsReport: Codable {
    /// The date this earnings report covers (typically end of fiscal period)
    public let reportDate: Date
    /// Total revenue/sales for the period (always present)
    public let totalRevenue: Double
    /// Basic earnings per share
    public let earningsPerShare: Double
    /// Diluted earnings per share (includes potential dilution)
    public let dilutedEPS: Double?
    /// Earnings before interest, taxes, depreciation, and amortization
    public let ebitda: Double?
    /// Net income for the period
    public let netIncome: Double?
    /// Gross profit (revenue minus cost of goods sold)
    public let grossProfit: Double?
    /// Operating income before interest and taxes
    public let operatingIncome: Double?
    /// Surprise percentage vs analyst estimates
    public let surprisePercent: Double?
    
    /// Creates a new earnings report.
    /// - Parameters:
    ///   - reportDate: The reporting period end date
    ///   - totalRevenue: Total revenue for the period (required)
    ///   - earningsPerShare: Basic EPS (required)
    ///   - dilutedEPS: Diluted EPS (optional)
    ///   - ebitda: EBITDA calculation (optional)
    ///   - netIncome: Net income (optional)
    ///   - grossProfit: Gross profit (optional)
    ///   - operatingIncome: Operating income (optional)
    ///   - surprisePercent: Earnings surprise percentage (optional)
    public init(
        reportDate: Date,
        totalRevenue: Double,
        earningsPerShare: Double,
        dilutedEPS: Double? = nil,
        ebitda: Double? = nil,
        netIncome: Double? = nil,
        grossProfit: Double? = nil,
        operatingIncome: Double? = nil,
        surprisePercent: Double? = nil
    ) {
        self.reportDate = reportDate
        self.totalRevenue = totalRevenue
        self.earningsPerShare = earningsPerShare
        self.dilutedEPS = dilutedEPS
        self.ebitda = ebitda
        self.netIncome = netIncome
        self.grossProfit = grossProfit
        self.operatingIncome = operatingIncome
        self.surprisePercent = surprisePercent
    }
}

/// Future earnings estimates from financial analysts.
///
/// This structure contains forward-looking earnings predictions from analysts,
/// including consensus estimates, high/low ranges, and revision trends.
///
/// ## Usage Example
/// ```swift
/// let estimate = YFEarningsEstimate(
///     period: "2025Q1",
///     estimateDate: Date(),
///     consensusEPS: 1.25,
///     highEstimate: 1.35,
///     lowEstimate: 1.15
/// )
/// ```
public struct YFEarningsEstimate: Codable {
    /// The period this estimate covers (e.g., "2025Q1", "FY2025")
    public let period: String
    /// The date this estimate was made or last updated
    public let estimateDate: Date
    /// Consensus earnings per share estimate
    public let consensusEPS: Double
    /// Highest analyst EPS estimate
    public let highEstimate: Double?
    /// Lowest analyst EPS estimate  
    public let lowEstimate: Double?
    /// Number of analysts providing estimates
    public let numberOfAnalysts: Int?
    /// Revenue estimate for the period
    public let revenueEstimate: Double?
    
    /// Creates a new earnings estimate.
    /// - Parameters:
    ///   - period: The forecast period
    ///   - estimateDate: When the estimate was made
    ///   - consensusEPS: Consensus EPS estimate (required)
    ///   - highEstimate: Highest EPS estimate (optional)
    ///   - lowEstimate: Lowest EPS estimate (optional)
    ///   - numberOfAnalysts: Number of analysts (optional)
    ///   - revenueEstimate: Revenue estimate (optional)
    public init(
        period: String,
        estimateDate: Date,
        consensusEPS: Double,
        highEstimate: Double? = nil,
        lowEstimate: Double? = nil,
        numberOfAnalysts: Int? = nil,
        revenueEstimate: Double? = nil
    ) {
        self.period = period
        self.estimateDate = estimateDate
        self.consensusEPS = consensusEPS
        self.highEstimate = highEstimate
        self.lowEstimate = lowEstimate
        self.numberOfAnalysts = numberOfAnalysts
        self.revenueEstimate = revenueEstimate
    }
}