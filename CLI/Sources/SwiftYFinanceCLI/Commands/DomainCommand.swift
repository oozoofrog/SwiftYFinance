import Foundation
import SwiftYFinance
import ArgumentParser

struct DomainCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "domain",
        abstract: "Get sector, industry, and market domain data"
    )
    
    @Option(name: .shortAndLong, help: "Domain type: sector, industry, or market")
    var type: DomainType = .sector
    
    @Option(help: "Sector name when using sector type (e.g., technology, healthcare)")
    var sector: String?
    
    @Option(help: "Industry key when using industry type")
    var industry: String?
    
    @Option(help: "Market region when using market type (e.g., us, eu)")
    var market: String?
    
    @Flag(name: .shortAndLong, help: "Enable debug output")
    var debug = false
    
    @Flag(name: .shortAndLong, help: "Output raw JSON response")
    var json = false
    
    func run() async throws {
        let client = YFClient(debugEnabled: debug)
        
        if debug && !json {
            print("🔍 Debug mode enabled")
            print("🌐 Fetching \(type) domain data")
        }
        
        do {
            if json {
                let rawData = try await fetchRawJSON(client: client)
                print(formatJSONOutput(rawData))
            } else {
                switch type {
                case .sector:
                    let sectorData = try await fetchSectorData(client: client)
                    printSectorInfo(sectorData)
                case .industry, .market:
                    let domainData = try await fetchDomainData(client: client)
                    printDomainInfo(domainData)
                }
            }
        } catch {
            if json {
                printJSONError("Failed to fetch domain data", error: error)
            } else {
                printError("Failed to fetch domain data", error: error)
            }
            throw ExitCode.failure
        }
    }
    
    private func fetchSectorData(client: YFClient) async throws -> YFDomainSectorResponse {
        if let sectorName = sector {
            if let yfSector = YFSector(rawValue: sectorName) {
                return try await client.domain.fetchSectorDetails(yfSector)
            } else {
                throw ValidationError("Invalid sector name: \(sectorName). Available sectors: \(YFSector.allCases.map { $0.rawValue }.joined(separator: ", "))")
            }
        } else {
            return try await client.domain.fetchSectorDetails(.technology)
        }
    }
    
    private func fetchDomainData(client: YFClient) async throws -> [YFDomainResult] {
        switch type {
        case .sector:
            // Sector uses new model, handled separately
            return []
        case .industry:
            guard let industryKey = industry else {
                throw ValidationError("Industry key is required when using industry type")
            }
            return try await client.domain.fetchIndustry(industryKey)
        case .market:
            if let marketName = market {
                if let yfMarket = YFMarket(rawValue: marketName) {
                    return try await client.domain.fetchMarket(yfMarket)
                } else {
                    throw ValidationError("Invalid market name: \(marketName). Available markets: \(YFMarket.allCases.map { $0.rawValue }.joined(separator: ", "))")
                }
            } else {
                return try await client.domain.fetchMarket(.us)
            }
        }
    }
    
    private func fetchRawJSON(client: YFClient) async throws -> Data {
        switch type {
        case .sector:
            if let sectorName = sector {
                if let yfSector = YFSector(rawValue: sectorName) {
                    return try await client.domain.fetchRawJSON(sector: yfSector)
                } else {
                    throw ValidationError("Invalid sector name: \(sectorName)")
                }
            } else {
                return try await client.domain.fetchRawJSON(sector: .technology)
            }
        case .industry:
            guard let industryKey = industry else {
                throw ValidationError("Industry key is required when using industry type")
            }
            return try await client.domain.fetchRawJSON(industry: industryKey)
        case .market:
            if let marketName = market {
                if let yfMarket = YFMarket(rawValue: marketName) {
                    return try await client.domain.fetchRawJSON(market: yfMarket)
                } else {
                    throw ValidationError("Invalid market name: \(marketName)")
                }
            } else {
                return try await client.domain.fetchRawJSON(market: .us)
            }
        }
    }
    
    private func printSectorInfo(_ sectorData: YFDomainSectorResponse) {
        guard let data = sectorData.data else {
            print("❌ No sector data available")
            return
        }
        
        print("🌐 Sector Data")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        
        if let symbol = data.symbol {
            print("📈 Symbol: \(symbol)")
        }
        
        if let key = data.key {
            print("🏷 Sector: \(key)")
        }
        
        // Performance data
        if let performance = data.performance {
            print("\n📊 Performance:")
            if let ytd = performance.ytdChangePercent {
                printPerformanceItem("YTD", value: ytd)
            }
            if let oneYear = performance.oneYearChangePercent {
                printPerformanceItem("1 Year", value: oneYear)
            }
            if let threeYear = performance.threeYearChangePercent {
                printPerformanceItem("3 Year", value: threeYear)
            }
            if let fiveYear = performance.fiveYearChangePercent {
                printPerformanceItem("5 Year", value: fiveYear)
            }
        }
        
        // Top companies
        if let topCompanies = data.topCompanies, !topCompanies.isEmpty {
            print("\n🏢 Top Companies:")
            for (index, company) in topCompanies.prefix(5).enumerated() {
                if let name = company.name, let symbol = company.symbol {
                    print("  \(index + 1). \(name) (\(symbol))")
                    if let marketCap = company.marketCap, let fmt = marketCap.fmt {
                        print("     Market Cap: \(fmt)")
                    }
                    if let ytdReturn = company.ytdReturn, let raw = ytdReturn.raw {
                        let changeSymbol = raw >= 0 ? "🟢" : "🔴"
                        print("     YTD Return: \(changeSymbol) \(formatPercent(raw * 100))%")
                    }
                }
            }
        }
        
        print("\n🕒 Retrieved at: \(formatTime(Date()))")
    }
    
    private func printPerformanceItem(_ label: String, value: YFFormattedValue) {
        if let raw = value.raw, let fmt = value.fmt {
            let changeSymbol = raw >= 0 ? "🟢" : "🔴"
            print("  \(label): \(changeSymbol) \(fmt)")
        }
    }
    
    private func printDomainInfo(_ domainData: [YFDomainResult]) {
        guard !domainData.isEmpty else {
            print("❌ No domain data available")
            return
        }
        
        print("🌐 Domain Data (\(type.rawValue.capitalized))")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        
        for (index, result) in domainData.enumerated() {
            let name = result.name ?? "Unknown"
            let id = result.id ?? "N/A"
            
            print("[\(index + 1)] \(name) (\(id))")
            
            if let symbolCount = result.symbolCount {
                print("    Symbols: \(symbolCount)")
            }
            
            if let totalMarketCap = result.totalMarketCap {
                print("    Total Market Cap: $\(formatLargeNumber(totalMarketCap))")
            }
            
            if let averageMarketCap = result.averageMarketCap {
                print("    Average Market Cap: $\(formatLargeNumber(averageMarketCap))")
            }
            
            if let priceChangePercent = result.priceChangePercent {
                let changeSymbol = priceChangePercent >= 0 ? "🟢" : "🔴"
                let changeSign = priceChangePercent >= 0 ? "+" : ""
                print("    Price Change: \(changeSymbol) \(changeSign)\(formatPercent(priceChangePercent))%")
            }
            
            if let volume = result.volume {
                print("    Volume: \(formatVolume(volume))")
            }
            
            if let activeSymbols = result.activeSymbols {
                print("    Active Symbols: \(activeSymbols)")
            }
            
            print("")
        }
        
        print("📊 Domain Type: \(type)")
        print("🕒 Retrieved at: \(formatTime(Date()))")
    }
}

enum DomainType: String, CaseIterable, ExpressibleByArgument {
    case sector = "sector"
    case industry = "industry"
    case market = "market"
    
    var defaultValueDescription: String {
        switch self {
        case .sector: return "Sector data (default)"
        case .industry: return "Industry data"
        case .market: return "Market data"
        }
    }
}