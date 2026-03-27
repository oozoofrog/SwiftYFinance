/// SwiftYFinance MCP 서버 진입점
///
/// Yahoo Finance 데이터를 JSON-RPC 2.0 stdio 프로토콜로 제공하는 MCP 서버.
/// Claude Desktop, Cursor 등 MCP 클라이언트와 직접 연동합니다.

import Foundation

// MCPServer가 실행을 담당합니다.
let server = MCPServer()
await server.run()
