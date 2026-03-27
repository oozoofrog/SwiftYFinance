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

    /// 이모지 없이 ASCII 대체 문자로 출력 (CI/파이프라인 환경)
    @Flag(name: .customLong("no-emoji"), help: "이모지 없이 ASCII 대체 문자로 출력합니다")
    var noEmoji = false

    func run() async throws {
        let client = YFClient(debugEnabled: debug)
        let style = OutputStyle(noEmoji: noEmoji)

        if debug && !json {
            print("\(style.search) Debug mode enabled")
            print("[GLOBE] Fetching \(type) domain data")
        }

        do {
            if json {
                let rawData = try await fetchRawJSON(client: client)
                print(formatJSONOutput(rawData))
            } else {
                switch type {
                case .sector:
                    let sectorData = try await fetchSectorData(client: client)
                    printSectorInfo(sectorData, style: style)
                case .industry, .market:
                    let domainData = try await fetchDomainData(client: client)
                    printDomainInfo(domainData, style: style)
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
    
    private func printSectorInfo(_ sectorData: YFDomainSectorResponse, style: OutputStyle) {
        guard let data = sectorData.data else {
            print("\(style.error) No sector data available")
            return
        }

        print("[GLOBE] Sector Data")
        print(style.separator)
        print("")

        if let symbol = data.symbol {
            print("\(style.up) Symbol: \(symbol)")
        }

        if let key = data.key {
            print("[TAG] Sector: \(key)")
        }

        // 성과 데이터
        if let performance = data.performance {
            print("\n\(style.chart) Performance:")
            if let ytd = performance.ytdChangePercent {
                printPerformanceItem("YTD", value: ytd, style: style)
            }
            if let oneYear = performance.oneYearChangePercent {
                printPerformanceItem("1 Year", value: oneYear, style: style)
            }
            if let threeYear = performance.threeYearChangePercent {
                printPerformanceItem("3 Year", value: threeYear, style: style)
            }
            if let fiveYear = performance.fiveYearChangePercent {
                printPerformanceItem("5 Year", value: fiveYear, style: style)
            }
        }

        // 상위 기업
        if let topCompanies = data.topCompanies, !topCompanies.isEmpty {
            print("\n\(style.company) Top Companies:")
            for (index, company) in topCompanies.prefix(5).enumerated() {
                if let name = company.name, let symbol = company.symbol {
                    print("  \(index + 1). \(name) (\(symbol))")
                    if let marketCap = company.marketCap, let fmt = marketCap.fmt {
                        print("     Market Cap: \(fmt)")
                    }
                    if let ytdReturn = company.ytdReturn, let raw = ytdReturn.raw {
                        let changeSymbol = style.changeIcon(change: raw)
                        print("     YTD Return: \(changeSymbol) \(formatPercent(raw * 100))%")
                    }
                }
            }
        }

        print("\n\(style.clock) Retrieved at: \(formatTime(Date()))")
    }

    private func printPerformanceItem(_ label: String, value: YFFormattedValue, style: OutputStyle) {
        if let raw = value.raw, let fmt = value.fmt {
            let changeSymbol = style.changeIcon(change: raw)
            print("  \(label): \(changeSymbol) \(fmt)")
        }
    }

    private func printDomainInfo(_ domainData: [YFDomainResult], style: OutputStyle) {
        guard !domainData.isEmpty else {
            print("\(style.error) No domain data available")
            return
        }

        print("[GLOBE] Domain Data (\(type.rawValue.capitalized))")
        print(style.separator)
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
                let changeSymbol = style.changeIcon(change: priceChangePercent)
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

        print("\(style.chart) Domain Type: \(type)")
        print("\(style.clock) Retrieved at: \(formatTime(Date()))")
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