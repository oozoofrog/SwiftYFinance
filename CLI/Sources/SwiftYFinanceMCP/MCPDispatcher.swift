/// MCP 디스패처 — tool 이름으로 분기하여 Yahoo Finance 서비스를 호출
///
/// YFClient 인스턴스를 단일 관리하고, tools/call 요청을 해당 서비스로 라우팅합니다.
/// actor로 구현하여 YFClient 상태를 안전하게 관리합니다.
///
/// ## 직렬화 전략
/// - Encodable 모델 (YFHistoricalData, YFSearchResult, YFCustomScreenerResult, YFDomainResult 등):
///   JSONEncoder로 직렬화 → 문자열 → JSONValue.string으로 래핑
/// - Decodable-only 모델 (YFQuote, YFNewsArticle, YFOptionsChainResult 등):
///   `fetchRawJSON` 메서드로 Data를 직접 수신 → UTF-8 문자열로 변환
///
/// ## JSONValue 마이그레이션
/// - params: [String: JSONValue] 사용
/// - arguments: [String: JSONValue] 사용
/// - MCPResponse.success(result: JSONValue) 사용
/// - @unchecked Sendable 완전 제거

import Foundation
import SwiftYFinance

/// MCP tool 디스패처
actor MCPDispatcher {

    /// Yahoo Finance 클라이언트 단일 인스턴스
    let client = YFClient()

    /// JSON-RPC 요청을 처리하고 응답을 반환합니다.
    func dispatch(request: MCPRequest) async -> MCPResponse {
        let requestId = request.id ?? .null

        switch request.method {

        // MARK: initialize
        case "initialize":
            return handleInitialize(id: requestId)

        // MARK: tools/list
        case "tools/list":
            return handleToolsList(id: requestId)

        // MARK: tools/call
        case "tools/call":
            return await handleToolsCall(id: requestId, params: request.params)

        // MARK: 알 수 없는 메서드
        default:
            return MCPResponse.error(
                id: requestId,
                code: MCPErrorCode.methodNotFound,
                message: "Method not found: \(request.method)"
            )
        }
    }

    // MARK: - Private Handlers

    /// initialize 핸들러 — MCP 서버 정보 반환
    private func handleInitialize(id: MCPRequestId) -> MCPResponse {
        let result: JSONValue = .object([
            "protocolVersion": .string("2024-11-05"),
            "capabilities": .object(["tools": .object([:])]),
            "serverInfo": .object([
                "name": .string("swiftyfinance-mcp"),
                "version": .string("1.0.0")
            ])
        ])
        return MCPResponse.success(id: id, result: result)
    }

    /// tools/list 핸들러 — 12개 tool 목록 반환
    private func handleToolsList(id: MCPRequestId) -> MCPResponse {
        let tools = MCPToolDefinition.allTools.map { $0.toJSONValue() }
        let result: JSONValue = .object(["tools": .array(tools)])
        return MCPResponse.success(id: id, result: result)
    }

    /// tools/call 핸들러 — tool 이름으로 분기
    private func handleToolsCall(id: MCPRequestId, params: [String: JSONValue]) async -> MCPResponse {
        guard let toolName = params["name"]?.stringValue, !toolName.isEmpty else {
            return MCPResponse.error(
                id: id,
                code: MCPErrorCode.invalidParams,
                message: "Invalid params: missing 'name' field"
            )
        }

        // arguments 파라미터 추출 — [String: JSONValue] 또는 빈 딕셔너리
        let arguments: [String: JSONValue]
        if let argsValue = params["arguments"], case .object(let argsDict) = argsValue {
            arguments = argsDict
        } else {
            arguments = [:]
        }

        do {
            let resultText = try await callTool(name: toolName, arguments: arguments)
            let content: JSONValue = .array([
                .object(["type": .string("text"), "text": .string(resultText)])
            ])
            let result: JSONValue = .object(["content": content])
            return MCPResponse.success(id: id, result: result)

        } catch MCPToolError.unknownTool(let name) {
            return MCPResponse.error(
                id: id,
                code: MCPErrorCode.methodNotFound,
                message: "Unknown tool: \(name)"
            )
        } catch MCPToolError.missingParam(let param) {
            return MCPResponse.error(
                id: id,
                code: MCPErrorCode.invalidParams,
                message: "Invalid params: missing required parameter '\(param)'"
            )
        } catch MCPToolError.invalidParam(let msg) {
            return MCPResponse.error(
                id: id,
                code: MCPErrorCode.invalidParams,
                message: "Invalid params: \(msg)"
            )
        } catch {
            // YFError 또는 기타 에러 → -32603 Internal Error
            return MCPResponse.error(
                id: id,
                code: MCPErrorCode.internalError,
                message: "Internal error",
                data: error.localizedDescription
            )
        }
    }

    // MARK: - Tool Router

    /// tool 이름으로 실제 서비스를 호출합니다.
    private func callTool(name: String, arguments: [String: JSONValue]) async throws -> String {
        switch name {
        case "quote":             return try await callQuote(arguments: arguments)
        case "multi-quote":       return try await callMultiQuote(arguments: arguments)
        case "chart":             return try await callChart(arguments: arguments)
        case "search":            return try await callSearch(arguments: arguments)
        case "news":              return try await callNews(arguments: arguments)
        case "options":           return try await callOptions(arguments: arguments)
        case "screening":         return try await callScreening(arguments: arguments)
        case "customScreener":    return try await callCustomScreener(arguments: arguments)
        case "quoteSummary":      return try await callQuoteSummary(arguments: arguments)
        case "domain":            return try await callDomain(arguments: arguments)
        case "fundamentals":      return try await callFundamentals(arguments: arguments)
        case "websocket-snapshot": return try await callWebSocketSnapshot(arguments: arguments)
        default:
            throw MCPToolError.unknownTool(name)
        }
    }

    // MARK: - Tool Implementations

    /// quote tool — 단일 종목 실시간 시세 (fetchRawJSON 사용 — YFQuote는 Encodable 미지원)
    private func callQuote(arguments: [String: JSONValue]) async throws -> String {
        guard let symbol = arguments["symbol"]?.stringValue, !symbol.isEmpty else {
            throw MCPToolError.missingParam("symbol")
        }
        let ticker = YFTicker(symbol: symbol.uppercased())
        let data = try await client.quote.fetchRawJSON(ticker: ticker)
        return dataToJSONString(data)
    }

    /// multi-quote tool — 복수 종목 배치 조회
    /// YFQuoteResponse는 Encodable 미지원이므로 fetch(symbols:) 결과를 JSONValue로 변환합니다.
    private func callMultiQuote(arguments: [String: JSONValue]) async throws -> String {
        guard let symbolsArray = arguments["symbols"]?.arrayValue, !symbolsArray.isEmpty else {
            throw MCPToolError.missingParam("symbols")
        }
        let symbols = symbolsArray.compactMap { $0.stringValue }.map { $0.uppercased() }
        guard !symbols.isEmpty else {
            throw MCPToolError.invalidParam("symbols must be an array of strings")
        }
        let response = try await client.quote.fetch(symbols: symbols)
        // YFQuoteResponse → JSONValue 배열 변환
        let items: [JSONValue] = (response.result ?? []).map { quoteData($0) }
        let data = try JSONSerialization.data(withJSONObject: JSONValue.array(items).toJSONObject())
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    /// chart tool — 과거 가격 데이터 (YFHistoricalData는 Codable)
    private func callChart(arguments: [String: JSONValue]) async throws -> String {
        guard let symbol = arguments["symbol"]?.stringValue, !symbol.isEmpty else {
            throw MCPToolError.missingParam("symbol")
        }
        let ticker = YFTicker(symbol: symbol.uppercased())

        // period 파라미터 파싱 (기본값: 1mo)
        let periodStr = arguments["period"]?.stringValue ?? "1mo"
        let period = parseYFPeriod(periodStr) ?? .oneMonth

        // interval 파라미터 파싱 (기본값: 1d)
        let intervalStr = arguments["interval"]?.stringValue ?? "1d"
        let interval = parseYFInterval(intervalStr) ?? .oneDay

        let data = try await client.chart.fetchRawJSON(ticker: ticker, period: period, interval: interval)
        return dataToJSONString(data)
    }

    /// search tool — 종목 검색 (YFSearchResult는 Codable)
    private func callSearch(arguments: [String: JSONValue]) async throws -> String {
        guard let query = arguments["query"]?.stringValue, !query.isEmpty else {
            throw MCPToolError.missingParam("query")
        }
        let results = try await client.search.find(companyName: query)
        return try encodeJSON(results)
    }

    /// news tool — 뉴스 조회 (원시 응답에서 news 배열만 추출)
    ///
    /// Yahoo Finance 뉴스 API 원시 응답은 `{news: [...], quotes: [...], ...}` 형태의 dict이므로
    /// `news` 키의 배열만 추출하여 반환합니다.
    private func callNews(arguments: [String: JSONValue]) async throws -> String {
        guard let query = arguments["query"]?.stringValue, !query.isEmpty else {
            throw MCPToolError.missingParam("query")
        }
        // count 파라미터 — .int 또는 .number에서 추출
        let count: Int
        if let countValue = arguments["count"] {
            count = countValue.intValue ?? Int(countValue.doubleValue ?? 10.0)
        } else {
            count = 10
        }
        let ticker = YFTicker(symbol: query)
        let data = try await client.news.fetchRawJSON(ticker: ticker, count: count)

        // 원시 응답에서 news 배열만 추출하여 반환
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let newsArray = obj["news"],
           let newsData = try? JSONSerialization.data(withJSONObject: newsArray) {
            return String(data: newsData, encoding: .utf8) ?? "[]"
        }
        return "[]"
    }

    /// options tool — 옵션 체인 (fetchRawJSON 사용 — YFOptionsChainResult는 Encodable 미지원)
    private func callOptions(arguments: [String: JSONValue]) async throws -> String {
        guard let symbol = arguments["symbol"]?.stringValue, !symbol.isEmpty else {
            throw MCPToolError.missingParam("symbol")
        }
        let ticker = YFTicker(symbol: symbol.uppercased())
        let data = try await client.options.fetchRawJSON(for: ticker)
        return dataToJSONString(data)
    }

    /// screening tool — 사전 정의 스크리너 (fetchRawJSON 사용)
    private func callScreening(arguments: [String: JSONValue]) async throws -> String {
        let screenerStr = arguments["screener"]?.stringValue ?? "dayGainers"
        let limit: Int
        if let limitValue = arguments["limit"] {
            limit = limitValue.intValue ?? Int(limitValue.doubleValue ?? 25.0)
        } else {
            limit = 25
        }
        let screener = parseYFPredefinedScreener(screenerStr) ?? .dayGainers
        let data = try await client.screener.fetchRawJSON(predefined: screener, limit: limit)
        return dataToJSONString(data)
    }

    /// customScreener tool — 맞춤 스크리닝 (YFCustomScreenerResult는 Codable)
    private func callCustomScreener(arguments: [String: JSONValue]) async throws -> String {
        let limit: Int
        if let limitValue = arguments["limit"] {
            limit = limitValue.intValue ?? Int(limitValue.doubleValue ?? 25.0)
        } else {
            limit = 25
        }
        // Double 파라미터 추출 — .number 또는 .int case 모두 처리
        let minMarketCap = arguments["minMarketCap"]?.doubleValue ?? arguments["minMarketCap"].flatMap { $0.intValue.map(Double.init) }
        let maxMarketCap = arguments["maxMarketCap"]?.doubleValue ?? arguments["maxMarketCap"].flatMap { $0.intValue.map(Double.init) }
        let minPERatio = arguments["minPERatio"]?.doubleValue ?? arguments["minPERatio"].flatMap { $0.intValue.map(Double.init) }
        let maxPERatio = arguments["maxPERatio"]?.doubleValue ?? arguments["maxPERatio"].flatMap { $0.intValue.map(Double.init) }

        let results: [YFCustomScreenerResult]
        if let minPE = minPERatio, let maxPE = maxPERatio {
            results = try await client.customScreener.screenByPERatio(
                minPE: minPE,
                maxPE: maxPE,
                limit: limit
            )
        } else if let minCap = minMarketCap, let maxCap = maxMarketCap {
            results = try await client.customScreener.screenByMarketCap(
                minMarketCap: minCap,
                maxMarketCap: maxCap,
                limit: limit
            )
        } else {
            // 기본: 대형주 스크리닝
            results = try await client.customScreener.screenByMarketCap(
                minMarketCap: 10_000_000_000,
                maxMarketCap: 1_000_000_000_000,
                limit: limit
            )
        }
        return try encodeJSON(results)
    }

    /// quoteSummary tool — 종합 기업 정보 (fetchRawJSON 사용 — YFQuoteSummary는 Encodable 미지원)
    private func callQuoteSummary(arguments: [String: JSONValue]) async throws -> String {
        guard let symbol = arguments["symbol"]?.stringValue, !symbol.isEmpty else {
            throw MCPToolError.missingParam("symbol")
        }
        let ticker = YFTicker(symbol: symbol.uppercased())
        let typeStr = arguments["type"]?.stringValue ?? "essential"
        let data: Data

        switch typeStr.lowercased() {
        case "comprehensive":
            data = try await client.quoteSummary.fetchComprehensiveRawJSON(ticker: ticker)
        case "company":
            data = try await client.quoteSummary.fetchRawJSON(ticker: ticker, modules: YFQuoteSummaryModule.companyInfo)
        case "price":
            data = try await client.quoteSummary.fetchRawJSON(ticker: ticker, modules: YFQuoteSummaryModule.priceInfo)
        case "financials":
            data = try await client.quoteSummary.fetchRawJSON(ticker: ticker, modules: YFQuoteSummaryModule.annualFinancials)
        case "earnings":
            data = try await client.quoteSummary.fetchRawJSON(ticker: ticker, modules: YFQuoteSummaryModule.earningsData)
        case "ownership":
            data = try await client.quoteSummary.fetchRawJSON(ticker: ticker, modules: YFQuoteSummaryModule.ownershipData)
        case "analyst":
            data = try await client.quoteSummary.fetchRawJSON(ticker: ticker, modules: YFQuoteSummaryModule.analystData)
        default: // "essential"
            data = try await client.quoteSummary.fetchEssentialRawJSON(ticker: ticker)
        }
        return dataToJSONString(data)
    }

    /// domain tool — 섹터/산업/마켓 도메인 (YFDomainSectorResponse/YFDomainResult는 Codable)
    private func callDomain(arguments: [String: JSONValue]) async throws -> String {
        let domainType = arguments["domainType"]?.stringValue ?? "sector"
        let value = arguments["value"]?.stringValue ?? "technology"

        switch domainType.lowercased() {
        case "market":
            let market = parseYFMarket(value) ?? .us
            let results = try await client.domain.fetchMarket(market)
            return try encodeJSON(results)
        case "industry":
            let results = try await client.domain.fetchIndustry(value)
            return try encodeJSON(results)
        default: // "sector"
            let sector = parseYFSector(value) ?? .technology
            let response = try await client.domain.fetchSectorDetails(sector)
            return try encodeJSON(response)
        }
    }

    /// fundamentals tool — 재무제표 시계열 (fetchRawJSON 사용 — Encodable 미지원)
    private func callFundamentals(arguments: [String: JSONValue]) async throws -> String {
        guard let symbol = arguments["symbol"]?.stringValue, !symbol.isEmpty else {
            throw MCPToolError.missingParam("symbol")
        }
        let ticker = YFTicker(symbol: symbol.uppercased())
        let data = try await client.fundamentalsTimeseries.fetchRawJSON(ticker: ticker)
        return dataToJSONString(data)
    }

    /// websocket-snapshot tool — WebSocket 1회성 스냅샷
    private func callWebSocketSnapshot(arguments: [String: JSONValue]) async throws -> String {
        guard let symbolsArray = arguments["symbols"]?.arrayValue, !symbolsArray.isEmpty else {
            throw MCPToolError.missingParam("symbols")
        }
        let symbols = symbolsArray.compactMap { $0.stringValue }.map { $0.uppercased() }
        guard !symbols.isEmpty else {
            throw MCPToolError.invalidParam("symbols must be an array of strings")
        }
        let timeoutSeconds: Int
        if let timeoutValue = arguments["timeout_seconds"] {
            timeoutSeconds = timeoutValue.intValue ?? Int(timeoutValue.doubleValue ?? 10.0)
        } else {
            timeoutSeconds = 10
        }

        // 타임아웃 경쟁
        return try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                try await self.fetchWebSocketSnapshot(symbols: symbols)
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeoutSeconds) * 1_000_000_000)
                throw YFError.networkError("WebSocket snapshot timeout after \(timeoutSeconds) seconds")
            }
            guard let result = try await group.next() else {
                throw YFError.networkError("WebSocket snapshot failed: no result")
            }
            group.cancelAll()
            return result
        }
    }

    /// WebSocket 스냅샷 실제 구현
    private func fetchWebSocketSnapshot(symbols: [String]) async throws -> String {
        let wsClient = YFWebSocketClient()
        try await wsClient.connect()
        try await wsClient.subscribe(symbols)

        let (messageStream, _) = await wsClient.streams()

        // JSONValue 딕셔너리로 수집
        var collected: [JSONValue] = []
        var remaining = Set(symbols)

        for await message in messageStream {
            guard !remaining.isEmpty else { break }
            if let sym = message.symbol, remaining.contains(sym) {
                remaining.remove(sym)
                var dict: [String: JSONValue] = [:]
                if let s = message.symbol { dict["symbol"] = .string(s) }
                if let p = message.price { dict["price"] = .number(Double(p)) }
                if let c = message.change { dict["change"] = .number(Double(c)) }
                if let cp = message.changePercent { dict["changePercent"] = .number(Double(cp)) }
                if let v = message.volume { dict["volume"] = .int(Int(v)) }
                if let ms = message.marketState { dict["marketState"] = .string(ms) }
                if let dh = message.dayHigh { dict["dayHigh"] = .number(Double(dh)) }
                if let dl = message.dayLow { dict["dayLow"] = .number(Double(dl)) }
                collected.append(.object(dict))
            }
            if remaining.isEmpty { break }
        }

        await wsClient.disconnect()

        guard !collected.isEmpty else {
            throw YFError.noData
        }

        let jsonValue = JSONValue.array(collected)
        let data = try JSONSerialization.data(withJSONObject: jsonValue.toJSONObject())
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    // MARK: - Helpers

    /// Encodable 값을 JSON 문자열로 직렬화
    private func encodeJSON<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(value)
        return String(data: data, encoding: .utf8) ?? "null"
    }

    /// Data → UTF-8 JSON 문자열 변환
    private func dataToJSONString(_ data: Data) -> String {
        return String(data: data, encoding: .utf8) ?? "null"
    }

    /// YFQuote를 JSONValue로 변환 (multi-quote에서 사용)
    private func quoteData(_ quote: YFQuote) -> JSONValue {
        var dict: [String: JSONValue] = [:]
        if let v = quote.basicInfo.symbol { dict["symbol"] = .string(v) }
        if let v = quote.basicInfo.shortName { dict["shortName"] = .string(v) }
        if let v = quote.basicInfo.longName { dict["longName"] = .string(v) }
        if let v = quote.marketData.regularMarketPrice { dict["regularMarketPrice"] = .number(Double(v)) }
        if let v = quote.marketData.regularMarketChange { dict["regularMarketChange"] = .number(Double(v)) }
        if let v = quote.marketData.regularMarketChangePercent { dict["regularMarketChangePercent"] = .number(Double(v)) }
        if let v = quote.marketData.regularMarketOpen { dict["regularMarketOpen"] = .number(Double(v)) }
        if let v = quote.marketData.regularMarketDayHigh { dict["regularMarketDayHigh"] = .number(Double(v)) }
        if let v = quote.marketData.regularMarketDayLow { dict["regularMarketDayLow"] = .number(Double(v)) }
        if let v = quote.marketData.regularMarketPreviousClose { dict["regularMarketPreviousClose"] = .number(Double(v)) }
        if let v = quote.volumeInfo.regularMarketVolume { dict["regularMarketVolume"] = .int(Int(v)) }
        if let v = quote.volumeInfo.marketCap { dict["marketCap"] = .int(Int(v)) }
        return .object(dict)
    }
}

// MARK: - MCPToolError

/// MCP tool 처리 에러
enum MCPToolError: Error {
    case unknownTool(String)
    case missingParam(String)
    case invalidParam(String)
}

// MARK: - Parse Helpers

/// YFPeriod 파싱
private func parseYFPeriod(_ str: String) -> YFPeriod? {
    switch str.lowercased() {
    case "1d": return .oneDay
    case "5d": return .oneWeek
    case "1mo": return .oneMonth
    case "3mo": return .threeMonths
    case "6mo": return .sixMonths
    case "1y": return .oneYear
    case "2y": return .twoYears
    case "5y": return .fiveYears
    case "10y": return .tenYears
    case "max": return .max
    default: return nil
    }
}

/// YFInterval 파싱
private func parseYFInterval(_ str: String) -> YFInterval? {
    switch str.lowercased() {
    case "1m": return .oneMinute
    case "2m": return .twoMinutes
    case "5m": return .fiveMinutes
    case "15m": return .fifteenMinutes
    case "30m": return .thirtyMinutes
    case "60m": return .sixtyMinutes
    case "90m": return .ninetyMinutes
    case "1h": return .oneHour
    case "1d": return .oneDay
    case "5d": return .fiveDays
    case "1wk": return .oneWeek
    case "1mo": return .oneMonth
    case "3mo": return .threeMonths
    default: return nil
    }
}

/// YFPredefinedScreener 파싱
private func parseYFPredefinedScreener(_ str: String) -> YFPredefinedScreener? {
    switch str {
    case "dayGainers", "day_gainers": return .dayGainers
    case "dayLosers", "day_losers": return .dayLosers
    case "mostActives", "most_actives": return .mostActives
    case "aggressiveSmallCaps", "aggressive_small_caps": return .aggressiveSmallCaps
    case "growthTechnologyStocks", "growth_technology_stocks": return .growthTechnologyStocks
    case "undervaluedGrowthStocks", "undervalued_growth_stocks": return .undervaluedGrowthStocks
    case "undervaluedLargeCaps", "undervalued_large_caps": return .undervaluedLargeCaps
    case "smallCapGainers", "small_cap_gainers": return .smallCapGainers
    case "mostShortedStocks", "most_shorted_stocks": return .mostShortedStocks
    default: return nil
    }
}

/// YFMarket 파싱
private func parseYFMarket(_ str: String) -> YFMarket? {
    switch str.lowercased() {
    case "us": return .us
    default: return nil
    }
}

/// YFSector 파싱
private func parseYFSector(_ str: String) -> YFSector? {
    switch str.lowercased() {
    case "technology": return .technology
    case "healthcare": return .healthcare
    case "financialservices", "financial-services": return .financialServices
    case "consumerdefensive", "consumer-defensive": return .consumerDefensive
    case "consumercyclical", "consumer-cyclical": return .consumerCyclical
    case "industrials": return .industrials
    case "communicationservices", "communication-services": return .communicationServices
    case "energy": return .energy
    case "utilities": return .utilities
    case "realestate", "real-estate": return .realEstate
    case "basicmaterials", "basic-materials": return .basicMaterials
    default: return nil
    }
}
