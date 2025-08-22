import Foundation
import SwiftYFinance
import ArgumentParser

struct ScreeningCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "screening",
        abstract: "Screen stocks using predefined filters"
    )
    
    @Argument(help: "Predefined screener type (day_gainers, day_losers, most_actives, aggressive_small_caps, growth_technology_stocks, undervalued_growth_stocks, undervalued_large_caps, small_cap_gainers, most_shorted_stocks)")
    var screenerType: String
    
    @Option(name: .shortAndLong, help: "Number of results to return (default: 25, max: 250)")
    var limit: Int = 25
    
    @Flag(name: .shortAndLong, help: "Enable debug output")
    var debug = false
    
    @Flag(name: .shortAndLong, help: "Output raw JSON response")
    var json = false
    
    func run() async throws {
        let client = YFClient(debugEnabled: debug)
        
        // 스크리너 타입을 YFPredefinedScreener로 변환
        guard let predefinedScreener = parsePredefinedScreener(screenerType.lowercased()) else {
            if json {
                printJSONError("Invalid screener type", error: YFError.invalidRequest)
            } else {
                print("❌ Invalid screener type: \(screenerType)")
                print("")
                print("Available screener types:")
                print("  • day_gainers")
                print("  • day_losers")
                print("  • most_actives")
                print("  • aggressive_small_caps")
                print("  • growth_technology_stocks")
                print("  • undervalued_growth_stocks")
                print("  • undervalued_large_caps")
                print("  • small_cap_gainers")
                print("  • most_shorted_stocks")
            }
            throw ExitCode.failure
        }
        
        let actualLimit = min(limit, 250)
        
        if debug && !json {
            print("🔍 Debug mode enabled")
            print("📊 Screening with: \(screenerType)")
            print("🔢 Limit: \(actualLimit)")
        }
        
        do {
            if json {
                // Raw JSON 출력 (CLI용)
                let rawData = try await client.screening.fetchRawJSON(predefined: predefinedScreener, limit: actualLimit)
                print(formatJSONOutput(rawData))
            } else {
                // 파싱된 결과 출력
                let results = try await client.screening.screenPredefined(predefinedScreener, limit: actualLimit)
                printScreeningResults(results, screenerType: screenerType)
            }
        } catch {
            if json {
                printJSONError("Failed to screen stocks", error: error)
            } else {
                printError("Failed to screen stocks", error: error)
            }
            throw ExitCode.failure
        }
    }
    
    private func parsePredefinedScreener(_ input: String) -> YFPredefinedScreener? {
        switch input {
        case "day_gainers":
            return .dayGainers
        case "day_losers":
            return .dayLosers
        case "most_actives":
            return .mostActives
        case "aggressive_small_caps":
            return .aggressiveSmallCaps
        case "growth_technology_stocks":
            return .growthTechnologyStocks
        case "undervalued_growth_stocks":
            return .undervaluedGrowthStocks
        case "undervalued_large_caps":
            return .undervaluedLargeCaps
        case "small_cap_gainers":
            return .smallCapGainers
        case "most_shorted_stocks":
            return .mostShortedStocks
        default:
            return nil
        }
    }
    
    private func printScreeningResults(_ results: [YFScreenResult], screenerType: String) {
        print("📊 Stock Screening Results: \(screenerType)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        
        if results.isEmpty {
            print("No stocks found for this screening criteria")
            return
        }
        
        // 헤더 출력
        print(String(format: "%-6s %-25s %10s %10s %8s", "Symbol", "Company", "Price", "Change%", "Volume"))
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        for result in results {
            let symbol = String((result.symbol ?? "").prefix(6))
            let company = String((result.shortName ?? result.longName ?? "").prefix(25))
            let price = String(format: "$%.2f", result.regularMarketPrice ?? 0)
            let change = String(format: "%.2f%%", result.regularMarketChangePercent ?? 0)
            let volume = formatVolume(Int(result.regularMarketVolume ?? 0))
            
            print(String(format: "%-6s %-25s %10s %10s %8s", 
                         symbol, company, price, change, volume))
        }
        
        print("")
        print("Found \(results.count) stock\(results.count == 1 ? "" : "s")")
        
        // 추가 통계 정보
        if !results.isEmpty {
            let avgPrice = results.compactMap { $0.regularMarketPrice }.reduce(0, +) / Double(results.count)
            let avgChange = results.compactMap { $0.regularMarketChangePercent }.reduce(0, +) / Double(results.count)
            
            print("")
            print("📈 Summary:")
            print("   Average Price: $\(String(format: "%.2f", avgPrice))")
            print("   Average Change: \(String(format: "%.2f", avgChange))%")
        }
    }
    
    private func formatVolume(_ volume: Int) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM", Double(volume) / 1_000_000)
        } else if volume >= 1_000 {
            return String(format: "%.1fK", Double(volume) / 1_000)
        } else {
            return String(volume)
        }
    }
    
}