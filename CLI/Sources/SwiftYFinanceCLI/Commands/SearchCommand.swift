import Foundation
import SwiftYFinance
import ArgumentParser

struct SearchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search for stocks by company name"
    )
    
    @Argument(help: "Company name or ticker to search for")
    var query: String
    
    @Option(name: .shortAndLong, help: "Maximum number of results")
    var limit: Int = 10
    
    @Flag(name: .shortAndLong, help: "Enable debug output")
    var debug = false
    
    @Flag(name: .shortAndLong, help: "Output raw JSON response")
    var json = false
    
    func run() async throws {
        let client = YFClient(debugEnabled: debug)
        
        if debug && !json {
            print("🔍 Debug mode enabled")
            print("🔎 Searching for: \(query)")
        }
        
        do {
            if json {
                let rawData = try await client.search.findRawJSON(companyName: query)
                print(formatJSONOutput(rawData))
            } else {
                let results = try await client.search.find(companyName: query)
                printSearchResults(results, query: query, limit: limit)
            }
        } catch {
            if json {
                printJSONError("Failed to search", error: error)
            } else {
                printError("Failed to search", error: error)
            }
            throw ExitCode.failure
        }
    }
    
    private func printSearchResults(_ results: [YFSearchResult], query: String, limit: Int) {
        print("🔎 Search Results for '\(query)'")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        if results.isEmpty {
            print("No results found.")
            return
        }
        
        print("Found \(results.count) results (showing first \(min(limit, results.count))):")
        print("")
        print("Symbol    Type      Name")
        print("────────────────────────────────────────────────────────")
        
        for result in results.prefix(limit) {
            let typeIcon = getTypeIcon(result.quoteType)
            let shortName = String(result.shortName.prefix(40))
            print("\(result.symbol.padding(toLength: 8, withPad: " ", startingAt: 0))  \(typeIcon) \(result.quoteType.rawValue.padding(toLength: 6, withPad: " ", startingAt: 0))  \(shortName)")
        }
    }
}