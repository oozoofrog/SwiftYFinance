import Foundation
import ArgumentParser

@main
struct SwiftYFinanceCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftyfinance",
        abstract: "SwiftYFinance - Yahoo Finance API Client for Swift",
        version: "1.0.0",
        subcommands: [
            QuoteCommand.self,
            HistoryCommand.self,
            SearchCommand.self,
            FundamentalsCommand.self
        ],
        defaultSubcommand: QuoteCommand.self
    )
}