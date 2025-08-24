import Foundation

/// Yahoo Finance Domain API 응답 모델
///
/// Domain API의 JSON 응답 구조를 파싱하기 위한 모델입니다.
/// 실제 API 응답에 맞춰 구조를 정의하며, 추후 JSON 파일 생성을 통해 개선될 예정입니다.
public struct YFDomainResponse: Codable, Sendable {
    /// Finance 응답 컨테이너
    public let finance: YFDomainFinanceContainer?
    
    /// 에러 정보 (있는 경우)
    public let error: YFDomainError?
    
    enum CodingKeys: String, CodingKey {
        case finance
        case error
    }
}

/// Domain API Finance 컨테이너
public struct YFDomainFinanceContainer: Codable, Sendable {
    /// 도메인 데이터 결과 배열
    public let result: [YFDomainResult]?
    
    /// API 에러 정보
    public let error: YFDomainError?
    
    enum CodingKeys: String, CodingKey {
        case result
        case error
    }
}

/// 개별 도메인 결과 모델
public struct YFDomainResult: Codable, Sendable {
    /// 도메인 ID (예: "technology", "basic-materials")
    public let id: String?
    
    /// 도메인 이름 (예: "Technology", "Basic Materials")
    public let name: String?
    
    /// 도메인 타입 (sector, industry, market)
    public let type: String?
    
    /// 심볼 개수
    public let symbolCount: Int?
    
    /// 시가총액 합계
    public let totalMarketCap: Double?
    
    /// 평균 시가총액
    public let averageMarketCap: Double?
    
    /// 가격 변화율 (%)
    public let priceChangePercent: Double?
    
    /// 거래량
    public let volume: Int?
    
    /// 활성 심볼 개수
    public let activeSymbols: Int?
    
    /// 추가 메타데이터 (기본 Codable 타입들만)
    public let metadata: [String: CodableValue]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case symbolCount = "symbol_count"
        case totalMarketCap = "total_market_cap"
        case averageMarketCap = "average_market_cap"
        case priceChangePercent = "price_change_percent"
        case volume
        case activeSymbols = "active_symbols"
        case metadata
    }
}

/// Sendable하면서 Codable한 값 타입 래퍼
public enum CodableValue: Codable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type")
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

/// Domain API 에러 모델
public struct YFDomainError: Codable, Sendable {
    /// 에러 코드
    public let code: String?
    
    /// 에러 메시지
    public let description: String?
    
    enum CodingKeys: String, CodingKey {
        case code
        case description
    }
}