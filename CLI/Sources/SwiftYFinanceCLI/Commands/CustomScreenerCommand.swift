import Foundation
import SwiftYFinance
import ArgumentParser

struct CustomScreenerCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "custom-screening",
        abstract: "Perform advanced stock screening with custom filters"
    )
    
    @Option(help: "Market cap range (e.g., \"100B:1T\" or \"1000000000:1000000000000\")")
    var marketCap: String?
    
    @Option(help: "P/E ratio range (e.g., \"5:25\")")
    var peRatio: String?
    
    @Option(help: "Return range in percentage (e.g., \"-10:50\")")
    var returns: String?
    
    @Option(name: .shortAndLong, help: "Number of results to return")
    var limit: Int = 25
    
    @Flag(name: .shortAndLong, help: "Enable debug output")
    var debug = false
    
    @Flag(name: .shortAndLong, help: "Output raw JSON response")
    var json = false
    
    func run() async throws {
        let client = YFClient(debugEnabled: debug)
        
        if debug && !json {
            print("🔍 Debug mode enabled")
            print("📊 Performing custom stock screening")
            if let marketCap = marketCap { print("💰 Market Cap Range: \(marketCap)") }
            if let peRatio = peRatio { print("📈 P/E Ratio Range: \(peRatio)") }
            if let returns = returns { print("💵 Returns Range: \(returns)%") }
            print("🔢 Limit: \(limit)")
        }
        
        do {
            if json {
                let rawData = try await fetchRawJSON(client: client)
                print(formatJSONOutput(rawData))
            } else {
                let screeningResults = try await performCustomScreening(client: client)
                printScreeningResults(screeningResults)
            }
        } catch {
            if json {
                printJSONError("Failed to perform custom screening", error: error)
            } else {
                printError("Failed to perform custom screening", error: error)
            }
            throw ExitCode.failure
        }
    }
    
    private func performCustomScreening(client: YFClient) async throws -> [YFCustomScreenerResult] {
        // 필터가 하나도 지정되지 않은 경우 기본 시가총액 스크리닝
        if marketCap == nil && peRatio == nil && returns == nil {
            return try await client.customScreener.screenByMarketCap(limit: limit)
        }
        
        // 단일 필터 처리
        if let marketCapRange = marketCap, peRatio == nil, returns == nil {
            let (min, max) = try parseMarketCapRange(marketCapRange)
            return try await client.customScreener.screenByMarketCap(
                minMarketCap: min,
                maxMarketCap: max,
                limit: limit
            )
        }
        
        if let peRange = peRatio, marketCap == nil, returns == nil {
            let (min, max) = try parseDoubleRange(peRange)
            return try await client.customScreener.screenByPERatio(
                minPE: min,
                maxPE: max,
                limit: limit
            )
        }
        
        if let returnRange = returns, marketCap == nil, peRatio == nil {
            let (min, max) = try parseDoubleRange(returnRange)
            return try await client.customScreener.screenByReturn(
                minReturn: min,
                maxReturn: max,
                limit: limit
            )
        }
        
        // 복합 필터 처리
        var conditions: [YFScreenerCondition] = []
        
        if let marketCapRange = marketCap {
            let (min, max) = try parseMarketCapRange(marketCapRange)
            let minCondition = YFScreenerCondition(field: YFScreenerQuery.Field.marketCap, operator: .gte, value: .double(min))
            let maxCondition = YFScreenerCondition(field: YFScreenerQuery.Field.marketCap, operator: .lte, value: .double(max))
            conditions.append(minCondition)
            conditions.append(maxCondition)
        }
        
        if let peRange = peRatio {
            let (min, max) = try parseDoubleRange(peRange)
            let minCondition = YFScreenerCondition(field: YFScreenerQuery.Field.peRatio, operator: .gte, value: .double(min))
            let maxCondition = YFScreenerCondition(field: YFScreenerQuery.Field.peRatio, operator: .lte, value: .double(max))
            conditions.append(minCondition)
            conditions.append(maxCondition)
        }
        
        if let returnRange = returns {
            let (min, max) = try parseDoubleRange(returnRange)
            let minCondition = YFScreenerCondition(field: YFScreenerQuery.Field.percentChange, operator: .gte, value: .double(min))
            let maxCondition = YFScreenerCondition(field: YFScreenerQuery.Field.percentChange, operator: .lte, value: .double(max))
            conditions.append(minCondition)
            conditions.append(maxCondition)
        }
        
        return try await client.customScreener.screenWithConditions(conditions, limit: limit)
    }
    
    private func fetchRawJSON(client: YFClient) async throws -> Data {
        let query: YFScreenerQuery
        
        if let marketCapRange = marketCap, peRatio == nil, returns == nil {
            let (min, max) = try parseMarketCapRange(marketCapRange)
            query = YFScreenerQuery.marketCapRange(min: min, max: max)
        } else if let peRange = peRatio, marketCap == nil, returns == nil {
            let (min, max) = try parseDoubleRange(peRange)
            query = YFScreenerQuery.peRatioRange(min: min, max: max)
        } else if let returnRange = returns, marketCap == nil, peRatio == nil {
            let (min, max) = try parseDoubleRange(returnRange)
            query = YFScreenerQuery.returnRange(min: min, max: max)
        } else {
            var conditions: [YFScreenerCondition] = []
            
            if let marketCapRange = marketCap {
                let (min, max) = try parseMarketCapRange(marketCapRange)
                let minCondition = YFScreenerCondition(field: YFScreenerQuery.Field.marketCap, operator: .gte, value: .double(min))
                let maxCondition = YFScreenerCondition(field: YFScreenerQuery.Field.marketCap, operator: .lte, value: .double(max))
                conditions.append(minCondition)
                conditions.append(maxCondition)
            }
            
            if let peRange = peRatio {
                let (min, max) = try parseDoubleRange(peRange)
                let minCondition = YFScreenerCondition(field: YFScreenerQuery.Field.peRatio, operator: .gte, value: .double(min))
                let maxCondition = YFScreenerCondition(field: YFScreenerQuery.Field.peRatio, operator: .lte, value: .double(max))
                conditions.append(minCondition)
                conditions.append(maxCondition)
            }
            
            if let returnRange = returns {
                let (min, max) = try parseDoubleRange(returnRange)
                let minCondition = YFScreenerCondition(field: YFScreenerQuery.Field.percentChange, operator: .gte, value: .double(min))
                let maxCondition = YFScreenerCondition(field: YFScreenerQuery.Field.percentChange, operator: .lte, value: .double(max))
                conditions.append(minCondition)
                conditions.append(maxCondition)
            }
            
            if conditions.isEmpty {
                query = YFScreenerQuery.marketCapRange(min: 100_000_000_000, max: 10_000_000_000_000)
            } else {
                query = YFScreenerQuery.multipleConditions(conditions)
            }
        }
        
        return try await client.customScreener.fetchRawJSON(query: query, limit: limit)
    }
    
    private func parseMarketCapRange(_ range: String) throws -> (min: Double, max: Double) {
        let parts = range.split(separator: ":")
        guard parts.count == 2 else {
            throw ValidationError("Invalid market cap range format. Use 'min:max' (e.g., '100B:1T' or '100000000000:1000000000000')")
        }
        
        let minValue = try parseMarketCapValue(String(parts[0]))
        let maxValue = try parseMarketCapValue(String(parts[1]))
        
        guard minValue < maxValue else {
            throw ValidationError("Minimum market cap must be less than maximum")
        }
        
        return (min: minValue, max: maxValue)
    }
    
    private func parseMarketCapValue(_ value: String) throws -> Double {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        
        if trimmed.hasSuffix("T") {
            let number = String(trimmed.dropLast())
            guard let doubleValue = Double(number) else {
                throw ValidationError("Invalid market cap value: \(value)")
            }
            return doubleValue * 1_000_000_000_000
        } else if trimmed.hasSuffix("B") {
            let number = String(trimmed.dropLast())
            guard let doubleValue = Double(number) else {
                throw ValidationError("Invalid market cap value: \(value)")
            }
            return doubleValue * 1_000_000_000
        } else if trimmed.hasSuffix("M") {
            let number = String(trimmed.dropLast())
            guard let doubleValue = Double(number) else {
                throw ValidationError("Invalid market cap value: \(value)")
            }
            return doubleValue * 1_000_000
        } else {
            guard let doubleValue = Double(trimmed) else {
                throw ValidationError("Invalid market cap value: \(value)")
            }
            return doubleValue
        }
    }
    
    private func parseDoubleRange(_ range: String) throws -> (min: Double, max: Double) {
        let parts = range.split(separator: ":")
        guard parts.count == 2 else {
            throw ValidationError("Invalid range format. Use 'min:max' (e.g., '5:25')")
        }
        
        guard let minValue = Double(parts[0]), let maxValue = Double(parts[1]) else {
            throw ValidationError("Invalid numeric values in range: \(range)")
        }
        
        guard minValue < maxValue else {
            throw ValidationError("Minimum value must be less than maximum")
        }
        
        return (min: minValue, max: maxValue)
    }
    
    private func printScreeningResults(_ results: [YFCustomScreenerResult]) {
        guard !results.isEmpty else {
            print("❌ No stocks found matching the specified criteria")
            return
        }
        
        print("📊 Custom Screening Results")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        
        for (index, stock) in results.enumerated() {
            let symbol = stock.symbol ?? "N/A"
            let name = stock.shortName ?? stock.longName ?? "Unknown Company"
            
            print("[\(index + 1)] \(symbol) - \(name)")
            
            if let price = stock.regularMarketPrice {
                let change = stock.regularMarketChange ?? 0
                let changePercent = stock.regularMarketChangePercent ?? 0
                let changeSymbol = change >= 0 ? "🟢" : "🔴"
                let changeSign = change >= 0 ? "+" : ""
                
                print("    Price: $\(formatPrice(price)) \(changeSymbol) \(changeSign)$\(formatPrice(change)) (\(changeSign)\(formatPercent(changePercent))%)")
            }
            
            if let marketCap = stock.marketCap {
                print("    Market Cap: $\(formatLargeNumber(marketCap))")
            }
            
            if let pe = stock.trailingPE {
                print("    P/E Ratio: \(formatPrice(pe))")
            }
            
            if let volume = stock.regularMarketVolume {
                print("    Volume: \(formatVolume(volume))")
            }
            
            if let sector = stock.sector {
                print("    Sector: \(sector)")
            }
            
            if let industry = stock.industry {
                print("    Industry: \(industry)")
            }
            
            if let exchange = stock.exchange {
                print("    Exchange: \(exchange)")
            }
            
            print("")
        }
        
        // 필터 요약 출력
        var filterSummary: [String] = []
        if let marketCap = marketCap { filterSummary.append("Market Cap: \(marketCap)") }
        if let peRatio = peRatio { filterSummary.append("P/E Ratio: \(peRatio)") }
        if let returns = returns { filterSummary.append("Returns: \(returns)%") }
        
        if !filterSummary.isEmpty {
            print("🔍 Applied Filters: \(filterSummary.joined(separator: ", "))")
        }
        
        print("📈 Found \(results.count) stocks (limit: \(limit))")
        print("🕒 Retrieved at: \(formatTime(Date()))")
    }
}