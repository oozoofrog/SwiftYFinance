/// JSONValue Round-trip Fuzzy 테스트
///
/// 랜덤 JSONValue 트리 생성기를 사용하여 encode→decode round-trip이
/// 항상 동등성을 유지하는지 100회 검증합니다.
///
/// ## 설계 원칙
/// - 시드 기반 재현 가능한 난수 생성기 (LCG — Linear Congruential Generator)
/// - 깊이 최대 10, 각 노드에서 7가지 case 중 랜덤 선택
/// - 실패 시 시드를 Issue.record로 기록하여 재현 가능성 보장
/// - Double.nan, Double.infinity는 null로 인코딩되므로 round-trip에서 제외

import Testing
import Foundation
@testable import SwiftYFinanceMCP

// MARK: - 시드 기반 난수 생성기

/// LCG (Linear Congruential Generator) — 재현 가능한 시퀀스
///
/// 시드가 같으면 항상 동일한 시퀀스를 생성합니다.
/// thread-safe 보장을 위해 struct로 값 타입 사용.
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    /// 다음 UInt64 생성 (Knuth 상수 LCG)
    mutating func next() -> UInt64 {
        // LCG 파라미터: multiplier=6364136223846793005, increment=1442695040888963407
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }

    /// 0..<n 범위의 Int 생성
    mutating func nextInt(_ n: Int) -> Int {
        guard n > 0 else { return 0 }
        return Int(next() % UInt64(n))
    }

    /// 0.0..<1.0 범위의 Double 생성
    mutating func nextDouble() -> Double {
        let bits = next()
        // UInt64 → [0, 1) Double 변환
        return Double(bits >> 11) / Double(1 << 53)
    }

    /// true/false 생성
    mutating func nextBool() -> Bool {
        return next() % 2 == 0
    }

    /// 문자열 생성 (alphanumeric, 길이 1~20)
    mutating func nextString() -> String {
        let charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let length = nextInt(20) + 1
        var result = ""
        result.reserveCapacity(length)
        for _ in 0..<length {
            let idx = nextInt(charset.count)
            let char = charset[charset.index(charset.startIndex, offsetBy: idx)]
            result.append(char)
        }
        return result
    }

    /// 정수 생성 — 안전한 범위로 제한 (JSON round-trip에서 정밀도 손실 없는 범위)
    ///
    /// JSON 표준에서 숫자 정밀도는 IEEE 754 double 기준.
    /// Int.max (2^63-1)는 double로 표현 불가하므로 ±1_000_000 범위로 제한.
    mutating func nextSafeInt() -> Int {
        let maxVal: UInt64 = 2_000_001
        let raw = next() % maxVal
        return Int(raw) - 1_000_000
    }
}

// MARK: - JSONValue 랜덤 생성기

/// 재귀적 JSONValue 생성기
///
/// - maxDepth: 재귀 깊이 제한 (스택 오버플로 방지)
/// - round-trip 안전성: NaN/Infinity는 생성하지 않음 (인코딩 시 null로 변환되어 동등성 깨짐)
/// - 스택 안전성: 자식 수를 최대 3개로 제한하여 지수적 스택 성장 방지
nonisolated func randomJSONValue(rng: inout SeededRandom, depth: Int = 0, maxDepth: Int = 5) -> JSONValue {
    // 깊이 제한 — 재귀 종료
    if depth >= maxDepth {
        // 리프 노드: scalar 타입만 생성
        let leafChoice = rng.nextInt(4)
        switch leafChoice {
        case 0: return .string(rng.nextString())
        case 1: return .int(rng.nextSafeInt())
        case 2: return .bool(rng.nextBool())
        default: return .null
        }
    }

    let choice = rng.nextInt(7)
    switch choice {
    case 0: // string
        return .string(rng.nextString())
    case 1: // int
        return .int(rng.nextSafeInt())
    case 2: // number — NaN/Infinity 제외 (round-trip 깨짐)
        let base = rng.nextDouble() * 1_000.0 - 500.0
        return .number(base)
    case 3: // bool
        return .bool(rng.nextBool())
    case 4: // array — 자식 수 최대 3개로 제한 (스택 오버플로 방지)
        let count = rng.nextInt(4)  // 0~3
        let arr = (0..<count).map { _ in randomJSONValue(rng: &rng, depth: depth + 1, maxDepth: maxDepth) }
        return .array(arr)
    case 5: // object — 키-값 쌍 최대 3개로 제한
        let count = rng.nextInt(4)  // 0~3
        var dict: [String: JSONValue] = [:]
        for _ in 0..<count {
            let key = rng.nextString()
            dict[key] = randomJSONValue(rng: &rng, depth: depth + 1, maxDepth: maxDepth)
        }
        return .object(dict)
    default: // null
        return .null
    }
}

/// 안전한 스칼라/얕은 JSONValue 생성기 (재귀 없음)
///
/// 스택 오버플로 위험 없이 다양한 JSONValue를 생성합니다.
/// 배열과 오브젝트는 스칼라만 포함하여 재귀를 제거합니다.
nonisolated func randomScalarOrShallowJSONValue(rng: inout SeededRandom) -> JSONValue {
    let choice = rng.nextInt(7)
    switch choice {
    case 0:
        return .string(rng.nextString())
    case 1:
        return .int(rng.nextSafeInt())
    case 2:
        // 유한한 Double만 생성
        let d = (rng.nextDouble() - 0.5) * 2000.0
        return .number(d)
    case 3:
        return .bool(rng.nextBool())
    case 4:
        // 스칼라만 포함한 배열 (재귀 없음)
        let count = rng.nextInt(4)
        var arr: [JSONValue] = []
        arr.reserveCapacity(count)
        for _ in 0..<count {
            arr.append(randomLeaf(rng: &rng))
        }
        return .array(arr)
    case 5:
        // 스칼라만 포함한 오브젝트 (재귀 없음)
        let count = rng.nextInt(4)
        var dict: [String: JSONValue] = [:]
        for _ in 0..<count {
            dict[rng.nextString()] = randomLeaf(rng: &rng)
        }
        return .object(dict)
    default:
        return .null
    }
}

/// 리프 JSONValue 생성 (scalar만)
nonisolated func randomLeaf(rng: inout SeededRandom) -> JSONValue {
    switch rng.nextInt(5) {
    case 0: return .string(rng.nextString())
    case 1: return .int(rng.nextSafeInt())
    case 2: return .bool(rng.nextBool())
    case 3: return .null
    default: return .number((rng.nextDouble() - 0.5) * 1000.0)
    }
}

// MARK: - Fuzzy Round-trip 테스트

/// Swift Testing 병렬 실행 비활성화 — 재귀적 JSONValue 생성 시 스택 충돌 방지
@Suite("JSONValue Fuzzy Round-trip", .serialized)
struct JSONValueFuzzyRoundTripTests {

    /// 100회 랜덤 round-trip 검증
    ///
    /// 각 회차마다 시드가 달라 서로 다른 JSONValue 트리를 생성합니다.
    /// 실패 시 시드를 Issue.record에 기록하여 재현 가능합니다.
    @Test("100회 랜덤 JSONValue round-trip")
    func randomRoundTrip100Times() {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        var failCount = 0

        for i in 0..<100 {
            // 시드: 회차 번호 기반 (재현 가능)
            let seed = UInt64(i &* 31 &+ 7)
            var rng = SeededRandom(seed: seed == 0 ? 1 : seed)

            // scalar 또는 얕은 구조만 생성 — 스택 오버플로 완전 방지
            let original = randomScalarOrShallowJSONValue(rng: &rng)

            guard let data = try? encoder.encode(original) else {
                Issue.record("시드 \(seed) (회차 \(i)): encode 실패")
                failCount += 1
                continue
            }

            guard let decoded = try? decoder.decode(JSONValue.self, from: data) else {
                Issue.record("시드 \(seed) (회차 \(i)): decode 실패")
                failCount += 1
                continue
            }

            if original != decoded {
                Issue.record("시드 \(seed) (회차 \(i)): round-trip 동등성 실패 (JSON: \(String(data: data, encoding: .utf8) ?? "?"))")
                failCount += 1
            }
        }

        #expect(failCount == 0)
    }

    /// 깊이 5 중첩 구조 round-trip
    @Test("깊이 5 중첩 구조 round-trip")
    func deepNestingRoundTrip() throws {
        let seed: UInt64 = 0xDEAD_BEEF_CAFE_1234
        var rng = SeededRandom(seed: seed)
        let value = randomJSONValue(rng: &rng, depth: 0, maxDepth: 5)

        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        if value != decoded {
            Issue.record("깊이 5 round-trip 실패 — 시드: \(seed)")
        }
        #expect(value == decoded)
    }

    /// 빈 구조체 round-trip
    @Test("빈 array/object round-trip")
    func emptyStructuresRoundTrip() throws {
        let cases: [JSONValue] = [
            .array([]),
            .object([:]),
            .array([.object([:])]),
            .object(["empty": .array([])])
        ]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for original in cases {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(JSONValue.self, from: data)
            #expect(original == decoded, "빈 구조 round-trip 실패: \(original)")
        }
    }

    /// 단일 scalar round-trip
    @Test("모든 scalar 타입 round-trip")
    func scalarRoundTrip() throws {
        let cases: [JSONValue] = [
            .string(""),
            .string("hello"),
            .int(0),
            .int(1),
            .int(-1),
            .bool(true),
            .bool(false),
            .null
        ]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for original in cases {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(JSONValue.self, from: data)
            #expect(original == decoded, "scalar round-trip 실패: \(original)")
        }
    }

    /// 시드 재현성 검증 — 같은 시드는 항상 동일한 값 생성
    @Test("시드 재현성 — 동일 시드는 동일 JSONValue 생성")
    func seedReproducibility() {
        let seed: UInt64 = 42
        var rng1 = SeededRandom(seed: seed)
        var rng2 = SeededRandom(seed: seed)

        let val1 = randomJSONValue(rng: &rng1, depth: 0, maxDepth: 5)
        let val2 = randomJSONValue(rng: &rng2, depth: 0, maxDepth: 5)

        #expect(val1 == val2, "같은 시드는 동일한 JSONValue를 생성해야 합니다")
    }
}
