import Foundation
import Testing
@testable import SwiftYFinanceMCP

@Suite("MCP 설정 파일 병합")
struct MCPConfigurationTests {

    @Test("빈 설정 파일에 서버 엔트리 생성")
    func createFreshConfig() throws {
        let server = MCPServerConfiguration(
            name: "yahoo-finance",
            command: "/usr/local/bin/swift-yf-tools",
            args: ["mcp", "serve"]
        )

        let data = try MCPConfigurationFile.mergedJSON(existingData: nil, server: server)
        let root = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let mcpServers = try #require(root["mcpServers"] as? [String: Any])
        let installed = try #require(mcpServers["yahoo-finance"] as? [String: Any])

        #expect(installed["command"] as? String == "/usr/local/bin/swift-yf-tools")
        #expect(installed["args"] as? [String] == ["mcp", "serve"])
    }

    @Test("기존 서버 설정을 보존하면서 새 엔트리 병합")
    func preserveExistingServers() throws {
        let existing = """
        {
          "mcpServers": {
            "existing-server": {
              "command": "/tmp/existing",
              "args": []
            }
          }
        }
        """.data(using: .utf8)

        let server = MCPServerConfiguration(
            name: "yahoo-finance",
            command: "/usr/local/bin/swift-yf-tools",
            args: ["mcp", "serve"]
        )

        let data = try MCPConfigurationFile.mergedJSON(existingData: existing, server: server)
        let root = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let mcpServers = try #require(root["mcpServers"] as? [String: Any])

        #expect(mcpServers["existing-server"] != nil)
        #expect(mcpServers["yahoo-finance"] != nil)
    }
}
