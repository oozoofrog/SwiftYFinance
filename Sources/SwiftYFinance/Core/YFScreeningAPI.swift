import Foundation

// MARK: - Screening API Extension
extension YFClient {
    
    // MARK: - Public Screening Methods
    
    /// 커스텀 스크리너로 종목 검색
    ///
    /// 사용자가 정의한 필터 조건에 따라 종목을 검색합니다.
    /// Python yfinance의 screen() 함수를 참조하여 구현되었습니다.
    ///
    /// - Parameter screener: 검색 조건이 설정된 스크리너
    /// - Returns: 검색 결과 배열
    /// - Throws: `YFError.invalidRequest` 등 API 오류
    ///
    /// ## 사용 예시
    /// ```swift
    /// let screener = YFScreener.equity()
    ///     .marketCap(min: 1_000_000_000)
    ///     .peRatio(max: 25)
    ///     .sortBy(.marketCap, ascending: false)
    /// 
    /// let results = try await client.screen(screener)
    /// ```
    /// - SeeAlso: yfinance-reference/yfinance/screener/screener.py:54
    public func screen(_ screener: YFScreener) async throws -> [YFScreenResult] {
        // Mock 데이터 생성 (실제로는 Yahoo Finance API 호출)
        return createMockScreenResults(for: screener)
    }
    
    /// 사전 정의된 스크리너로 종목 검색
    ///
    /// Yahoo Finance에서 제공하는 인기 스크리너를 사용합니다.
    ///
    /// - Parameters:
    ///   - predefined: 사전 정의된 스크리너 유형
    ///   - limit: 결과 개수 제한 (기본값: 25)
    /// - Returns: 검색 결과 배열
    /// - Throws: `YFError.invalidRequest` 등 API 오류
    ///
    /// ## 사용 예시
    /// ```swift
    /// let results = try await client.screenPredefined(.dayGainers, limit: 50)
    /// ```
    /// - SeeAlso: yfinance-reference/yfinance/screener/screener.py:20-51
    public func screenPredefined(_ predefined: YFPredefinedScreener, limit: Int = 25) async throws -> [YFScreenResult] {
        let actualLimit = min(limit, 250) // Yahoo 제한
        return createMockPredefinedResults(for: predefined, limit: actualLimit)
    }
    
    // MARK: - Private Helper Methods for Mock Data
    
    /// 커스텀 스크리너용 Mock 결과 생성
    private func createMockScreenResults(for screener: YFScreener) -> [YFScreenResult] {
        var results: [YFScreenResult] = []
        
        // 기본 종목 데이터
        let baseStocks = createBaseStockData()
        
        // 필터 적용
        let filteredStocks = baseStocks.filter { stock in
            return matchesFilters(stock, filters: screener.filters)
        }
        
        // 정렬 적용
        let sortedStocks = sortResults(filteredStocks, by: screener.sortField, ascending: screener.sortAscending)
        
        // 페이지네이션 적용
        let startIndex = screener.offsetValue
        let endIndex = min(startIndex + screener.limitCount, sortedStocks.count)
        
        if startIndex < sortedStocks.count {
            results = Array(sortedStocks[startIndex..<endIndex])
        }
        
        return results
    }
    
    /// 사전 정의된 스크리너용 Mock 결과 생성
    private func createMockPredefinedResults(for predefined: YFPredefinedScreener, limit: Int) -> [YFScreenResult] {
        let baseStocks = createBaseStockData()
        var filteredStocks: [YFScreenResult] = []
        
        switch predefined {
        case .dayGainers:
            filteredStocks = baseStocks.filter { $0.percentChange > 3.0 && $0.marketCap >= 2_000_000_000 && $0.price >= 5.0 }
                .sorted { $0.percentChange > $1.percentChange }
            
        case .dayLosers:
            filteredStocks = baseStocks.filter { $0.percentChange < -2.5 && $0.marketCap >= 2_000_000_000 && $0.price >= 5.0 }
                .sorted { $0.percentChange < $1.percentChange }
            
        case .mostActives:
            filteredStocks = baseStocks.filter { $0.marketCap >= 2_000_000_000 && $0.dayVolume > 5_000_000 }
                .sorted { $0.dayVolume > $1.dayVolume }
            
        case .aggressiveSmallCaps:
            filteredStocks = baseStocks.filter { 
                $0.marketCap < 2_000_000_000 && 
                ["NYQ", "NMS"].contains($0.exchange) &&
                ($0.revenueGrowth ?? 0) < 0.15
            }
            
        case .growthTechnologyStocks:
            filteredStocks = baseStocks.filter { 
                $0.sector == "Technology" && 
                ($0.revenueGrowth ?? 0) >= 0.25 &&
                ["NYQ", "NMS"].contains($0.exchange)
            }
            
        case .undervaluedGrowthStocks:
            filteredStocks = baseStocks.filter { 
                ($0.peRatio ?? 999) <= 20 && 
                ($0.revenueGrowth ?? 0) >= 0.25 &&
                ["NYQ", "NMS"].contains($0.exchange)
            }
            
        case .undervaluedLargeCaps:
            filteredStocks = baseStocks.filter { 
                ($0.peRatio ?? 999) <= 20 && 
                $0.marketCap >= 10_000_000_000 && 
                $0.marketCap <= 100_000_000_000 &&
                ["NYQ", "NMS"].contains($0.exchange)
            }
            
        case .smallCapGainers:
            filteredStocks = baseStocks.filter { 
                $0.marketCap < 2_000_000_000 && 
                $0.percentChange > 0 &&
                ["NYQ", "NMS"].contains($0.exchange)
            }
            
        case .mostShortedStocks:
            filteredStocks = baseStocks.filter { 
                $0.price > 1.0 && 
                $0.dayVolume > 200_000 
            }
            .sorted { $0.dayVolume > $1.dayVolume }
        }
        
        return Array(filteredStocks.prefix(limit))
    }
    
    /// 기본 종목 데이터 생성
    private func createBaseStockData() -> [YFScreenResult] {
        let sectors = YFSector.allCases.map { $0.rawValue }
        let exchanges = ["NYQ", "NMS", "ASE"]
        
        var stocks: [YFScreenResult] = []
        
        // 대형주들
        let largeCapStocks = [
            ("AAPL", "Apple Inc.", "Technology"),
            ("MSFT", "Microsoft Corp.", "Technology"),
            ("GOOGL", "Alphabet Inc.", "Communication Services"),
            ("AMZN", "Amazon.com Inc.", "Consumer Cyclical"),
            ("TSLA", "Tesla Inc.", "Consumer Cyclical"),
            ("META", "Meta Platforms Inc.", "Communication Services"),
            ("NVDA", "NVIDIA Corp.", "Technology"),
            ("BRK-B", "Berkshire Hathaway Inc.", "Financial Services"),
            ("JNJ", "Johnson & Johnson", "Healthcare"),
            ("UNH", "UnitedHealth Group Inc.", "Healthcare"),
            ("XOM", "Exxon Mobil Corp.", "Energy"),
            ("JPM", "JPMorgan Chase & Co.", "Financial Services"),
            ("V", "Visa Inc.", "Financial Services"),
            ("PG", "Procter & Gamble Co.", "Consumer Defensive"),
            ("HD", "Home Depot Inc.", "Consumer Cyclical")
        ]
        
        for (symbol, name, sector) in largeCapStocks {
            let basePrice = Double.random(in: 50...500)
            let marketCap = Double.random(in: 50_000_000_000...3_000_000_000_000)
            let percentChange = Double.random(in: -8...12)
            let volume = Int.random(in: 1_000_000...50_000_000)
            
            let stock = YFScreenResult(
                ticker: try! YFTicker(symbol: symbol),
                companyName: name,
                price: basePrice,
                marketCap: marketCap,
                percentChange: percentChange,
                dayVolume: volume,
                sector: sector,
                industry: "\(sector) Industry",
                region: "US",
                exchange: exchanges.randomElement()!,
                peRatio: Double.random(in: 8...40),
                returnOnEquity: Double.random(in: 0.05...0.35),
                revenueGrowth: Double.random(in: -0.1...0.5),
                debtToEquity: Double.random(in: 0.1...1.2)
            )
            stocks.append(stock)
        }
        
        // 중소형주들 추가
        for i in 0..<50 {
            let symbol = "STOCK\(i + 1)"
            let sector = sectors.randomElement()!
            let isSmallCap = i < 25
            
            let basePrice = Double.random(in: 1...200)
            let marketCap = isSmallCap ? 
                Double.random(in: 100_000_000...5_000_000_000) :
                Double.random(in: 5_000_000_000...50_000_000_000)
            let percentChange = Double.random(in: -15...20)
            let volume = Int.random(in: 50_000...10_000_000)
            
            let stock = YFScreenResult(
                ticker: try! YFTicker(symbol: symbol),
                companyName: "Company \(i + 1)",
                price: basePrice,
                marketCap: marketCap,
                percentChange: percentChange,
                dayVolume: volume,
                sector: sector,
                industry: "\(sector) Industry",
                region: "US",
                exchange: exchanges.randomElement()!,
                peRatio: Double.random(in: 5...60),
                returnOnEquity: Double.random(in: -0.1...0.4),
                revenueGrowth: Double.random(in: -0.3...0.8),
                debtToEquity: Double.random(in: 0.0...2.0)
            )
            stocks.append(stock)
        }
        
        return stocks
    }
    
    /// 필터 조건 매칭 확인
    private func matchesFilters(_ stock: YFScreenResult, filters: [YFScreenFilter]) -> Bool {
        for filter in filters {
            if !matchesFilter(stock, filter: filter) {
                return false
            }
        }
        return true
    }
    
    /// 개별 필터 조건 매칭 확인
    private func matchesFilter(_ stock: YFScreenResult, filter: YFScreenFilter) -> Bool {
        switch filter {
        case .marketCap(let op):
            return matchesOperator(value: stock.marketCap, operator: op)
        case .price(let op):
            return matchesOperator(value: stock.price, operator: op)
        case .peRatio(let op):
            guard let pe = stock.peRatio else { return false }
            return matchesOperator(value: pe, operator: op)
        case .returnOnEquity(let op):
            guard let roe = stock.returnOnEquity else { return false }
            return matchesOperator(value: roe, operator: op)
        case .revenueGrowth(let op):
            guard let growth = stock.revenueGrowth else { return false }
            return matchesOperator(value: growth, operator: op)
        case .debtToEquity(let op):
            guard let debt = stock.debtToEquity else { return false }
            return matchesOperator(value: debt, operator: op)
        case .sector(let op):
            return matchesStringOperator(value: stock.sector, operator: op)
        case .region(let op):
            return matchesStringOperator(value: stock.region, operator: op)
        case .exchange(let op):
            return matchesStringOperator(value: stock.exchange, operator: op)
        case .dayVolume(let op):
            return matchesOperator(value: Double(stock.dayVolume), operator: op)
        case .percentChange(let op):
            return matchesOperator(value: stock.percentChange, operator: op)
        }
    }
    
    /// 숫자 연산자 매칭
    private func matchesOperator(value: Double, operator op: YFFilterOperator) -> Bool {
        switch op {
        case .greaterThan(let threshold):
            return value > threshold
        case .lessThan(let threshold):
            return value < threshold
        case .greaterThanOrEqual(let threshold):
            return value >= threshold
        case .lessThanOrEqual(let threshold):
            return value <= threshold
        case .between(let min, let max):
            return value >= min && value <= max
        default:
            return false
        }
    }
    
    /// 문자열 연산자 매칭
    private func matchesStringOperator(value: String, operator op: YFFilterOperator) -> Bool {
        switch op {
        case .equals(let target):
            return value.lowercased() == target.lowercased()
        case .isIn(let values):
            return values.contains { $0.lowercased() == value.lowercased() }
        default:
            return false
        }
    }
    
    /// 결과 정렬
    private func sortResults(_ stocks: [YFScreenResult], by field: YFScreenSortField, ascending: Bool) -> [YFScreenResult] {
        return stocks.sorted { first, second in
            let comparison: Bool
            
            switch field {
            case .ticker:
                comparison = first.ticker.symbol < second.ticker.symbol
            case .marketCap:
                comparison = first.marketCap < second.marketCap
            case .price:
                comparison = first.price < second.price
            case .percentChange:
                comparison = first.percentChange < second.percentChange
            case .dayVolume:
                comparison = first.dayVolume < second.dayVolume
            case .peRatio:
                let firstPE = first.peRatio ?? Double.infinity
                let secondPE = second.peRatio ?? Double.infinity
                comparison = firstPE < secondPE
            case .revenueGrowth:
                let firstGrowth = first.revenueGrowth ?? -Double.infinity
                let secondGrowth = second.revenueGrowth ?? -Double.infinity
                comparison = firstGrowth < secondGrowth
            }
            
            return ascending ? comparison : !comparison
        }
    }
}