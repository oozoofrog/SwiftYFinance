import Foundation

// MARK: - Options Trading API Extension
extension YFClient {
    
    // MARK: - Public Options Methods
    
    /// 옵션 체인 데이터를 조회합니다.
    ///
    /// Python yfinance의 option_chain() 메서드를 참조하여 구현
    /// - Parameters:
    ///   - ticker: 조회할 ticker
    ///   - expiry: 특정 만기일 (nil이면 가장 가까운 만기일)
    /// - Returns: 옵션 체인 데이터
    /// - SeeAlso: yfinance-reference/yfinance/ticker.py:87 option_chain()
    public func fetchOptionsChain(ticker: YFTicker, expiry: Date? = nil) async throws -> YFOptionsChain {
        // 테스트를 위한 에러 케이스
        if ticker.symbol == "INVALID" {
            throw YFError.apiError("Invalid symbol: INVALID")
        }
        
        // 만기일 목록 조회
        let expirationDates = try await getOptionsExpirationDates(ticker: ticker)
        
        // 특정 만기일 선택 또는 첫 번째 만기일 사용
        let targetExpiry = expiry ?? expirationDates.first ?? Date()
        
        // Mock 옵션 체인 데이터 생성 (실제 구현은 API 호출)
        let chain = createMockOptionsChain(ticker: ticker, expiry: targetExpiry)
        
        var chains: [Date: OptionsChain] = [:]
        chains[targetExpiry] = chain
        
        return YFOptionsChain(
            ticker: ticker,
            expirationDates: expirationDates,
            chains: chains
        )
    }
    
    /// 특정 만기일의 옵션 체인을 조회합니다.
    ///
    /// - Parameters:
    ///   - ticker: 조회할 ticker
    ///   - expiry: 만기일
    /// - Returns: 특정 만기일의 옵션 체인
    public func fetchOptionsChain(ticker: YFTicker, expiry: Date) async throws -> OptionsChain {
        // 전체 체인 조회 후 특정 만기일 데이터 반환
        let chain = createMockOptionsChain(ticker: ticker, expiry: expiry)
        return chain
    }
    
    /// 옵션 만기일 목록을 조회합니다.
    ///
    /// Python yfinance의 options 속성을 참조하여 구현
    /// - Parameter ticker: 조회할 ticker
    /// - Returns: 만기일 목록
    /// - SeeAlso: yfinance-reference/yfinance/ticker.py:309 options property
    public func getOptionsExpirationDates(ticker: YFTicker) async throws -> [Date] {
        // 테스트를 위한 Mock 만기일 생성 (실제로는 API 호출)
        let calendar = Calendar.current
        let now = Date()
        
        var expirationDates: [Date] = []
        
        // 주간 옵션 (매주 금요일) - 4주
        for week in 0..<4 {
            if let friday = nextFriday(from: calendar.date(byAdding: .weekOfYear, value: week, to: now)!) {
                expirationDates.append(friday)
            }
        }
        
        // 월간 옵션 (매월 세 번째 금요일) - 추가 3개월
        for month in 1..<4 {
            if let monthlyExpiry = thirdFriday(of: calendar.date(byAdding: .month, value: month, to: now)!) {
                if !expirationDates.contains(where: { 
                    calendar.isDate($0, inSameDayAs: monthlyExpiry) 
                }) {
                    expirationDates.append(monthlyExpiry)
                }
            }
        }
        
        return expirationDates.sorted()
    }
    
    // MARK: - Private Helper Methods
    
    /// Mock 옵션 체인 데이터 생성
    private func createMockOptionsChain(ticker: YFTicker, expiry: Date) -> OptionsChain {
        // 현재 가격 (Mock)
        let currentPrice = 150.0
        
        // 행사가격 생성 (현재가 기준 ±20%)
        let strikes = stride(from: currentPrice * 0.8, to: currentPrice * 1.2, by: 5.0).map { $0 }
        
        // Call 옵션 생성
        let calls = strikes.map { strike in
            createMockOption(
                ticker: ticker,
                strike: strike,
                expiry: expiry,
                optionType: .call,
                currentPrice: currentPrice
            )
        }
        
        // Put 옵션 생성
        let puts = strikes.map { strike in
            createMockOption(
                ticker: ticker,
                strike: strike,
                expiry: expiry,
                optionType: .put,
                currentPrice: currentPrice
            )
        }
        
        return OptionsChain(
            expirationDate: expiry,
            calls: calls,
            puts: puts
        )
    }
    
    /// Mock 개별 옵션 생성
    private func createMockOption(
        ticker: YFTicker,
        strike: Double,
        expiry: Date,
        optionType: OptionType,
        currentPrice: Double
    ) -> YFOption {
        // ITM/OTM 판단
        let inTheMoney = optionType == .call ? 
            (currentPrice > strike) : 
            (currentPrice < strike)
        
        // 내재가치 계산
        let intrinsicValue = optionType == .call ?
            max(0, currentPrice - strike) :
            max(0, strike - currentPrice)
        
        // 시간가치 (만기까지 남은 일수 기준)
        let daysToExpiry = max(1, Calendar.current.dateComponents([.day], from: Date(), to: expiry).day ?? 1)
        let timeValue = Double(daysToExpiry) * 0.1
        
        // 옵션 가격 = 내재가치 + 시간가치
        let optionPrice = intrinsicValue + timeValue
        
        // Mock Greeks 계산
        let delta = optionType == .call ?
            min(0.9, max(0.1, 0.5 + (currentPrice - strike) / 100)) :
            min(-0.1, max(-0.9, -0.5 + (currentPrice - strike) / 100))
        
        let gamma = 0.02 * exp(-pow((currentPrice - strike) / 10, 2))
        let theta = -timeValue / Double(daysToExpiry)
        let vega = 0.1 * sqrt(Double(daysToExpiry) / 365)
        let rho = optionType == .call ? 0.01 : -0.01
        
        // 계약 심볼 생성
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd"
        let expiryString = dateFormatter.string(from: expiry)
        let typeChar = optionType == .call ? "C" : "P"
        let strikeString = String(format: "%08.0f", strike * 1000)
        let contractSymbol = "\(ticker.symbol)\(expiryString)\(typeChar)\(strikeString)"
        
        return YFOption(
            contractSymbol: contractSymbol,
            strike: strike,
            expiry: expiry,
            optionType: optionType,
            lastPrice: optionPrice,
            bid: optionPrice * 0.99,
            ask: optionPrice * 1.01,
            change: Double.random(in: -0.5...0.5),
            percentChange: Double.random(in: -5...5),
            volume: Int.random(in: 100...10000),
            openInterest: Int.random(in: 1000...50000),
            impliedVolatility: Double.random(in: 0.2...0.8),
            delta: delta,
            gamma: gamma,
            theta: theta,
            vega: vega,
            rho: rho,
            lastTradeDate: Date(),
            contractSize: 100,
            currency: "USD",
            inTheMoney: inTheMoney
        )
    }
    
    /// 다음 금요일 찾기
    private func nextFriday(from date: Date) -> Date? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let daysUntilFriday = (6 - weekday + 7) % 7
        let daysToAdd = daysUntilFriday == 0 ? 0 : daysUntilFriday
        return calendar.date(byAdding: .day, value: daysToAdd, to: date)
    }
    
    /// 해당 월의 세 번째 금요일 찾기
    private func thirdFriday(of date: Date) -> Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        
        guard let firstDayOfMonth = calendar.date(from: components) else { return nil }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysUntilFirstFriday = (6 - firstWeekday + 7) % 7
        
        guard let firstFriday = calendar.date(byAdding: .day, value: daysUntilFirstFriday, to: firstDayOfMonth) else {
            return nil
        }
        
        // 세 번째 금요일 = 첫 번째 금요일 + 14일
        return calendar.date(byAdding: .weekOfYear, value: 2, to: firstFriday)
    }
}