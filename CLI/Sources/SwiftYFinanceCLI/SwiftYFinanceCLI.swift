import ArgumentParser

@main
struct SwiftYFinanceCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swift-yf-tools",
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
            WebSocketCommand.self,
            MCPCommand.self
        ],
        defaultSubcommand: QuoteCommand.self
    )

    /// 전역 옵션 — 모든 서브커맨드에 전달
    /// swift-argument-parser는 루트 커맨드의 @OptionGroup을 서브커맨드에 직접 전달하지 않으므로,
    /// 각 커맨드에서 독립적으로 --no-emoji를 선언합니다.
    /// SwiftYFinanceCLI는 글로벌 플래그 등록 진입점 역할만 합니다.
}
