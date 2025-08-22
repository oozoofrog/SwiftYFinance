import Foundation

/// A container for comprehensive financial statement data from Yahoo Finance.
///
/// This structure holds both annual and quarterly financial reports for a given ticker,
/// providing key metrics from income statements and other financial statements.
/// Financial data includes revenue, income, assets, liabilities, and other core metrics
/// that analysts use to evaluate company performance.
///
/// ## Related Types
/// - ``YFFinancialReport``: Individual financial statement data
/// - ``YFTicker``: The stock ticker identifier
///
/// ## Usage Example
/// ```swift
/// let client = YFClient()
/// let ticker = try YFTicker(symbol: "AAPL")
/// let financials = try await client.fetchFinancials(ticker: ticker)
///
/// for report in financials.annualReports {
///     print("Year: \(report.reportDate)")
///     print("Revenue: $\(report.totalRevenue / 1_000_000_000)B")
///     print("Net Income: $\(report.netIncome / 1_000_000_000)B")
/// }
/// ```
public struct YFFinancials: Codable {
    /// The ticker symbol this financial data belongs to
    public let ticker: YFTicker
    /// Annual financial reports, typically spanning multiple years
    public let annualReports: [YFFinancialReport]
    /// Quarterly financial reports for more granular analysis
    public let quarterlyReports: [YFFinancialReport]
    
    /// Creates a new financial data container.
    /// - Parameters:
    ///   - ticker: The ticker symbol
    ///   - annualReports: Array of annual financial reports
    ///   - quarterlyReports: Array of quarterly reports (defaults to empty)
    public init(ticker: YFTicker, annualReports: [YFFinancialReport], quarterlyReports: [YFFinancialReport] = []) {
        self.ticker = ticker
        self.annualReports = annualReports
        self.quarterlyReports = quarterlyReports
    }
}

/// A single comprehensive financial report containing key financial metrics.
///
/// This structure represents financial data for a specific reporting period,
/// including revenue, income, assets, and liabilities from various financial statements.
/// All monetary values are in the reporting currency (typically USD) as absolute amounts.
///
/// ## Key Metrics
/// - **Total Revenue**: Total sales/revenue for the period
/// - **Net Income**: Bottom-line profit after all expenses
/// - **Total Assets**: All assets owned by the company
/// - **Total Liabilities**: All debts and obligations owed by the company
///
/// ## Usage Example
/// ```swift
/// let report = YFFinancialReport(
///     reportDate: Date(),
///     totalRevenue: 394_328_000_000,  // $394.3B
///     netIncome: 99_803_000_000,      // $99.8B
///     totalAssets: 352_755_000_000,   // $352.8B
///     totalLiabilities: 290_437_000_000 // $290.4B
/// )
/// print("ROA: \(report.netIncome / report.totalAssets * 100)%")
/// ```
public struct YFFinancialReport: Codable {
    /// The date this financial report covers (typically end of fiscal period)
    public let reportDate: Date
    /// Total revenue/sales for the period (always present)
    public let totalRevenue: Double
    /// Net income after all expenses and taxes (always present)
    public let netIncome: Double
    /// Total assets owned by the company (always present)
    public let totalAssets: Double
    /// Total liabilities and debts owed by the company (always present)
    public let totalLiabilities: Double
    /// Gross profit (revenue minus cost of goods sold)
    public let grossProfit: Double?
    /// Operating income before interest and taxes
    public let operatingIncome: Double?
    /// Total cash and cash equivalents
    public let totalCash: Double?
    /// Total debt obligations (short-term + long-term)
    public let totalDebt: Double?
    
    /// Creates a new financial report.
    /// - Parameters:
    ///   - reportDate: The reporting period end date
    ///   - totalRevenue: Total revenue for the period (required)
    ///   - netIncome: Net income for the period (required)
    ///   - totalAssets: Total assets (required)
    ///   - totalLiabilities: Total liabilities (required)
    ///   - grossProfit: Gross profit (optional)
    ///   - operatingIncome: Operating income (optional)
    ///   - totalCash: Total cash position (optional)
    ///   - totalDebt: Total debt obligations (optional)
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