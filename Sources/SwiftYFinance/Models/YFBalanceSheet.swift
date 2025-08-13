import Foundation

/// A container for balance sheet data from Yahoo Finance.
///
/// This structure holds both annual and quarterly balance sheet reports for a given ticker.
/// Balance sheets provide a snapshot of a company's financial position at a specific point
/// in time, showing assets, liabilities, and stockholder equity.
///
/// ## Related Types
/// - ``YFBalanceSheetReport``: Individual balance sheet report data
/// - ``YFTicker``: The stock ticker identifier
///
/// ## Usage Example
/// ```swift
/// let client = YFClient()
/// let ticker = try YFTicker(symbol: "AAPL")
/// let balanceSheet = try await client.fetchBalanceSheet(ticker: ticker)
///
/// for report in balanceSheet.annualReports {
///     print("Year: \(report.reportDate)")
///     print("Total Assets: $\(report.totalAssets! / 1_000_000_000)B")
///     print("Equity: $\(report.totalStockholderEquity / 1_000_000_000)B")
/// }
/// ```
public struct YFBalanceSheet: Codable {
    /// The ticker symbol this balance sheet data belongs to
    public let ticker: YFTicker
    /// Annual balance sheet reports, typically spanning multiple years
    public let annualReports: [YFBalanceSheetReport]
    /// Quarterly balance sheet reports for more granular analysis
    public let quarterlyReports: [YFBalanceSheetReport]
    
    /// Creates a new balance sheet data container.
    /// - Parameters:
    ///   - ticker: The ticker symbol
    ///   - annualReports: Array of annual balance sheet reports
    ///   - quarterlyReports: Array of quarterly reports (defaults to empty)
    public init(ticker: YFTicker, annualReports: [YFBalanceSheetReport], quarterlyReports: [YFBalanceSheetReport] = []) {
        self.ticker = ticker
        self.annualReports = annualReports
        self.quarterlyReports = quarterlyReports
    }
}

/// A single balance sheet report containing key financial position metrics.
///
/// This structure represents balance sheet data for a specific reporting period,
/// showing the company's assets, liabilities, and equity at a point in time.
/// All monetary values are in the reporting currency (typically USD) as absolute amounts.
///
/// ## Key Metrics
/// - **Total Current Assets**: Assets expected to be converted to cash within one year
/// - **Total Current Liabilities**: Debts due within one year
/// - **Total Stockholder Equity**: Owners' equity in the company
/// - **Retained Earnings**: Accumulated profits retained by the company
///
/// ## Usage Example
/// ```swift
/// let report = YFBalanceSheetReport(
///     reportDate: Date(),
///     totalCurrentAssets: 143_566_000_000,     // $143.6B
///     totalCurrentLiabilities: 153_982_000_000, // $154.0B
///     totalStockholderEquity: 62_146_000_000,   // $62.1B
///     retainedEarnings: 5_562_000_000           // $5.6B
/// )
/// print("Current Ratio: \(report.totalCurrentAssets / report.totalCurrentLiabilities)")
/// ```
public struct YFBalanceSheetReport: Codable {
    /// The date this balance sheet covers (typically end of fiscal period)
    public let reportDate: Date
    /// Current assets (cash, inventory, receivables expected to be converted within 1 year)
    public let totalCurrentAssets: Double
    /// Current liabilities (debts and obligations due within 1 year)
    public let totalCurrentLiabilities: Double
    /// Total stockholder equity (owners' residual interest in assets)
    public let totalStockholderEquity: Double
    /// Accumulated earnings retained by the company (not paid as dividends)
    public let retainedEarnings: Double
    /// Total assets owned by the company
    public let totalAssets: Double?
    /// Total liabilities owed by the company
    public let totalLiabilities: Double?
    /// Cash and cash equivalents
    public let cash: Double?
    /// Short-term investments that can be quickly converted to cash
    public let shortTermInvestments: Double?
    
    /// Creates a new balance sheet report.
    /// - Parameters:
    ///   - reportDate: The reporting period end date
    ///   - totalCurrentAssets: Current assets (required)
    ///   - totalCurrentLiabilities: Current liabilities (required)
    ///   - totalStockholderEquity: Stockholder equity (required)
    ///   - retainedEarnings: Retained earnings (required)
    ///   - totalAssets: Total assets (optional)
    ///   - totalLiabilities: Total liabilities (optional)
    ///   - cash: Cash position (optional)
    ///   - shortTermInvestments: Short-term investments (optional)
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