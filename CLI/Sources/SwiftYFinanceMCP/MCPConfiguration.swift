import Foundation

/// MCP 서버 엔트리 구성
public struct MCPServerConfiguration: Sendable, Equatable {
    public let name: String
    public let command: String
    public let args: [String]

    public init(name: String, command: String, args: [String] = []) {
        self.name = name
        self.command = command
        self.args = args
    }
}

/// MCP 설정 파일 병합 유틸리티
public enum MCPConfigurationFile {
    /// 기존 설정과 새 서버 구성을 병합한 JSON 데이터를 반환합니다.
    public static func mergedJSON(
        existingData: Data?,
        server: MCPServerConfiguration
    ) throws -> Data {
        var rootObject = try parseRootObject(from: existingData)
        var mcpServers = rootObject["mcpServers"] as? [String: Any] ?? [:]
        mcpServers[server.name] = [
            "command": server.command,
            "args": server.args
        ]
        rootObject["mcpServers"] = mcpServers

        let options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys]
        let data = try JSONSerialization.data(withJSONObject: rootObject, options: options)
        guard var json = String(data: data, encoding: .utf8) else {
            throw MCPConfigurationError.serializationFailed
        }
        if !json.hasSuffix("\n") {
            json.append("\n")
        }
        return Data(json.utf8)
    }

    private static func parseRootObject(from existingData: Data?) throws -> [String: Any] {
        guard let existingData, !existingData.isEmpty else {
            return [:]
        }

        let raw = try JSONSerialization.jsonObject(with: existingData)
        guard let object = raw as? [String: Any] else {
            throw MCPConfigurationError.invalidRootObject
        }
        return object
    }
}

public enum MCPConfigurationError: LocalizedError {
    case invalidRootObject
    case serializationFailed

    public var errorDescription: String? {
        switch self {
        case .invalidRootObject:
            return "MCP 설정 파일의 최상위 JSON 객체가 dictionary가 아닙니다."
        case .serializationFailed:
            return "MCP 설정 파일을 JSON 문자열로 직렬화하지 못했습니다."
        }
    }
}
