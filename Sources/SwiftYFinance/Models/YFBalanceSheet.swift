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

/// A single balance sheet report containing comprehensive financial position metrics.
///
/// This structure represents balance sheet data for a specific reporting period,
/// showing the company's assets, liabilities, and equity at a point in time.
/// All monetary values are in the reporting currency (typically USD) as absolute amounts.
/// Supports all 68 metrics available in yfinance-reference for complete compatibility.
///
/// ## Key Metrics Categories
/// - **Assets**: Total, current, non-current, PPE, investments, etc.
/// - **Liabilities**: Total, current, long-term, debt obligations, etc. 
/// - **Equity**: Stockholders equity, retained earnings, capital stock, etc.
/// - **Shares**: Outstanding shares, treasury shares, share counts, etc.
///
/// ## Usage Example
/// ```swift
/// let report = YFBalanceSheetReport(
///     reportDate: Date(),
///     totalAssets: 364_980_000_000,            // $365.0B
///     totalCurrentAssets: 143_566_000_000,     // $143.6B
///     totalCurrentLiabilities: 153_982_000_000, // $154.0B
///     stockholdersEquity: 56_950_000_000,       // $57.0B
///     retainedEarnings: -19_154_000_000         // -$19.2B
/// )
/// print("Current Ratio: \(report.totalCurrentAssets! / report.totalCurrentLiabilities!)")
/// ```
public struct YFBalanceSheetReport: Codable {
    /// The date this balance sheet covers (typically end of fiscal period)
    public let reportDate: Date
    
    // MARK: - Share Information
    /// Number of treasury shares held by the company
    public let treasurySharesNumber: Double?
    /// Number of preferred shares outstanding
    public let preferredSharesNumber: Double?
    /// Number of ordinary shares outstanding
    public let ordinarySharesNumber: Double?
    /// Total number of shares issued
    public let shareIssued: Double?
    
    // MARK: - Key Financial Ratios & Derived Metrics
    /// Net debt (Total debt minus cash)
    public let netDebt: Double?
    /// Total debt obligations
    public let totalDebt: Double?
    /// Tangible book value (shareholders equity minus intangible assets)
    public let tangibleBookValue: Double?
    /// Total invested capital
    public let investedCapital: Double?
    /// Working capital (current assets minus current liabilities)
    public let workingCapital: Double?
    /// Net tangible assets
    public let netTangibleAssets: Double?
    
    // MARK: - Equity Section
    /// Capital lease obligations
    public let capitalLeaseObligations: Double?
    /// Common stock equity
    public let commonStockEquity: Double?
    /// Preferred stock equity
    public let preferredStockEquity: Double?
    /// Total capitalization
    public let totalCapitalization: Double?
    /// Total equity gross minority interest
    public let totalEquityGrossMinorityInterest: Double?
    /// Minority interest
    public let minorityInterest: Double?
    /// Stockholders equity (owners' residual interest in assets)
    public let stockholdersEquity: Double?
    /// Other equity interest
    public let otherEquityInterest: Double?
    /// Gains/losses not affecting retained earnings
    public let gainsLossesNotAffectingRetainedEarnings: Double?
    /// Other equity adjustments
    public let otherEquityAdjustments: Double?
    /// Fixed assets revaluation reserve
    public let fixedAssetsRevaluationReserve: Double?
    /// Foreign currency translation adjustments
    public let foreignCurrencyTranslationAdjustments: Double?
    /// Minimum pension liabilities
    public let minimumPensionLiabilities: Double?
    /// Unrealized gain/loss
    public let unrealizedGainLoss: Double?
    /// Treasury stock
    public let treasuryStock: Double?
    /// Accumulated earnings retained by the company (not paid as dividends)
    public let retainedEarnings: Double?
    /// Additional paid-in capital
    public let additionalPaidInCapital: Double?
    /// Capital stock
    public let capitalStock: Double?
    /// Other capital stock
    public let otherCapitalStock: Double?
    /// Common stock
    public let commonStock: Double?
    /// Preferred stock
    public let preferredStock: Double?
    
    // MARK: - Partnership Capital (for partnerships)
    /// Total partnership capital
    public let totalPartnershipCapital: Double?
    /// General partnership capital
    public let generalPartnershipCapital: Double?
    /// Limited partnership capital
    public let limitedPartnershipCapital: Double?
    
    // MARK: - Liabilities Section
    /// Total liabilities net minority interest
    public let totalLiabilitiesNetMinorityInterest: Double?
    /// Total non-current liabilities net minority interest
    public let totalNonCurrentLiabilitiesNetMinorityInterest: Double?
    /// Other non-current liabilities
    public let otherNonCurrentLiabilities: Double?
    /// Liabilities held for sale (non-current)
    public let liabilitiesHeldforSaleNonCurrent: Double?
    /// Restricted common stock
    public let restrictedCommonStock: Double?
    /// Preferred securities outside stock equity
    public let preferredSecuritiesOutsideStockEquity: Double?
    /// Derivative product liabilities
    public let derivativeProductLiabilities: Double?
    /// Employee benefits
    public let employeeBenefits: Double?
    /// Non-current pension and other post-retirement benefit plans
    public let nonCurrentPensionAndOtherPostretirementBenefitPlans: Double?
    /// Non-current accrued expenses
    public let nonCurrentAccruedExpenses: Double?
    /// Due to related parties (non-current)
    public let duetoRelatedPartiesNonCurrent: Double?
    /// Trade and other payables (non-current)
    public let tradeandOtherPayablesNonCurrent: Double?
    /// Non-current deferred liabilities
    public let nonCurrentDeferredLiabilities: Double?
    /// Non-current deferred revenue
    public let nonCurrentDeferredRevenue: Double?
    /// Non-current deferred taxes liabilities
    public let nonCurrentDeferredTaxesLiabilities: Double?
    /// Long-term debt and capital lease obligation
    public let longTermDebtAndCapitalLeaseObligation: Double?
    /// Long-term capital lease obligation
    public let longTermCapitalLeaseObligation: Double?
    /// Long-term debt
    public let longTermDebt: Double?
    /// Long-term provisions
    public let longTermProvisions: Double?
    
    // MARK: - Current Liabilities
    /// Current liabilities (debts and obligations due within 1 year)
    public let currentLiabilities: Double?
    /// Other current liabilities
    public let otherCurrentLiabilities: Double?
    /// Current deferred liabilities
    public let currentDeferredLiabilities: Double?
    /// Current deferred revenue
    public let currentDeferredRevenue: Double?
    /// Current deferred taxes liabilities
    public let currentDeferredTaxesLiabilities: Double?
    /// Current debt and capital lease obligation
    public let currentDebtAndCapitalLeaseObligation: Double?
    /// Current capital lease obligation
    public let currentCapitalLeaseObligation: Double?
    /// Current debt
    public let currentDebt: Double?
    /// Other current borrowings
    public let otherCurrentBorrowings: Double?
    /// Line of credit
    public let lineOfCredit: Double?
    /// Commercial paper
    public let commercialPaper: Double?
    /// Current notes payable
    public let currentNotesPayable: Double?
    /// Pension and other post-retirement benefit plans (current)
    public let pensionandOtherPostRetirementBenefitPlansCurrent: Double?
    /// Current provisions
    public let currentProvisions: Double?
    /// Payables and accrued expenses
    public let payablesAndAccruedExpenses: Double?
    /// Current accrued expenses
    public let currentAccruedExpenses: Double?
    /// Interest payable
    public let interestPayable: Double?
    /// Payables
    public let payables: Double?
    /// Other payable
    public let otherPayable: Double?
    /// Due to related parties (current)
    public let duetoRelatedPartiesCurrent: Double?
    /// Dividends payable
    public let dividendsPayable: Double?
    /// Total tax payable
    public let totalTaxPayable: Double?
    /// Income tax payable
    public let incomeTaxPayable: Double?
    /// Accounts payable
    public let accountsPayable: Double?
    
    // MARK: - Assets Section
    /// Total assets owned by the company
    public let totalAssets: Double?
    /// Total non-current assets
    public let totalNonCurrentAssets: Double?
    /// Other non-current assets
    public let otherNonCurrentAssets: Double?
    /// Defined pension benefit
    public let definedPensionBenefit: Double?
    /// Non-current prepaid assets
    public let nonCurrentPrepaidAssets: Double?
    /// Non-current deferred assets
    public let nonCurrentDeferredAssets: Double?
    /// Non-current deferred taxes assets
    public let nonCurrentDeferredTaxesAssets: Double?
    /// Due from related parties (non-current)
    public let duefromRelatedPartiesNonCurrent: Double?
    /// Non-current note receivables
    public let nonCurrentNoteReceivables: Double?
    /// Non-current accounts receivable
    public let nonCurrentAccountsReceivable: Double?
    /// Financial assets
    public let financialAssets: Double?
    
    // MARK: - Investments
    /// Investments and advances
    public let investmentsAndAdvances: Double?
    /// Other investments
    public let otherInvestments: Double?
    /// Investment in financial assets
    public let investmentinFinancialAssets: Double?
    /// Held-to-maturity securities
    public let heldToMaturitySecurities: Double?
    /// Available-for-sale securities
    public let availableForSaleSecurities: Double?
    /// Financial assets designated as fair value through P&L
    public let financialAssetsDesignatedasFairValueThroughProfitorLossTotal: Double?
    /// Trading securities
    public let tradingSecurities: Double?
    /// Long-term equity investment
    public let longTermEquityInvestment: Double?
    /// Investments in joint ventures at cost
    public let investmentsinJointVenturesatCost: Double?
    /// Investments in other ventures under equity method
    public let investmentsInOtherVenturesUnderEquityMethod: Double?
    /// Investments in associates at cost
    public let investmentsinAssociatesatCost: Double?
    /// Investments in subsidiaries at cost
    public let investmentsinSubsidiariesatCost: Double?
    /// Investment properties
    public let investmentProperties: Double?
    
    // MARK: - Intangible Assets & PPE
    /// Goodwill and other intangible assets
    public let goodwillAndOtherIntangibleAssets: Double?
    /// Other intangible assets
    public let otherIntangibleAssets: Double?
    /// Goodwill
    public let goodwill: Double?
    /// Net property, plant & equipment
    public let netPPE: Double?
    /// Accumulated depreciation
    public let accumulatedDepreciation: Double?
    /// Gross property, plant & equipment
    public let grossPPE: Double?
    /// Leases
    public let leases: Double?
    /// Construction in progress
    public let constructionInProgress: Double?
    /// Other properties
    public let otherProperties: Double?
    /// Machinery, furniture & equipment
    public let machineryFurnitureEquipment: Double?
    /// Buildings and improvements
    public let buildingsAndImprovements: Double?
    /// Land and improvements
    public let landAndImprovements: Double?
    /// Properties
    public let properties: Double?
    
    // MARK: - Current Assets
    /// Current assets (cash, inventory, receivables expected to be converted within 1 year)
    public let currentAssets: Double?
    /// Other current assets
    public let otherCurrentAssets: Double?
    /// Hedging assets (current)
    public let hedgingAssetsCurrent: Double?
    /// Assets held for sale (current)
    public let assetsHeldForSaleCurrent: Double?
    /// Current deferred assets
    public let currentDeferredAssets: Double?
    /// Current deferred taxes assets
    public let currentDeferredTaxesAssets: Double?
    /// Restricted cash
    public let restrictedCash: Double?
    /// Prepaid assets
    public let prepaidAssets: Double?
    
    // MARK: - Inventory
    /// Inventory
    public let inventory: Double?
    /// Inventories adjustments/allowances
    public let inventoriesAdjustmentsAllowances: Double?
    /// Other inventories
    public let otherInventories: Double?
    /// Finished goods
    public let finishedGoods: Double?
    /// Work in process
    public let workInProcess: Double?
    /// Raw materials
    public let rawMaterials: Double?
    
    // MARK: - Receivables
    /// Receivables
    public let receivables: Double?
    /// Receivables adjustments/allowances
    public let receivablesAdjustmentsAllowances: Double?
    /// Other receivables
    public let otherReceivables: Double?
    /// Due from related parties (current)
    public let duefromRelatedPartiesCurrent: Double?
    /// Taxes receivable
    public let taxesReceivable: Double?
    /// Accrued interest receivable
    public let accruedInterestReceivable: Double?
    /// Notes receivable
    public let notesReceivable: Double?
    /// Loans receivable
    public let loansReceivable: Double?
    /// Accounts receivable
    public let accountsReceivable: Double?
    /// Allowance for doubtful accounts receivable
    public let allowanceForDoubtfulAccountsReceivable: Double?
    /// Gross accounts receivable
    public let grossAccountsReceivable: Double?
    
    // MARK: - Cash & Short-term Investments
    /// Cash, cash equivalents and short-term investments
    public let cashCashEquivalentsAndShortTermInvestments: Double?
    /// Other short-term investments
    public let otherShortTermInvestments: Double?
    /// Cash and cash equivalents
    public let cashAndCashEquivalents: Double?
    /// Cash equivalents
    public let cashEquivalents: Double?
    /// Cash (financial)
    public let cashFinancial: Double?
    /// Cash, cash equivalents and federal funds sold
    public let cashCashEquivalentsAndFederalFundsSold: Double?
    
    /// Creates a new comprehensive balance sheet report.
    /// - Parameters:
    ///   - reportDate: The reporting period end date
    ///   - All other parameters: Various balance sheet metrics (all optional except reportDate)
    public init(
        reportDate: Date,
        treasurySharesNumber: Double? = nil,
        preferredSharesNumber: Double? = nil,
        ordinarySharesNumber: Double? = nil,
        shareIssued: Double? = nil,
        netDebt: Double? = nil,
        totalDebt: Double? = nil,
        tangibleBookValue: Double? = nil,
        investedCapital: Double? = nil,
        workingCapital: Double? = nil,
        netTangibleAssets: Double? = nil,
        capitalLeaseObligations: Double? = nil,
        commonStockEquity: Double? = nil,
        preferredStockEquity: Double? = nil,
        totalCapitalization: Double? = nil,
        totalEquityGrossMinorityInterest: Double? = nil,
        minorityInterest: Double? = nil,
        stockholdersEquity: Double? = nil,
        otherEquityInterest: Double? = nil,
        gainsLossesNotAffectingRetainedEarnings: Double? = nil,
        otherEquityAdjustments: Double? = nil,
        fixedAssetsRevaluationReserve: Double? = nil,
        foreignCurrencyTranslationAdjustments: Double? = nil,
        minimumPensionLiabilities: Double? = nil,
        unrealizedGainLoss: Double? = nil,
        treasuryStock: Double? = nil,
        retainedEarnings: Double? = nil,
        additionalPaidInCapital: Double? = nil,
        capitalStock: Double? = nil,
        otherCapitalStock: Double? = nil,
        commonStock: Double? = nil,
        preferredStock: Double? = nil,
        totalPartnershipCapital: Double? = nil,
        generalPartnershipCapital: Double? = nil,
        limitedPartnershipCapital: Double? = nil,
        totalLiabilitiesNetMinorityInterest: Double? = nil,
        totalNonCurrentLiabilitiesNetMinorityInterest: Double? = nil,
        otherNonCurrentLiabilities: Double? = nil,
        liabilitiesHeldforSaleNonCurrent: Double? = nil,
        restrictedCommonStock: Double? = nil,
        preferredSecuritiesOutsideStockEquity: Double? = nil,
        derivativeProductLiabilities: Double? = nil,
        employeeBenefits: Double? = nil,
        nonCurrentPensionAndOtherPostretirementBenefitPlans: Double? = nil,
        nonCurrentAccruedExpenses: Double? = nil,
        duetoRelatedPartiesNonCurrent: Double? = nil,
        tradeandOtherPayablesNonCurrent: Double? = nil,
        nonCurrentDeferredLiabilities: Double? = nil,
        nonCurrentDeferredRevenue: Double? = nil,
        nonCurrentDeferredTaxesLiabilities: Double? = nil,
        longTermDebtAndCapitalLeaseObligation: Double? = nil,
        longTermCapitalLeaseObligation: Double? = nil,
        longTermDebt: Double? = nil,
        longTermProvisions: Double? = nil,
        currentLiabilities: Double? = nil,
        otherCurrentLiabilities: Double? = nil,
        currentDeferredLiabilities: Double? = nil,
        currentDeferredRevenue: Double? = nil,
        currentDeferredTaxesLiabilities: Double? = nil,
        currentDebtAndCapitalLeaseObligation: Double? = nil,
        currentCapitalLeaseObligation: Double? = nil,
        currentDebt: Double? = nil,
        otherCurrentBorrowings: Double? = nil,
        lineOfCredit: Double? = nil,
        commercialPaper: Double? = nil,
        currentNotesPayable: Double? = nil,
        pensionandOtherPostRetirementBenefitPlansCurrent: Double? = nil,
        currentProvisions: Double? = nil,
        payablesAndAccruedExpenses: Double? = nil,
        currentAccruedExpenses: Double? = nil,
        interestPayable: Double? = nil,
        payables: Double? = nil,
        otherPayable: Double? = nil,
        duetoRelatedPartiesCurrent: Double? = nil,
        dividendsPayable: Double? = nil,
        totalTaxPayable: Double? = nil,
        incomeTaxPayable: Double? = nil,
        accountsPayable: Double? = nil,
        totalAssets: Double? = nil,
        totalNonCurrentAssets: Double? = nil,
        otherNonCurrentAssets: Double? = nil,
        definedPensionBenefit: Double? = nil,
        nonCurrentPrepaidAssets: Double? = nil,
        nonCurrentDeferredAssets: Double? = nil,
        nonCurrentDeferredTaxesAssets: Double? = nil,
        duefromRelatedPartiesNonCurrent: Double? = nil,
        nonCurrentNoteReceivables: Double? = nil,
        nonCurrentAccountsReceivable: Double? = nil,
        financialAssets: Double? = nil,
        investmentsAndAdvances: Double? = nil,
        otherInvestments: Double? = nil,
        investmentinFinancialAssets: Double? = nil,
        heldToMaturitySecurities: Double? = nil,
        availableForSaleSecurities: Double? = nil,
        financialAssetsDesignatedasFairValueThroughProfitorLossTotal: Double? = nil,
        tradingSecurities: Double? = nil,
        longTermEquityInvestment: Double? = nil,
        investmentsinJointVenturesatCost: Double? = nil,
        investmentsInOtherVenturesUnderEquityMethod: Double? = nil,
        investmentsinAssociatesatCost: Double? = nil,
        investmentsinSubsidiariesatCost: Double? = nil,
        investmentProperties: Double? = nil,
        goodwillAndOtherIntangibleAssets: Double? = nil,
        otherIntangibleAssets: Double? = nil,
        goodwill: Double? = nil,
        netPPE: Double? = nil,
        accumulatedDepreciation: Double? = nil,
        grossPPE: Double? = nil,
        leases: Double? = nil,
        constructionInProgress: Double? = nil,
        otherProperties: Double? = nil,
        machineryFurnitureEquipment: Double? = nil,
        buildingsAndImprovements: Double? = nil,
        landAndImprovements: Double? = nil,
        properties: Double? = nil,
        currentAssets: Double? = nil,
        otherCurrentAssets: Double? = nil,
        hedgingAssetsCurrent: Double? = nil,
        assetsHeldForSaleCurrent: Double? = nil,
        currentDeferredAssets: Double? = nil,
        currentDeferredTaxesAssets: Double? = nil,
        restrictedCash: Double? = nil,
        prepaidAssets: Double? = nil,
        inventory: Double? = nil,
        inventoriesAdjustmentsAllowances: Double? = nil,
        otherInventories: Double? = nil,
        finishedGoods: Double? = nil,
        workInProcess: Double? = nil,
        rawMaterials: Double? = nil,
        receivables: Double? = nil,
        receivablesAdjustmentsAllowances: Double? = nil,
        otherReceivables: Double? = nil,
        duefromRelatedPartiesCurrent: Double? = nil,
        taxesReceivable: Double? = nil,
        accruedInterestReceivable: Double? = nil,
        notesReceivable: Double? = nil,
        loansReceivable: Double? = nil,
        accountsReceivable: Double? = nil,
        allowanceForDoubtfulAccountsReceivable: Double? = nil,
        grossAccountsReceivable: Double? = nil,
        cashCashEquivalentsAndShortTermInvestments: Double? = nil,
        otherShortTermInvestments: Double? = nil,
        cashAndCashEquivalents: Double? = nil,
        cashEquivalents: Double? = nil,
        cashFinancial: Double? = nil,
        cashCashEquivalentsAndFederalFundsSold: Double? = nil
    ) {
        self.reportDate = reportDate
        self.treasurySharesNumber = treasurySharesNumber
        self.preferredSharesNumber = preferredSharesNumber
        self.ordinarySharesNumber = ordinarySharesNumber
        self.shareIssued = shareIssued
        self.netDebt = netDebt
        self.totalDebt = totalDebt
        self.tangibleBookValue = tangibleBookValue
        self.investedCapital = investedCapital
        self.workingCapital = workingCapital
        self.netTangibleAssets = netTangibleAssets
        self.capitalLeaseObligations = capitalLeaseObligations
        self.commonStockEquity = commonStockEquity
        self.preferredStockEquity = preferredStockEquity
        self.totalCapitalization = totalCapitalization
        self.totalEquityGrossMinorityInterest = totalEquityGrossMinorityInterest
        self.minorityInterest = minorityInterest
        self.stockholdersEquity = stockholdersEquity
        self.otherEquityInterest = otherEquityInterest
        self.gainsLossesNotAffectingRetainedEarnings = gainsLossesNotAffectingRetainedEarnings
        self.otherEquityAdjustments = otherEquityAdjustments
        self.fixedAssetsRevaluationReserve = fixedAssetsRevaluationReserve
        self.foreignCurrencyTranslationAdjustments = foreignCurrencyTranslationAdjustments
        self.minimumPensionLiabilities = minimumPensionLiabilities
        self.unrealizedGainLoss = unrealizedGainLoss
        self.treasuryStock = treasuryStock
        self.retainedEarnings = retainedEarnings
        self.additionalPaidInCapital = additionalPaidInCapital
        self.capitalStock = capitalStock
        self.otherCapitalStock = otherCapitalStock
        self.commonStock = commonStock
        self.preferredStock = preferredStock
        self.totalPartnershipCapital = totalPartnershipCapital
        self.generalPartnershipCapital = generalPartnershipCapital
        self.limitedPartnershipCapital = limitedPartnershipCapital
        self.totalLiabilitiesNetMinorityInterest = totalLiabilitiesNetMinorityInterest
        self.totalNonCurrentLiabilitiesNetMinorityInterest = totalNonCurrentLiabilitiesNetMinorityInterest
        self.otherNonCurrentLiabilities = otherNonCurrentLiabilities
        self.liabilitiesHeldforSaleNonCurrent = liabilitiesHeldforSaleNonCurrent
        self.restrictedCommonStock = restrictedCommonStock
        self.preferredSecuritiesOutsideStockEquity = preferredSecuritiesOutsideStockEquity
        self.derivativeProductLiabilities = derivativeProductLiabilities
        self.employeeBenefits = employeeBenefits
        self.nonCurrentPensionAndOtherPostretirementBenefitPlans = nonCurrentPensionAndOtherPostretirementBenefitPlans
        self.nonCurrentAccruedExpenses = nonCurrentAccruedExpenses
        self.duetoRelatedPartiesNonCurrent = duetoRelatedPartiesNonCurrent
        self.tradeandOtherPayablesNonCurrent = tradeandOtherPayablesNonCurrent
        self.nonCurrentDeferredLiabilities = nonCurrentDeferredLiabilities
        self.nonCurrentDeferredRevenue = nonCurrentDeferredRevenue
        self.nonCurrentDeferredTaxesLiabilities = nonCurrentDeferredTaxesLiabilities
        self.longTermDebtAndCapitalLeaseObligation = longTermDebtAndCapitalLeaseObligation
        self.longTermCapitalLeaseObligation = longTermCapitalLeaseObligation
        self.longTermDebt = longTermDebt
        self.longTermProvisions = longTermProvisions
        self.currentLiabilities = currentLiabilities
        self.otherCurrentLiabilities = otherCurrentLiabilities
        self.currentDeferredLiabilities = currentDeferredLiabilities
        self.currentDeferredRevenue = currentDeferredRevenue
        self.currentDeferredTaxesLiabilities = currentDeferredTaxesLiabilities
        self.currentDebtAndCapitalLeaseObligation = currentDebtAndCapitalLeaseObligation
        self.currentCapitalLeaseObligation = currentCapitalLeaseObligation
        self.currentDebt = currentDebt
        self.otherCurrentBorrowings = otherCurrentBorrowings
        self.lineOfCredit = lineOfCredit
        self.commercialPaper = commercialPaper
        self.currentNotesPayable = currentNotesPayable
        self.pensionandOtherPostRetirementBenefitPlansCurrent = pensionandOtherPostRetirementBenefitPlansCurrent
        self.currentProvisions = currentProvisions
        self.payablesAndAccruedExpenses = payablesAndAccruedExpenses
        self.currentAccruedExpenses = currentAccruedExpenses
        self.interestPayable = interestPayable
        self.payables = payables
        self.otherPayable = otherPayable
        self.duetoRelatedPartiesCurrent = duetoRelatedPartiesCurrent
        self.dividendsPayable = dividendsPayable
        self.totalTaxPayable = totalTaxPayable
        self.incomeTaxPayable = incomeTaxPayable
        self.accountsPayable = accountsPayable
        self.totalAssets = totalAssets
        self.totalNonCurrentAssets = totalNonCurrentAssets
        self.otherNonCurrentAssets = otherNonCurrentAssets
        self.definedPensionBenefit = definedPensionBenefit
        self.nonCurrentPrepaidAssets = nonCurrentPrepaidAssets
        self.nonCurrentDeferredAssets = nonCurrentDeferredAssets
        self.nonCurrentDeferredTaxesAssets = nonCurrentDeferredTaxesAssets
        self.duefromRelatedPartiesNonCurrent = duefromRelatedPartiesNonCurrent
        self.nonCurrentNoteReceivables = nonCurrentNoteReceivables
        self.nonCurrentAccountsReceivable = nonCurrentAccountsReceivable
        self.financialAssets = financialAssets
        self.investmentsAndAdvances = investmentsAndAdvances
        self.otherInvestments = otherInvestments
        self.investmentinFinancialAssets = investmentinFinancialAssets
        self.heldToMaturitySecurities = heldToMaturitySecurities
        self.availableForSaleSecurities = availableForSaleSecurities
        self.financialAssetsDesignatedasFairValueThroughProfitorLossTotal = financialAssetsDesignatedasFairValueThroughProfitorLossTotal
        self.tradingSecurities = tradingSecurities
        self.longTermEquityInvestment = longTermEquityInvestment
        self.investmentsinJointVenturesatCost = investmentsinJointVenturesatCost
        self.investmentsInOtherVenturesUnderEquityMethod = investmentsInOtherVenturesUnderEquityMethod
        self.investmentsinAssociatesatCost = investmentsinAssociatesatCost
        self.investmentsinSubsidiariesatCost = investmentsinSubsidiariesatCost
        self.investmentProperties = investmentProperties
        self.goodwillAndOtherIntangibleAssets = goodwillAndOtherIntangibleAssets
        self.otherIntangibleAssets = otherIntangibleAssets
        self.goodwill = goodwill
        self.netPPE = netPPE
        self.accumulatedDepreciation = accumulatedDepreciation
        self.grossPPE = grossPPE
        self.leases = leases
        self.constructionInProgress = constructionInProgress
        self.otherProperties = otherProperties
        self.machineryFurnitureEquipment = machineryFurnitureEquipment
        self.buildingsAndImprovements = buildingsAndImprovements
        self.landAndImprovements = landAndImprovements
        self.properties = properties
        self.currentAssets = currentAssets
        self.otherCurrentAssets = otherCurrentAssets
        self.hedgingAssetsCurrent = hedgingAssetsCurrent
        self.assetsHeldForSaleCurrent = assetsHeldForSaleCurrent
        self.currentDeferredAssets = currentDeferredAssets
        self.currentDeferredTaxesAssets = currentDeferredTaxesAssets
        self.restrictedCash = restrictedCash
        self.prepaidAssets = prepaidAssets
        self.inventory = inventory
        self.inventoriesAdjustmentsAllowances = inventoriesAdjustmentsAllowances
        self.otherInventories = otherInventories
        self.finishedGoods = finishedGoods
        self.workInProcess = workInProcess
        self.rawMaterials = rawMaterials
        self.receivables = receivables
        self.receivablesAdjustmentsAllowances = receivablesAdjustmentsAllowances
        self.otherReceivables = otherReceivables
        self.duefromRelatedPartiesCurrent = duefromRelatedPartiesCurrent
        self.taxesReceivable = taxesReceivable
        self.accruedInterestReceivable = accruedInterestReceivable
        self.notesReceivable = notesReceivable
        self.loansReceivable = loansReceivable
        self.accountsReceivable = accountsReceivable
        self.allowanceForDoubtfulAccountsReceivable = allowanceForDoubtfulAccountsReceivable
        self.grossAccountsReceivable = grossAccountsReceivable
        self.cashCashEquivalentsAndShortTermInvestments = cashCashEquivalentsAndShortTermInvestments
        self.otherShortTermInvestments = otherShortTermInvestments
        self.cashAndCashEquivalents = cashAndCashEquivalents
        self.cashEquivalents = cashEquivalents
        self.cashFinancial = cashFinancial
        self.cashCashEquivalentsAndFederalFundsSold = cashCashEquivalentsAndFederalFundsSold
    }
}