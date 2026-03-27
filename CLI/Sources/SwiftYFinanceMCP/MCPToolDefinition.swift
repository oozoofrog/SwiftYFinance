/// MCP Tool 정의 — 12개 Yahoo Finance 서비스 tool 목록
///
/// tools/list 응답에서 반환되는 tool 메타데이터.
/// 각 tool의 이름, 설명, JSON Schema(inputSchema)를 포함합니다.
///
/// ## 설계 원칙
/// - inputSchema: JSONValue로 타입 안전하게 표현 (@unchecked Sendable 제거)
/// - nonisolated struct: actor isolation 불필요한 순수 데이터 구조

import Foundation

/// MCP tool 단일 정의
///
/// `inputSchema: JSONValue` — @unchecked Sendable 없이 완전한 Sendable 충족.
nonisolated struct MCPToolDefinition: Sendable {
    let name: String
    let description: String
    /// JSON Schema Draft 7 형식의 입력 파라미터 스키마 (JSONValue 타입)
    let inputSchema: JSONValue

    /// MCP 응답 형식의 JSONValue로 변환
    func toJSONValue() -> JSONValue {
        return .object([
            "name": .string(name),
            "description": .string(description),
            "inputSchema": inputSchema
        ])
    }

    /// MCP 응답 형식의 딕셔너리로 변환 (JSONSerialization 호환)
    func toDictionary() -> [String: Any] {
        return toJSONValue().toJSONObject() as? [String: Any] ?? [
            "name": name,
            "description": description,
            "inputSchema": [:]
        ]
    }
}

// MARK: - 12개 Tool 정의

extension MCPToolDefinition {

    /// 12개 Yahoo Finance MCP tool 목록
    static let allTools: [MCPToolDefinition] = [
        quoteToolDefinition,
        multiQuoteToolDefinition,
        chartToolDefinition,
        searchToolDefinition,
        newsToolDefinition,
        optionsToolDefinition,
        screeningToolDefinition,
        customScreenerToolDefinition,
        quoteSummaryToolDefinition,
        domainToolDefinition,
        fundamentalsToolDefinition,
        websocketSnapshotToolDefinition
    ]

    // MARK: quote

    static let quoteToolDefinition = MCPToolDefinition(
        name: "quote",
        description: "Yahoo Finance에서 단일 종목의 실시간 시세를 조회합니다. 현재가, 거래량, 시가총액 등 기본 마켓 데이터를 반환합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "symbol": .object([
                    "type": .string("string"),
                    "description": .string("종목 심볼 (예: AAPL, TSLA, BTC-USD)")
                ])
            ]),
            "required": .array([.string("symbol")])
        ])
    )

    // MARK: multi-quote

    static let multiQuoteToolDefinition = MCPToolDefinition(
        name: "multi-quote",
        description: "여러 종목의 실시간 시세를 한 번에 조회합니다. YFQuoteService.fetch(symbols:)를 사용하여 배치 조회를 수행합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "symbols": .object([
                    "type": .string("array"),
                    "items": .object(["type": .string("string")]),
                    "description": .string("종목 심볼 배열 (예: [\"AAPL\", \"TSLA\", \"MSFT\"])"),
                    "minItems": .int(1)
                ])
            ]),
            "required": .array([.string("symbols")])
        ])
    )

    // MARK: chart

    static let chartToolDefinition = MCPToolDefinition(
        name: "chart",
        description: "종목의 과거 가격 데이터(OHLCV)를 조회합니다. period와 interval 파라미터로 조회 범위와 봉 단위를 설정합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "symbol": .object([
                    "type": .string("string"),
                    "description": .string("종목 심볼 (예: AAPL)")
                ]),
                "period": .object([
                    "type": .string("string"),
                    "description": .string("조회 기간 (1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, 10y, max)"),
                    "default": .string("1mo")
                ]),
                "interval": .object([
                    "type": .string("string"),
                    "description": .string("봉 단위 (1m, 2m, 5m, 15m, 30m, 60m, 90m, 1h, 1d, 5d, 1wk, 1mo, 3mo)"),
                    "default": .string("1d")
                ])
            ]),
            "required": .array([.string("symbol")])
        ])
    )

    // MARK: search

    static let searchToolDefinition = MCPToolDefinition(
        name: "search",
        description: "회사명 또는 키워드로 Yahoo Finance 종목을 검색합니다. 종목 심볼, 회사명, 거래소 정보를 반환합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "query": .object([
                    "type": .string("string"),
                    "description": .string("검색할 회사명 또는 키워드 (예: Apple, Tesla)")
                ]),
                "limit": .object([
                    "type": .string("integer"),
                    "description": .string("최대 결과 수 (기본값: 10)"),
                    "default": .int(10)
                ])
            ]),
            "required": .array([.string("query")])
        ])
    )

    // MARK: news

    static let newsToolDefinition = MCPToolDefinition(
        name: "news",
        description: "종목 또는 키워드 관련 Yahoo Finance 뉴스를 조회합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "query": .object([
                    "type": .string("string"),
                    "description": .string("검색할 종목 심볼 또는 키워드 (예: AAPL, Apple)")
                ]),
                "count": .object([
                    "type": .string("integer"),
                    "description": .string("가져올 뉴스 수 (기본값: 10)"),
                    "default": .int(10)
                ])
            ]),
            "required": .array([.string("query")])
        ])
    )

    // MARK: options

    static let optionsToolDefinition = MCPToolDefinition(
        name: "options",
        description: "종목의 옵션 체인 데이터를 조회합니다. 콜/풋 옵션의 행사가, 만기일, 내재 변동성 등을 포함합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "symbol": .object([
                    "type": .string("string"),
                    "description": .string("종목 심볼 (예: AAPL)")
                ])
            ]),
            "required": .array([.string("symbol")])
        ])
    )

    // MARK: screening

    static let screeningToolDefinition = MCPToolDefinition(
        name: "screening",
        description: "Yahoo Finance 사전 정의 스크리너를 실행합니다. dayGainers, dayLosers, mostActives 등 미리 정의된 스크리닝 전략을 사용합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "screener": .object([
                    "type": .string("string"),
                    "description": .string("스크리너 유형 (dayGainers, dayLosers, mostActives, aggressiveSmallCaps, growthTechnologyStocks, undervaluedGrowthStocks, undervaluedLargeCaps, smallCapGainers, mostShortedStocks)"),
                    "default": .string("dayGainers")
                ]),
                "limit": .object([
                    "type": .string("integer"),
                    "description": .string("최대 결과 수 (기본값: 25)"),
                    "default": .int(25)
                ])
            ])
        ])
    )

    // MARK: customScreener

    static let customScreenerToolDefinition = MCPToolDefinition(
        name: "customScreener",
        description: "맞춤 조건으로 종목을 스크리닝합니다. 시가총액, PER, 수익률 범위를 지정하여 조건에 맞는 종목을 검색합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "minMarketCap": .object([
                    "type": .string("number"),
                    "description": .string("최소 시가총액 (단위: USD)")
                ]),
                "maxMarketCap": .object([
                    "type": .string("number"),
                    "description": .string("최대 시가총액 (단위: USD)")
                ]),
                "minPERatio": .object([
                    "type": .string("number"),
                    "description": .string("최소 PER")
                ]),
                "maxPERatio": .object([
                    "type": .string("number"),
                    "description": .string("최대 PER")
                ]),
                "limit": .object([
                    "type": .string("integer"),
                    "description": .string("최대 결과 수 (기본값: 25)"),
                    "default": .int(25)
                ])
            ])
        ])
    )

    // MARK: quoteSummary

    static let quoteSummaryToolDefinition = MCPToolDefinition(
        name: "quoteSummary",
        description: "종목의 종합 기업 정보를 조회합니다. 재무제표, 실적, 애널리스트 추천, 소유권 정보 등을 type 파라미터로 선택합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "symbol": .object([
                    "type": .string("string"),
                    "description": .string("종목 심볼 (예: AAPL)")
                ]),
                "type": .object([
                    "type": .string("string"),
                    "description": .string("조회 유형 (essential, comprehensive, company, price, financials, earnings, ownership, analyst)"),
                    "default": .string("essential")
                ])
            ]),
            "required": .array([.string("symbol")])
        ])
    )

    // MARK: domain

    static let domainToolDefinition = MCPToolDefinition(
        name: "domain",
        description: "Yahoo Finance 섹터/산업/마켓 도메인 데이터를 조회합니다. 섹터별 주요 종목과 성과를 확인합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "domainType": .object([
                    "type": .string("string"),
                    "description": .string("도메인 유형 (sector, market, industry)"),
                    "default": .string("sector")
                ]),
                "value": .object([
                    "type": .string("string"),
                    "description": .string("섹터명 또는 마켓명 (예: technology, us). domainType이 sector일 때는 섹터명, market일 때는 마켓명")
                ])
            ])
        ])
    )

    // MARK: fundamentals

    static let fundamentalsToolDefinition = MCPToolDefinition(
        name: "fundamentals",
        description: "종목의 재무제표 시계열 데이터를 조회합니다. 손익계산서, 대차대조표, 현금흐름표의 과거 데이터를 포함합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "symbol": .object([
                    "type": .string("string"),
                    "description": .string("종목 심볼 (예: AAPL)")
                ])
            ]),
            "required": .array([.string("symbol")])
        ])
    )

    // MARK: websocket-snapshot

    static let websocketSnapshotToolDefinition = MCPToolDefinition(
        name: "websocket-snapshot",
        description: "Yahoo Finance WebSocket을 통해 지정 심볼(들)의 실시간 가격 스냅샷을 1회 수신합니다. 스트리밍 대신 MCP 호환 방식으로 즉시 반환합니다.",
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "symbols": .object([
                    "type": .string("array"),
                    "items": .object(["type": .string("string")]),
                    "description": .string("구독할 종목 심볼 배열 (예: [\"AAPL\", \"BTC-USD\"])"),
                    "minItems": .int(1)
                ]),
                "timeout_seconds": .object([
                    "type": .string("integer"),
                    "description": .string("타임아웃 시간(초). 이 시간 내에 스냅샷을 수신하지 못하면 에러 반환 (기본값: 10)"),
                    "default": .int(10)
                ])
            ]),
            "required": .array([.string("symbols")])
        ])
    )
}
