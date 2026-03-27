import Foundation
import ArgumentParser
import SwiftYFinanceMCP

struct MCPCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mcp",
        abstract: "Install or run SwiftYFinance MCP integration",
        subcommands: [
            MCPInstallCommand.self,
            MCPServeCommand.self
        ]
    )
}

struct MCPInstallCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install",
        abstract: "Install MCP config that points to this swift-yf-tools binary"
    )

    @Option(name: .shortAndLong, help: "Install target: claude, cursor, local, all")
    var client: MCPInstallTarget = .claude

    @Option(name: .shortAndLong, help: "MCP server name to register")
    var name: String = "yahoo-finance"

    @Option(help: "Custom config file path. If set, --client is ignored.")
    var path: String?

    @Flag(help: "Print the generated config without writing files")
    var dryRun = false

    @Flag(name: .customLong("no-emoji"), help: "이모지 없이 ASCII 대체 문자로 출력합니다")
    var noEmoji = false

    func run() throws {
        let style = OutputStyle(noEmoji: noEmoji)
        let executablePath = try resolveExecutablePath()
        let server = MCPServerConfiguration(
            name: name,
            command: executablePath,
            args: ["mcp", "serve"]
        )

        let targets = try installTargets()
        if dryRun {
            print("\(style.chart) 생성될 MCP 설정")
            print(style.separator)
        }

        for target in targets {
            let filePath = target.resolvedPath
            let existingData = FileManager.default.fileExists(atPath: filePath)
                ? try Data(contentsOf: URL(fileURLWithPath: filePath))
                : nil
            let mergedData = try MCPConfigurationFile.mergedJSON(existingData: existingData, server: server)

            if dryRun {
                print("# \(filePath)")
                print(String(decoding: mergedData, as: UTF8.self))
                continue
            }

            try write(data: mergedData, to: filePath)
            print("\(style.ok) MCP 설정 설치 완료: \(filePath)")
        }

        if dryRun {
            return
        }

        print("")
        print("\(style.link) 등록된 command: \(executablePath)")
        print("\(style.signal) 등록된 args: mcp serve")

        if targets.contains(where: { $0.kind == .claude }) {
            print("\(style.hint) Claude Desktop을 재시작하면 바로 사용할 수 있습니다.")
        }
    }

    private func installTargets() throws -> [MCPInstallDestination] {
        if let path {
            return [MCPInstallDestination(kind: .custom, resolvedPath: expandPath(path))]
        }

        switch client {
        case .claude:
            return [.claude]
        case .cursor:
            return [.cursorProject]
        case .local:
            return [.localProject]
        case .all:
            return [.claude, .cursorProject, .localProject]
        }
    }

    private func resolveExecutablePath() throws -> String {
        if let executableURL = Bundle.main.executableURL {
            return executableURL.standardizedFileURL.path
        }

        let candidate = URL(
            fileURLWithPath: CommandLine.arguments[0],
            relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        )
        let path = candidate.standardizedFileURL.path
        guard FileManager.default.isExecutableFile(atPath: path) else {
            throw ValidationError("현재 실행 파일 경로를 확인하지 못했습니다: \(path)")
        }
        return path
    }

    private func write(data: Data, to path: String) throws {
        let fileURL = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        try data.write(to: fileURL, options: .atomic)
    }

    private func expandPath(_ path: String) -> String {
        NSString(string: path).expandingTildeInPath
    }
}

struct MCPServeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "serve",
        abstract: "Run the MCP server over stdio"
    )

    func run() async throws {
        await MCPServer().run()
    }
}

enum MCPInstallTarget: String, ExpressibleByArgument, CaseIterable {
    case claude
    case cursor
    case local
    case all
}

struct MCPInstallDestination: Sendable {
    enum Kind: Sendable, Equatable {
        case claude
        case cursorProject
        case localProject
        case custom
    }

    let kind: Kind
    let resolvedPath: String

    static var claude: MCPInstallDestination {
        .init(
            kind: .claude,
            resolvedPath: NSString(
                string: "~/Library/Application Support/Claude/claude_desktop_config.json"
            ).expandingTildeInPath
        )
    }

    static var cursorProject: MCPInstallDestination {
        .init(
            kind: .cursorProject,
            resolvedPath: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(".cursor")
                .appendingPathComponent("mcp.json")
                .path
        )
    }

    static var localProject: MCPInstallDestination {
        .init(
            kind: .localProject,
            resolvedPath: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(".mcp.json")
                .path
        )
    }
}
