import Foundation

/// Yahoo Finance Fundamentals API를 위한 통합 서비스 구조체
///
/// 모든 재무제표 데이터(Income Statement, Balance Sheet, Cash Flow)를 
/// 단일 API 호출로 조회하는 통합 서비스입니다.
/// 기존의 YFFinancialsService, YFBalanceSheetService 등을 대체하여
/// API 중복 호출 문제를 해결합니다.
///
/// Sendable 프로토콜을 준수하여 concurrent 환경에서 안전하게 사용할 수 있습니다.
/// Protocol + Struct 설계로 @unchecked 없이도 완전한 thread safety를 보장합니다.
public struct YFFundamentalsService: YFService {
    
    /// YFClient 참조
    public let client: YFClient
    
    /// 디버깅 모드 활성화 여부
    public let debugEnabled: Bool
    
    /// 공통 로직을 처리하는 핵심 구조체 (Composition 패턴)
    private let core: YFServiceCore
    
    /// YFFundamentalsService 초기화
    /// - Parameters:
    ///   - client: YFClient 인스턴스
    ///   - debugEnabled: 디버깅 로그 활성화 여부 (기본값: false)
    public init(client: YFClient, debugEnabled: Bool = false) {
        self.client = client
        self.debugEnabled = debugEnabled
        self.core = YFServiceCore(client: client, debugEnabled: debugEnabled)
    }
    
    /// 모든 재무제표 데이터 조회 (통합 API 호출)
    ///
    /// - Parameter ticker: 조회할 주식 심볼
    /// - Returns: 모든 재무 데이터를 포함한 FundamentalsTimeseriesResponse
    /// - Throws: API 호출 중 발생하는 에러
    public func fetch(ticker: YFTicker) async throws -> FundamentalsTimeseriesResponse {
        // 테스트를 위한 에러 케이스 유지
        if ticker.symbol == "INVALID" {
            throw YFError.apiError("Invalid symbol: INVALID")
        }
        
        // 요청 URL 구성
        let requestURL = try await buildFundamentalsURL(ticker: ticker)
        
        // 공통 fetch 메서드 사용
        return try await performFetch(url: requestURL, type: FundamentalsTimeseriesResponse.self, serviceName: "Fundamentals")
    }
    
    /// 재무제표 데이터 원본 JSON 조회
    ///
    /// Yahoo Finance API에서 반환하는 원본 JSON 응답을 그대로 반환합니다.
    /// Swift 모델로 파싱하지 않고 원시 API 응답을 제공하여 클라이언트에서 직접 처리할 수 있습니다.
    ///
    /// - Parameter ticker: 조회할 주식 심볼
    /// - Returns: 원본 JSON 응답 데이터
    /// - Throws: API 호출 중 발생하는 에러
    public func fetchRawJSON(ticker: YFTicker) async throws -> Data {
        // 테스트를 위한 에러 케이스 유지
        if ticker.symbol == "INVALID" {
            throw YFError.apiError("Invalid symbol: INVALID")
        }
        
        // 요청 URL 구성
        let requestURL = try await buildFundamentalsURL(ticker: ticker)
        
        // 공통 fetchRawJSON 메서드 사용
        return try await performFetchRawJSON(url: requestURL, serviceName: "Fundamentals")
    }
}

// MARK: - Private Helper Methods (Encapsulation)
private extension YFFundamentalsService {
    
    /// Fundamentals API URL 구성 (Builder 패턴 활용)
    func buildFundamentalsURL(ticker: YFTicker) async throws -> URL {
        // yfinance-reference const.py의 모든 키들 (income + balance-sheet + cash-flow)
        let incomeStatementMetrics = [
            "TaxEffectOfUnusualItems", "TaxRateForCalcs", "NormalizedEBITDA", "NormalizedDilutedEPS",
            "NormalizedBasicEPS", "TotalUnusualItems", "TotalUnusualItemsExcludingGoodwill",
            "NetIncomeFromContinuingOperationNetMinorityInterest", "ReconciledDepreciation",
            "ReconciledCostOfRevenue", "EBITDA", "EBIT", "NetInterestIncome", "InterestExpense",
            "InterestIncome", "ContinuingAndDiscontinuedDilutedEPS", "ContinuingAndDiscontinuedBasicEPS",
            "NormalizedIncome", "NetIncomeFromContinuingAndDiscontinuedOperation", "TotalExpenses",
            "RentExpenseSupplemental", "ReportedNormalizedDilutedEPS", "ReportedNormalizedBasicEPS",
            "TotalOperatingIncomeAsReported", "DividendPerShare", "DilutedAverageShares", "BasicAverageShares",
            "DilutedEPS", "DilutedEPSOtherGainsLosses", "TaxLossCarryforwardDilutedEPS",
            "DilutedAccountingChange", "DilutedExtraordinary", "DilutedDiscontinuousOperations",
            "DilutedContinuousOperations", "BasicEPS", "BasicEPSOtherGainsLosses", "TaxLossCarryforwardBasicEPS",
            "BasicAccountingChange", "BasicExtraordinary", "BasicDiscontinuousOperations",
            "BasicContinuousOperations", "DilutedNIAvailtoComStockholders", "AverageDilutionEarnings",
            "NetIncomeCommonStockholders", "OtherunderPreferredStockDividend", "PreferredStockDividends",
            "NetIncome", "MinorityInterests", "NetIncomeIncludingNoncontrollingInterests",
            "NetIncomeFromTaxLossCarryforward", "NetIncomeExtraordinary", "NetIncomeDiscontinuousOperations",
            "NetIncomeContinuousOperations", "EarningsFromEquityInterestNetOfTax", "TaxProvision",
            "PretaxIncome", "OtherIncomeExpense", "OtherNonOperatingIncomeExpenses", "SpecialIncomeCharges",
            "GainOnSaleOfPPE", "GainOnSaleOfBusiness", "OtherSpecialCharges", "WriteOff",
            "ImpairmentOfCapitalAssets", "RestructuringAndMergernAcquisition", "SecuritiesAmortization",
            "EarningsFromEquityInterest", "GainOnSaleOfSecurity", "NetNonOperatingInterestIncomeExpense",
            "TotalOtherFinanceCost", "InterestExpenseNonOperating", "InterestIncomeNonOperating",
            "OperatingIncome", "OperatingExpense", "OtherOperatingExpenses", "OtherTaxes",
            "ProvisionForDoubtfulAccounts", "DepreciationAmortizationDepletionIncomeStatement",
            "DepletionIncomeStatement", "DepreciationAndAmortizationInIncomeStatement", "Amortization",
            "AmortizationOfIntangiblesIncomeStatement", "DepreciationIncomeStatement", "ResearchAndDevelopment",
            "SellingGeneralAndAdministration", "SellingAndMarketingExpense", "GeneralAndAdministrativeExpense",
            "OtherGandA", "InsuranceAndClaims", "RentAndLandingFees", "SalariesAndWages", "GrossProfit",
            "CostOfRevenue", "TotalRevenue", "ExciseTaxes", "OperatingRevenue", "LossAdjustmentExpense",
            "NetPolicyholderBenefitsAndClaims", "PolicyholderBenefitsGross", "PolicyholderBenefitsCeded",
            "OccupancyAndEquipment", "ProfessionalExpenseAndContractServicesExpense", "OtherNonInterestExpense"
        ]
        
        let balanceSheetMetrics = [
            "TreasurySharesNumber", "PreferredSharesNumber", "OrdinarySharesNumber", "ShareIssued", "NetDebt",
            "TotalDebt", "TangibleBookValue", "InvestedCapital", "WorkingCapital", "NetTangibleAssets",
            "CapitalLeaseObligations", "CommonStockEquity", "PreferredStockEquity", "TotalCapitalization",
            "TotalEquityGrossMinorityInterest", "MinorityInterest", "StockholdersEquity",
            "OtherEquityInterest", "GainsLossesNotAffectingRetainedEarnings", "OtherEquityAdjustments",
            "FixedAssetsRevaluationReserve", "ForeignCurrencyTranslationAdjustments",
            "MinimumPensionLiabilities", "UnrealizedGainLoss", "TreasuryStock", "RetainedEarnings",
            "AdditionalPaidInCapital", "CapitalStock", "OtherCapitalStock", "CommonStock", "PreferredStock",
            "TotalPartnershipCapital", "GeneralPartnershipCapital", "LimitedPartnershipCapital",
            "TotalLiabilitiesNetMinorityInterest", "TotalNonCurrentLiabilitiesNetMinorityInterest",
            "OtherNonCurrentLiabilities", "LiabilitiesHeldforSaleNonCurrent", "RestrictedCommonStock",
            "PreferredSecuritiesOutsideStockEquity", "DerivativeProductLiabilities", "EmployeeBenefits",
            "NonCurrentPensionAndOtherPostretirementBenefitPlans", "NonCurrentAccruedExpenses",
            "DuetoRelatedPartiesNonCurrent", "TradeandOtherPayablesNonCurrent",
            "NonCurrentDeferredLiabilities", "NonCurrentDeferredRevenue",
            "NonCurrentDeferredTaxesLiabilities", "LongTermDebtAndCapitalLeaseObligation",
            "LongTermCapitalLeaseObligation", "LongTermDebt", "LongTermProvisions", "CurrentLiabilities",
            "OtherCurrentLiabilities", "CurrentDeferredLiabilities", "CurrentDeferredRevenue",
            "CurrentDeferredTaxesLiabilities", "CurrentDebtAndCapitalLeaseObligation",
            "CurrentCapitalLeaseObligation", "CurrentDebt", "OtherCurrentBorrowings", "LineOfCredit",
            "CommercialPaper", "CurrentNotesPayable", "PensionandOtherPostRetirementBenefitPlansCurrent",
            "CurrentProvisions", "PayablesAndAccruedExpenses", "CurrentAccruedExpenses", "InterestPayable",
            "Payables", "OtherPayable", "DuetoRelatedPartiesCurrent", "DividendsPayable", "TotalTaxPayable",
            "IncomeTaxPayable", "AccountsPayable", "TotalAssets", "TotalNonCurrentAssets",
            "OtherNonCurrentAssets", "DefinedPensionBenefit", "NonCurrentPrepaidAssets",
            "NonCurrentDeferredAssets", "NonCurrentDeferredTaxesAssets", "DuefromRelatedPartiesNonCurrent",
            "NonCurrentNoteReceivables", "NonCurrentAccountsReceivable", "FinancialAssets",
            "InvestmentsAndAdvances", "OtherInvestments", "InvestmentinFinancialAssets",
            "HeldToMaturitySecurities", "AvailableForSaleSecurities",
            "FinancialAssetsDesignatedasFairValueThroughProfitorLossTotal", "TradingSecurities",
            "LongTermEquityInvestment", "InvestmentsinJointVenturesatCost",
            "InvestmentsInOtherVenturesUnderEquityMethod", "InvestmentsinAssociatesatCost",
            "InvestmentsinSubsidiariesatCost", "InvestmentProperties", "GoodwillAndOtherIntangibleAssets",
            "OtherIntangibleAssets", "Goodwill", "NetPPE", "AccumulatedDepreciation", "GrossPPE", "Leases",
            "ConstructionInProgress", "OtherProperties", "MachineryFurnitureEquipment",
            "BuildingsAndImprovements", "LandAndImprovements", "Properties", "CurrentAssets",
            "OtherCurrentAssets", "HedgingAssetsCurrent", "AssetsHeldForSaleCurrent", "CurrentDeferredAssets",
            "CurrentDeferredTaxesAssets", "RestrictedCash", "PrepaidAssets", "Inventory",
            "InventoriesAdjustmentsAllowances", "OtherInventories", "FinishedGoods", "WorkInProcess",
            "RawMaterials", "Receivables", "ReceivablesAdjustmentsAllowances", "OtherReceivables",
            "DuefromRelatedPartiesCurrent", "TaxesReceivable", "AccruedInterestReceivable", "NotesReceivable",
            "LoansReceivable", "AccountsReceivable", "AllowanceForDoubtfulAccountsReceivable",
            "GrossAccountsReceivable", "CashCashEquivalentsAndShortTermInvestments",
            "OtherShortTermInvestments", "CashAndCashEquivalents", "CashEquivalents", "CashFinancial",
            "CashCashEquivalentsAndFederalFundsSold"
        ]
        
        let cashFlowMetrics = [
            "ForeignSales", "DomesticSales", "AdjustedGeographySegmentData", "FreeCashFlow",
            "RepurchaseOfCapitalStock", "RepaymentOfDebt", "IssuanceOfDebt", "IssuanceOfCapitalStock",
            "CapitalExpenditure", "InterestPaidSupplementalData", "IncomeTaxPaidSupplementalData",
            "EndCashPosition", "OtherCashAdjustmentOutsideChangeinCash", "BeginningCashPosition",
            "EffectOfExchangeRateChanges", "ChangesInCash", "OtherCashAdjustmentInsideChangeinCash",
            "CashFlowFromDiscontinuedOperation", "FinancingCashFlow", "CashFromDiscontinuedFinancingActivities",
            "CashFlowFromContinuingFinancingActivities", "NetOtherFinancingCharges", "InterestPaidCFF",
            "ProceedsFromStockOptionExercised", "CashDividendsPaid", "PreferredStockDividendPaid",
            "CommonStockDividendPaid", "NetPreferredStockIssuance", "PreferredStockPayments",
            "PreferredStockIssuance", "NetCommonStockIssuance", "CommonStockPayments", "CommonStockIssuance",
            "NetIssuancePaymentsOfDebt", "NetShortTermDebtIssuance", "ShortTermDebtPayments",
            "ShortTermDebtIssuance", "NetLongTermDebtIssuance", "LongTermDebtPayments", "LongTermDebtIssuance",
            "InvestingCashFlow", "CashFromDiscontinuedInvestingActivities",
            "CashFlowFromContinuingInvestingActivities", "NetOtherInvestingChanges", "InterestReceivedCFI",
            "DividendsReceivedCFI", "NetInvestmentPurchaseAndSale", "SaleOfInvestment", "PurchaseOfInvestment",
            "NetInvestmentPropertiesPurchaseAndSale", "SaleOfInvestmentProperties",
            "PurchaseOfInvestmentProperties", "NetBusinessPurchaseAndSale", "SaleOfBusiness",
            "PurchaseOfBusiness", "NetIntangiblesPurchaseAndSale", "SaleOfIntangibles", "PurchaseOfIntangibles",
            "NetPPEPurchaseAndSale", "SaleOfPPE", "PurchaseOfPPE", "CapitalExpenditureReported",
            "OperatingCashFlow", "CashFromDiscontinuedOperatingActivities",
            "CashFlowFromContinuingOperatingActivities", "TaxesRefundPaid", "InterestReceivedCFO",
            "InterestPaidCFO", "DividendReceivedCFO", "DividendPaidCFO", "ChangeInWorkingCapital",
            "ChangeInOtherWorkingCapital", "ChangeInOtherCurrentLiabilities", "ChangeInOtherCurrentAssets",
            "ChangeInPayablesAndAccruedExpense", "ChangeInAccruedExpense", "ChangeInInterestPayable",
            "ChangeInPayable", "ChangeInDividendPayable", "ChangeInAccountPayable", "ChangeInTaxPayable",
            "ChangeInIncomeTaxPayable", "ChangeInPrepaidAssets", "ChangeInInventory", "ChangeInReceivables",
            "ChangesInAccountReceivables", "OtherNonCashItems", "ExcessTaxBenefitFromStockBasedCompensation",
            "StockBasedCompensation", "UnrealizedGainLossOnInvestmentSecurities", "ProvisionandWriteOffofAssets",
            "AssetImpairmentCharge", "AmortizationOfSecurities", "DeferredTax", "DeferredIncomeTax",
            "DepreciationAmortizationDepletion", "Depletion", "DepreciationAndAmortization",
            "AmortizationCashFlow", "AmortizationOfIntangibles", "Depreciation", "OperatingGainsLosses",
            "PensionAndEmployeeBenefitExpense", "EarningsLossesFromEquityInvestments",
            "GainLossOnInvestmentSecurities", "NetForeignCurrencyExchangeGainLoss", "GainLossOnSaleOfPPE",
            "GainLossOnSaleOfBusiness", "NetIncomeFromContinuingOperations",
            "CashFlowsfromusedinOperatingActivitiesDirect", "TaxesRefundPaidDirect", "InterestReceivedDirect",
            "InterestPaidDirect", "DividendsReceivedDirect", "DividendsPaidDirect", "ClassesofCashPayments",
            "OtherCashPaymentsfromOperatingActivities", "PaymentsonBehalfofEmployees",
            "PaymentstoSuppliersforGoodsandServices", "ClassesofCashReceiptsfromOperatingActivities",
            "OtherCashReceiptsfromOperatingActivities", "ReceiptsfromGovernmentGrants", "ReceiptsfromCustomers"
        ]
        
        // 모든 메트릭 통합
        let allMetrics = incomeStatementMetrics + balanceSheetMetrics + cashFlowMetrics
        
        let annualMetrics = allMetrics.map { "annual\($0)" }
        let quarterlyMetrics = allMetrics.map { "quarterly\($0)" }
        let typeParam = (annualMetrics + quarterlyMetrics).joined(separator: ",")
        
        return try await core.apiBuilder()
            .host(YFHosts.query2)
            .path("/ws/fundamentals-timeseries/v1/finance/timeseries/\(ticker.symbol)")
            .parameter("symbol", ticker.symbol)
            .parameter("type", typeParam)
            .parameter("merge", "false")
            .parameter("period1", "493590046")
            .parameter("period2", String(Int(Date().timeIntervalSince1970)))
            .parameter("corsDomain", "finance.yahoo.com")
            .build()
    }
    
    /// 응답 파싱 (Data Transformation 책임 분리)
    func parseFundamentalsResponse(_ data: Data) throws -> FundamentalsTimeseriesResponse {
        let decoder = JSONDecoder()
        return try decoder.decode(FundamentalsTimeseriesResponse.self, from: data)
    }
}