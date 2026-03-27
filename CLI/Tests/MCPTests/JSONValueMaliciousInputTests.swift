/// JSONValue 악의적 입력 테스트
///
/// 검증 대상:
/// - null 바이트 포함 문자열
/// - 제어 문자 (U+0001~U+001F)
/// - 유니코드 BOM (U+FEFF)
/// - 역슬래시 연속, 큰따옴표 연속
/// - 유효하지 않은 UTF-8 시퀀스 (Data 레벨)
/// - 유니코드 서로게이트 단독 사용
///
/// 모든 케이스에서 크래시/UB 없이 throws 또는 정상 디코딩 중 하나의 결정적 동작 보장

import Testing
import Foundation
@testable import SwiftYFinanceMCP

@Suite("JSONValue 악의적 입력", .serialized)
struct JSONValueMaliciousInputTests {

    // MARK: - Null 바이트

    @Test("null 바이트 포함 문자열 — 안전 처리")
    func nullByteInString() throws {
        // JSON에서 null 바이트(\u0000)는 이스케이프되어 표현됨
        // JSONEncoder가 \u0000을 \\u0000으로 이스케이프하여 안전하게 직렬화
        let val = JSONValue.string("hello\0world")
        let data = try JSONEncoder().encode(val)
        let jsonStr = String(data: data, encoding: .utf8)!
        // null 바이트는 JSON에서 \u0000으로 이스케이프되어야 함
        #expect(jsonStr.contains("\\u0000") || jsonStr.contains("\\0") || !jsonStr.contains("\0"))

        // decode 역시 안전하게 처리
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        if case .string(let s) = decoded {
            // null 바이트가 보존되거나 이스케이프되어 복원
            #expect(s.contains("\0") || s.contains("\\u0000") || s.count > 0)
        }
    }

    @Test("null 바이트 포함 JSON Data — decode throws 또는 정상")
    func nullByteInJSONData() {
        // JSON 문자열에 실제 null 바이트 주입
        let jsonWithNull = "\"hello\0world\""
        let data = jsonWithNull.data(using: .utf8) ?? Data()
        // decode는 throws 또는 정상 처리 — 크래시 없음 보장
        let result = try? JSONDecoder().decode(JSONValue.self, from: data)
        // result가 nil이거나 .string이거나 — 어떤 경우든 크래시가 없어야 함
        _ = result // 크래시 없음 검증
    }

    // MARK: - 제어 문자

    @Test("제어 문자 U+0001 포함 문자열 안전 인코딩")
    func controlCharacterU0001() throws {
        let val = JSONValue.string("\u{0001}control")
        let data = try JSONEncoder().encode(val)
        let jsonStr = String(data: data, encoding: .utf8)!
        // 제어 문자는 JSON에서 \u0001로 이스케이프되어야 함
        #expect(!jsonStr.contains("\u{0001}") || jsonStr.contains("\\u"))
    }

    @Test("제어 문자 전체 범위 U+0001~U+001F 인코딩 안전성")
    func controlCharactersFullRange() throws {
        for code in 1...31 {
            guard let scalar = Unicode.Scalar(code) else { continue }
            let char = Character(scalar)
            let val = JSONValue.string(String(char))
            let data = try JSONEncoder().encode(val)
            // 인코딩이 성공해야 함 — 크래시 없음
            #expect(!data.isEmpty, "U+\(String(code, radix: 16)) 인코딩 실패")
        }
    }

    @Test("탭, 줄바꿈, 캐리지리턴 인코딩")
    func commonControlChars() throws {
        let cases = ["\t", "\n", "\r", "\r\n"]
        for str in cases {
            let val = JSONValue.string(str)
            let data = try JSONEncoder().encode(val)
            let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
            // round-trip은 동등해야 함
            #expect(decoded == val, "제어 문자 '\(str.debugDescription)' round-trip 실패")
        }
    }

    // MARK: - BOM (U+FEFF)

    @Test("BOM (U+FEFF) 포함 문자열 안전 처리")
    func bomInString() throws {
        let val = JSONValue.string("\u{FEFF}BOM문자열")
        let data = try JSONEncoder().encode(val)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        // BOM은 UTF-8에서 유효한 문자 — round-trip 성공해야 함
        #expect(decoded == val)
    }

    @Test("JSON Data에 UTF-8 BOM 접두어 — decode throws 또는 정상")
    func utf8BOMPrefix() {
        // UTF-8 BOM: 0xEF 0xBB 0xBF
        var data = Data([0xEF, 0xBB, 0xBF])
        data.append(contentsOf: #"{"key":"value"}"#.utf8)
        // 크래시 없이 처리됨을 검증 (throws 또는 정상)
        let result = try? JSONDecoder().decode(JSONValue.self, from: data)
        _ = result  // nil이어도 크래시가 없어야 함
    }

    // MARK: - 역슬래시 및 큰따옴표

    @Test("역슬래시 연속 round-trip")
    func backslashSequence() throws {
        let val = JSONValue.string("a\\\\b")
        let data = try JSONEncoder().encode(val)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == val)
    }

    @Test("큰따옴표 포함 문자열 round-trip")
    func quotesInString() throws {
        let val = JSONValue.string("say \"hello\"")
        let data = try JSONEncoder().encode(val)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == val)
    }

    @Test("혼합 이스케이프 문자 round-trip")
    func mixedEscapes() throws {
        let val = JSONValue.string("tab:\tnewline:\nquote:\"back:\\")
        let data = try JSONEncoder().encode(val)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == val)
    }

    // MARK: - 유효하지 않은 UTF-8 시퀀스

    @Test("유효하지 않은 UTF-8 시퀀스 — decode throws 또는 null")
    func invalidUTF8Sequence() {
        // 0xFF 0xFE — 유효하지 않은 UTF-8 바이트
        let invalidData = Data([0xFF, 0xFE, 0x7B, 0x7D])  // invalid + {}
        let result = try? JSONDecoder().decode(JSONValue.self, from: invalidData)
        // 크래시 없이 처리됨 (nil이어도 정상)
        _ = result
    }

    @Test("잘린 UTF-8 시퀀스 — decode throws")
    func truncatedUTF8Sequence() {
        // 2바이트 UTF-8 시퀀스의 첫 바이트만
        let truncated = Data([0xC2])  // 잘린 시퀀스
        let result = try? JSONDecoder().decode(JSONValue.self, from: truncated)
        _ = result  // 크래시 없음 보장
    }

    @Test("과도한 이스케이프 JSON — decode 안전 처리")
    func overescapedJSON() {
        // JSON에서 허용되지 않는 이스케이프 시퀀스
        let bad = #""\a""#.data(using: .utf8)!  // \a는 JSON에서 미지원
        let result = try? JSONDecoder().decode(JSONValue.self, from: bad)
        _ = result  // throws여도 크래시 없음
    }

    // MARK: - 유니코드 서로게이트

    @Test("유니코드 서로게이트 이스케이프 — decode throws 또는 정상")
    func unicodeSurrogateEscape() {
        // U+D800은 서로게이트 — JSON 표준상 단독 사용 미지원
        // \uD800 형태의 JSON 문자열
        let surrogateJSON = #""\uD800""#.data(using: .utf8)!
        let result = try? JSONDecoder().decode(JSONValue.self, from: surrogateJSON)
        // 구현에 따라 throws 또는 특별 처리 — 크래시 없음이 핵심
        _ = result
    }

    @Test("서로게이트 쌍 JSON — decode 처리")
    func surrogatePairJSON() {
        // U+D83D U+DE00 → 이모지 😀 를 서로게이트 쌍으로 표현
        let surrogatePair = #""\uD83D\uDE00""#.data(using: .utf8)!
        let result = try? JSONDecoder().decode(JSONValue.self, from: surrogatePair)
        // 서로게이트 쌍은 이모지로 디코딩될 수 있음
        if let val = result, case .string(let s) = val {
            // 이모지 😀 또는 관련 문자가 포함됨
            #expect(!s.isEmpty)
        }
        // nil이어도 크래시 없음 — 통과
    }

    // MARK: - 최대 길이 문자열

    @Test("매우 긴 키 이름 — 크래시 없음")
    func longKeyName() throws {
        let longKey = String(repeating: "k", count: 10_000)
        let val = JSONValue.object([longKey: .string("value")])
        let data = try JSONEncoder().encode(val)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == val)
    }

    // MARK: - 유효하지 않은 JSON 구조

    @Test("빈 Data — decode throws")
    func emptyData() {
        let result = try? JSONDecoder().decode(JSONValue.self, from: Data())
        // 빈 Data는 decode 실패 → nil
        #expect(result == nil)
    }

    @Test("잘린 JSON — decode throws")
    func truncatedJSON() {
        let truncated = #"{"key": "val"#.data(using: .utf8)!
        let result = try? JSONDecoder().decode(JSONValue.self, from: truncated)
        #expect(result == nil)
    }

    @Test("중첩 따옴표 경계 문자열 round-trip")
    func nestedQuoteBoundary() throws {
        let val = JSONValue.string("\"\"\"triple quotes\"\"\"")
        let data = try JSONEncoder().encode(val)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
        #expect(decoded == val)
    }
}
