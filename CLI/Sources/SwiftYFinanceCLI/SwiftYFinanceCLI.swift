import ArgumentParser

@main
struct SwiftYFinanceCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftyfinance",
        abstract: "SwiftYFinance - Yahoo Finance API Client for Swift",
        version: "1.0.0",
        subcommands: [
            QuoteCommand.self,
            QuoteSummaryCommand.self,
            HistoryCommand.self,
            SearchCommand.self,
            FundamentalsCommand.self,
            NewsCommand.self,
            OptionsCommand.self,
            ScreeningCommand.self,
            DomainCommand.self,
            CustomScreenerCommand.self,
            WebSocketCommand.self
        ],
        defaultSubcommand: QuoteCommand.self
    )
}
