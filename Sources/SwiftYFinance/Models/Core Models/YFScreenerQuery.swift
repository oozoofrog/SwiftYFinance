import Foundation

/// Yahoo Finance Screener Query 연산자
/// 
/// 스크리너 쿼리에서 사용 가능한 모든 연산자를 정의합니다.
public enum YFScreenerOperator: String, CaseIterable, Sendable {
    /// 같음
    case eq = "EQ"
    /// 보다 큼
    case gt = "GT"
    /// 보다 작음
    case lt = "LT"
    /// 크거나 같음
    case gte = "GTE"
    /// 작거나 같음
    case lte = "LTE"
    /// 범위 내
    case between = "BTWN"
    /// 포함됨 (여러 값 중 하나)
    case isIn = "IS-IN"
    /// 논리 AND
    case and = "AND"
    /// 논리 OR
    case or = "OR"
}

/// Yahoo Finance Screener Query Value
/// 
/// 쿼리에서 사용할 수 있는 값의 타입을 정의합니다.
public enum YFScreenerValue: Sendable {
    case string(String)
    case double(Double)
    case int(Int)
    case query(YFScreenerQuery)
    
    /// 실제 값 반환
    public var value: Sendable {
        switch self {
        case .string(let str):
            return str
        case .double(let num):
            return num
        case .int(let num):
            return num
        case .query(let query):
            return query
        }
    }
}

/// Yahoo Finance Screener Query Protocol
/// 
/// 모든 스크리너 쿼리가 준수해야 하는 기본 프로토콜입니다.
public protocol YFScreenerQueryProtocol: Sendable {
    /// 쿼리를 딕셔너리 형태로 변환
    func toDictionary() -> [String: Sendable]
    
    /// JSON 데이터로 변환
    func toJSONData() throws -> Data
}

/// Yahoo Finance Screener Query 기본 구현
/// 
/// yfinance Python 라이브러리의 QueryBase 클래스와 호환되는 구조입니다.
public struct YFScreenerQuery: YFScreenerQueryProtocol {
    public let `operator`: YFScreenerOperator
    public let operands: [YFScreenerValue]
    
    public init(operator: YFScreenerOperator, operands: [YFScreenerValue]) {
        self.`operator` = `operator`
        self.operands = operands
    }
    
    /// 단일 값 쿼리 생성 (EQ, GT, LT, GTE, LTE)
    public init(operator: YFScreenerOperator, field: String, value: YFScreenerValue) {
        self.`operator` = `operator`
        self.operands = [.string(field), value]
    }
    
    /// 범위 쿼리 생성 (BTWN)
    public init(field: String, min: Double, max: Double) {
        self.`operator` = .between
        self.operands = [.string(field), .double(min), .double(max)]
    }
    
    /// IS-IN 쿼리 생성
    public init(field: String, values: [YFScreenerValue]) {
        self.`operator` = .isIn
        var operands = [YFScreenerValue.string(field)]
        operands.append(contentsOf: values)
        self.operands = operands
    }
    
    /// 논리 연산 쿼리 생성 (AND, OR)
    public init(operator: YFScreenerOperator, queries: [YFScreenerQuery]) {
        self.`operator` = `operator`
        self.operands = queries.map { .query($0) }
    }
    
    /// 딕셔너리로 변환
    public func toDictionary() -> [String: Sendable] {
        var result: [String: Sendable] = ["operator": `operator`.rawValue]
        
        // IS-IN을 OR + EQ 조합으로 변환 (yfinance 호환)
        if `operator` == .isIn && operands.count >= 2 {
            let field = operands[0]
            let values = Array(operands.dropFirst())
            
            let eqQueries = values.map { value in
                YFScreenerQuery(operator: .eq, operands: [field, value])
            }
            
            result["operator"] = YFScreenerOperator.or.rawValue
            result["operands"] = eqQueries.map { $0.toDictionary() }
        } else {
            result["operands"] = operands.map { operand -> Sendable in
                switch operand {
                case .query(let query):
                    return query.toDictionary()
                default:
                    return operand.value
                }
            }
        }
        
        return result
    }
    
    /// JSON 데이터로 변환
    public func toJSONData() throws -> Data {
        let dictionary = toDictionary()
        return try JSONSerialization.data(withJSONObject: dictionary, options: [.prettyPrinted])
    }
}

// MARK: - Convenience Initializers

extension YFScreenerQuery {
    
    /// 같음 쿼리
    public static func eq(_ field: String, _ value: String) -> YFScreenerQuery {
        return YFScreenerQuery(operator: .eq, field: field, value: .string(value))
    }
    
    /// 같음 쿼리 (숫자)
    public static func eq(_ field: String, _ value: Double) -> YFScreenerQuery {
        return YFScreenerQuery(operator: .eq, field: field, value: .double(value))
    }
    
    /// 보다 큼 쿼리
    public static func gt(_ field: String, _ value: Double) -> YFScreenerQuery {
        return YFScreenerQuery(operator: .gt, field: field, value: .double(value))
    }
    
    /// 보다 작음 쿼리
    public static func lt(_ field: String, _ value: Double) -> YFScreenerQuery {
        return YFScreenerQuery(operator: .lt, field: field, value: .double(value))
    }
    
    /// 크거나 같음 쿼리
    public static func gte(_ field: String, _ value: Double) -> YFScreenerQuery {
        return YFScreenerQuery(operator: .gte, field: field, value: .double(value))
    }
    
    /// 작거나 같음 쿼리
    public static func lte(_ field: String, _ value: Double) -> YFScreenerQuery {
        return YFScreenerQuery(operator: .lte, field: field, value: .double(value))
    }
    
    /// 범위 쿼리
    public static func between(_ field: String, min: Double, max: Double) -> YFScreenerQuery {
        return YFScreenerQuery(field: field, min: min, max: max)
    }
    
    /// 포함 쿼리 (문자열 배열)
    public static func isIn(_ field: String, _ values: [String]) -> YFScreenerQuery {
        let screenerValues = values.map { YFScreenerValue.string($0) }
        return YFScreenerQuery(field: field, values: screenerValues)
    }
    
    /// 논리 AND
    public static func and(_ queries: [YFScreenerQuery]) -> YFScreenerQuery {
        return YFScreenerQuery(operator: .and, queries: queries)
    }
    
    /// 논리 OR
    public static func or(_ queries: [YFScreenerQuery]) -> YFScreenerQuery {
        return YFScreenerQuery(operator: .or, queries: queries)
    }
}

// MARK: - Common Field Names

extension YFScreenerQuery {
    
    /// 일반적인 스크리너 필드명
    public struct Field {
        // 가격 관련
        public static let price = "intradayprice"
        public static let priceChange = "intradaypricechange"
        public static let percentChange = "percentchange"
        public static let marketCap = "intradaymarketcap"
        
        // 거래량
        public static let volume = "dayvolume"
        public static let avgVolume3M = "avgdailyvol3m"
        
        // 밸류에이션
        public static let peRatio = "peratio.lasttwelvemonths"
        public static let pegRatio5Y = "pegratio_5y"
        public static let priceToBook = "pricebookratio.quarterly"
        
        // 수익성
        public static let roe = "returnonequity.lasttwelvemonths"
        public static let roa = "returnonassets.lasttwelvemonths"
        
        // 분류
        public static let region = "region"
        public static let sector = "sector"
        public static let exchange = "exchange"
    }
}

// MARK: - Equity Query Extensions

extension YFScreenerQuery {
    
    /// 미국 주식 필터
    public static var usEquities: YFScreenerQuery {
        return .eq(Field.region, "us")
    }
    
    /// 대형주 필터 (시가총액 100억 이상)
    public static var largeCap: YFScreenerQuery {
        return .gte(Field.marketCap, 10_000_000_000)
    }
    
    /// 기술주 필터
    public static var technology: YFScreenerQuery {
        return .eq(Field.sector, "Technology")
    }
    
    /// 거래량 활발한 주식 (일일 거래량 100만주 이상)
    public static var highVolume: YFScreenerQuery {
        return .gte(Field.volume, 1_000_000)
    }
    
    /// 저PER 주식 (PER 15 이하)
    public static var lowPE: YFScreenerQuery {
        return .lte(Field.peRatio, 15.0)
    }
    
    /// 시가총액 범위 쿼리
    public static func marketCapRange(min: Double, max: Double) -> YFScreenerQuery {
        return .between(Field.marketCap, min: min, max: max)
    }
    
    /// P/E 비율 범위 쿼리
    public static func peRatioRange(min: Double, max: Double) -> YFScreenerQuery {
        return .between(Field.peRatio, min: min, max: max)
    }
    
    /// 수익률 범위 쿼리
    public static func returnRange(min: Double, max: Double) -> YFScreenerQuery {
        return .between(Field.percentChange, min: min, max: max)
    }
    
    /// 복합 조건 쿼리
    public static func multipleConditions(_ conditions: [YFScreenerCondition]) -> YFScreenerQuery {
        let queries = conditions.map { $0.toQuery() }
        return .and(queries)
    }
}

// MARK: - Screener Condition

/// 스크리너 조건 정의
public struct YFScreenerCondition: Sendable {
    public let field: String
    public let `operator`: YFScreenerOperator
    public let value: YFScreenerValue
    
    public init(field: String, operator: YFScreenerOperator, value: YFScreenerValue) {
        self.field = field
        self.`operator` = `operator`
        self.value = value
    }
    
    /// YFScreenerQuery로 변환
    public func toQuery() -> YFScreenerQuery {
        return YFScreenerQuery(operator: `operator`, field: field, value: value)
    }
    
    /// 편의 생성 메서드들
    public static func marketCap(min: Double, max: Double) -> YFScreenerCondition {
        return YFScreenerCondition(field: YFScreenerQuery.Field.marketCap, operator: .between, value: .double(min))
    }
    
    public static func peRatio(min: Double, max: Double) -> YFScreenerCondition {
        return YFScreenerCondition(field: YFScreenerQuery.Field.peRatio, operator: .between, value: .double(min))
    }
    
    public static func sector(_ sector: String) -> YFScreenerCondition {
        return YFScreenerCondition(field: YFScreenerQuery.Field.sector, operator: .eq, value: .string(sector))
    }
    
    public static func volume(min: Double) -> YFScreenerCondition {
        return YFScreenerCondition(field: YFScreenerQuery.Field.volume, operator: .gte, value: .double(min))
    }
}