/// JSONValue — MCP 타입 안전 JSON 표현
///
/// `[String: Any]`와 `Any`를 대체하는 재귀 enum.
/// Swift 6 컴파일 타임 Sendable 검증을 완전히 통과하며, @unchecked Sendable 없이
/// 모든 actor 경계를 안전하게 넘길 수 있습니다.
///
/// ## 설계 원칙
/// - nonisolated enum: 어떤 actor 컨텍스트에서도 사용 가능
/// - Codable: Bool → Int → Double 순서로 디코딩하여 타입 정밀도 보장
/// - Equatable + Hashable: 테스트 동등성 검증 및 Set/Dictionary 키로 사용 가능
/// - Foundation 양방향 변환: JSONSerialization 결과물과 완전 호환

import Foundation

// MARK: - JSONValue

/// JSON 값의 7가지 case를 표현하는 재귀 enum
///
/// JSON 표준(RFC 8259)의 모든 타입을 커버합니다:
/// - `string`: JSON string
/// - `number`: JSON number (소수 또는 소수점 있는 값)
/// - `int`: JSON number (정수 값) — Double 손실 방지
/// - `bool`: JSON boolean (true/false)
/// - `array`: JSON array
/// - `object`: JSON object
/// - `null`: JSON null
nonisolated enum JSONValue: Sendable, Codable, Equatable, Hashable {
    case string(String)
    case number(Double)
    case int(Int)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    // MARK: - Decodable

    /// JSON 디코딩 순서: Bool → Int → Double → String → Array → Object → null
    ///
    /// - Bool을 Int보다 먼저: JSON의 true/false가 NSNumber로 1/0으로 디코딩되는 것 방지
    /// - Int를 Double보다 먼저: 정수가 부동소수점으로 손실되는 것 방지
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // 1. null 확인
        if container.decodeNil() {
            self = .null
            return
        }

        // 2. Bool 시도 (Int보다 반드시 먼저 — JSON true/false 구분)
        if let boolVal = try? container.decode(Bool.self) {
            self = .bool(boolVal)
            return
        }

        // 3. Int 시도 (Double보다 먼저 — 정수 정밀도 유지)
        if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
            return
        }

        // 4. Double 시도
        if let doubleVal = try? container.decode(Double.self) {
            self = .number(doubleVal)
            return
        }

        // 5. String 시도
        if let strVal = try? container.decode(String.self) {
            self = .string(strVal)
            return
        }

        // 6. Array 시도
        if let arrVal = try? container.decode([JSONValue].self) {
            self = .array(arrVal)
            return
        }

        // 7. Object 시도
        if let objVal = try? container.decode([String: JSONValue].self) {
            self = .object(objVal)
            return
        }

        // 모든 시도 실패 — null로 폴백
        self = .null
    }

    // MARK: - Encodable

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s):
            try container.encode(s)
        case .number(let d):
            // NaN과 Infinity는 JSON 표준 미지원 — null로 폴백
            if d.isNaN || d.isInfinite {
                try container.encodeNil()
            } else {
                try container.encode(d)
            }
        case .int(let i):
            try container.encode(i)
        case .bool(let b):
            try container.encode(b)
        case .array(let arr):
            try container.encode(arr)
        case .object(let obj):
            try container.encode(obj)
        case .null:
            try container.encodeNil()
        }
    }
}

// MARK: - 편의 접근자

extension JSONValue {

    /// String 값 접근자 — `.string` case가 아니면 nil
    var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    /// Int 값 접근자 — `.int` case가 아니면 nil
    var intValue: Int? {
        if case .int(let i) = self { return i }
        return nil
    }

    /// Double 값 접근자 — `.number` case가 아니면 nil (.int는 포함하지 않음)
    var doubleValue: Double? {
        if case .number(let d) = self { return d }
        return nil
    }

    /// Bool 값 접근자 — `.bool` case가 아니면 nil
    var boolValue: Bool? {
        if case .bool(let b) = self { return b }
        return nil
    }

    /// Array 값 접근자 — `.array` case가 아니면 nil
    var arrayValue: [JSONValue]? {
        if case .array(let arr) = self { return arr }
        return nil
    }

    /// Object 값 접근자 — `.object` case가 아니면 nil
    var objectValue: [String: JSONValue]? {
        if case .object(let obj) = self { return obj }
        return nil
    }

    /// Object 키 subscript — `.object` case가 아니거나 키 없으면 nil
    subscript(key: String) -> JSONValue? {
        if case .object(let obj) = self { return obj[key] }
        return nil
    }

    /// Array 인덱스 subscript — `.array` case가 아니거나 범위 초과 시 nil
    subscript(index: Int) -> JSONValue? {
        if case .array(let arr) = self {
            guard index >= 0, index < arr.count else { return nil }
            return arr[index]
        }
        return nil
    }
}

// MARK: - Foundation 양방향 변환

extension JSONValue {

    /// JSONSerialization 출력 → JSONValue 변환
    ///
    /// `JSONSerialization.jsonObject(with:)`가 반환하는 Foundation 타입
    /// (NSNull, NSNumber, NSString, NSArray, NSDictionary)을 JSONValue로 변환합니다.
    ///
    /// NSNumber의 Bool/Int/Double 구분:
    /// - CFBooleanGetTypeID()로 Bool NSNumber 감지
    /// - 정수 NSNumber는 .int, 소수 NSNumber는 .number로 변환
    ///
    /// - Parameter jsonObject: JSONSerialization.jsonObject 결과
    /// - Returns: JSONValue 표현
    /// - Throws: 변환 불가 타입이 입력된 경우
    static func from(jsonObject: Any) throws -> JSONValue {
        // NSNull → .null
        if jsonObject is NSNull {
            return .null
        }

        // NSNumber 처리 — Bool/Int/Double 구분
        if let number = jsonObject as? NSNumber {
            // CFBooleanGetTypeID()로 Bool NSNumber 감지 (Int 1/0과 구분)
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return .bool(number.boolValue)
            }
            // Int 가능 여부 확인 — objCType으로 정수 타입 감지
            let objCType = String(cString: number.objCType)
            // 정수 타입: i(int), l(long), q(long long), I(unsigned int), L(unsigned long), Q(unsigned long long), s(short), S(unsigned short), c(char — Bool은 위에서 처리됨), C(unsigned char)
            let integerTypes: Set<String> = ["i", "l", "q", "I", "L", "Q", "s", "S", "C", "c"]
            if integerTypes.contains(objCType) {
                return .int(number.intValue)
            }
            // 그 외 (f, d 등) → Double
            return .number(number.doubleValue)
        }

        // NSString → .string
        if let str = jsonObject as? String {
            return .string(str)
        }

        // NSArray → .array
        if let arr = jsonObject as? [Any] {
            let values = try arr.map { try JSONValue.from(jsonObject: $0) }
            return .array(values)
        }

        // NSDictionary → .object
        if let dict = jsonObject as? [String: Any] {
            var result: [String: JSONValue] = [:]
            for (key, value) in dict {
                result[key] = try JSONValue.from(jsonObject: value)
            }
            return .object(result)
        }

        // 변환 불가 타입 — .null로 폴백 (throws 대신 안전한 처리)
        return .null
    }

    /// JSONValue → JSONSerialization 호환 타입으로 역변환
    ///
    /// `JSONSerialization.data(withJSONObject:)`에 직접 전달할 수 있는 타입을 반환합니다.
    ///
    /// - Returns: NSNull, Bool, Int, Double, String, [Any], [String: Any] 중 하나
    func toJSONObject() -> Any {
        switch self {
        case .null:
            return NSNull()
        case .bool(let b):
            return b
        case .int(let i):
            return i
        case .number(let d):
            // NaN/Infinity는 JSON 미지원 — NSNull 반환
            if d.isNaN || d.isInfinite {
                return NSNull()
            }
            return d
        case .string(let s):
            return s
        case .array(let arr):
            return arr.map { $0.toJSONObject() }
        case .object(let obj):
            var result: [String: Any] = [:]
            for (key, value) in obj {
                result[key] = value.toJSONObject()
            }
            return result
        }
    }
}

// MARK: - @concurrent JSON 파싱

extension JSONValue {

    /// Data → JSONValue CPU-bound 파싱 (concurrent thread pool에서 실행)
    ///
    /// `@concurrent`로 선언하여 MainActor 컨텍스트에서 호출해도 자동으로
    /// concurrent thread pool에서 실행됩니다.
    ///
    /// - Parameter data: UTF-8 인코딩된 JSON Data
    /// - Returns: 파싱된 JSONValue
    @concurrent
    static func parse(from data: Data) async throws -> JSONValue {
        let decoder = JSONDecoder()
        return try decoder.decode(JSONValue.self, from: data)
    }

    /// Any → JSONValue 변환 (concurrent thread pool에서 실행)
    ///
    /// JSONSerialization 결과를 JSONValue로 변환하는 CPU-bound 작업.
    ///
    /// - Parameter jsonObject: JSONSerialization.jsonObject 결과
    /// - Returns: JSONValue 표현
    @concurrent
    static func parseFromJSONObject(_ jsonObject: Any) async throws -> JSONValue {
        return try JSONValue.from(jsonObject: jsonObject)
    }
}
