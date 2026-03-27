/// 출력 스타일 유틸리티
///
/// 이모지 vs ASCII 대체 문자 전환을 담당합니다.
/// --no-emoji 플래그 활성화 시 이모지 대신 ASCII 문자를 출력합니다.
///
/// ## 사용 예시
/// ```swift
/// let style = OutputStyle(noEmoji: globalOptions.noEmoji)
/// print(style.up) // → "📈" 또는 "[UP]"
/// print(style.ok) // → "✅" 또는 "[OK]"
/// ```
///
/// nonisolated: 순수 데이터/유틸리티 struct — actor isolation 불필요
/// 모든 커맨드에서 공유합니다.

import Foundation

/// 이모지/ASCII 출력 스타일 구조체
nonisolated struct OutputStyle: Sendable {

    /// true이면 이모지 대신 ASCII 대체 문자 사용
    let noEmoji: Bool

    init(noEmoji: Bool = false) {
        self.noEmoji = noEmoji
    }

    // MARK: - 방향/상태 아이콘

    /// 상승 아이콘
    var up: String { noEmoji ? "[UP]" : "📈" }

    /// 하락 아이콘
    var down: String { noEmoji ? "[DOWN]" : "📉" }

    /// 성공/확인 아이콘
    var ok: String { noEmoji ? "[OK]" : "✅" }

    /// 에러/실패 아이콘
    var error: String { noEmoji ? "[ERR]" : "❌" }

    /// 상승 원형 아이콘
    var greenCircle: String { noEmoji ? "[+]" : "🟢" }

    /// 하락 원형 아이콘
    var redCircle: String { noEmoji ? "[-]" : "🔴" }

    /// 검색/분석 아이콘
    var search: String { noEmoji ? "[DBG]" : "🔍" }

    /// 차트/데이터 아이콘
    var chart: String { noEmoji ? "[DATA]" : "📊" }

    /// 회사 아이콘
    var company: String { noEmoji ? "[CO]" : "🏢" }

    /// 연결 아이콘
    var link: String { noEmoji ? "[CONN]" : "🔗" }

    /// 신호/스트리밍 아이콘
    var signal: String { noEmoji ? "[STRM]" : "📡" }

    /// 시간 아이콘
    var clock: String { noEmoji ? "[TIME]" : "⏱️" }

    /// 중지 아이콘
    var stop: String { noEmoji ? "[STOP]" : "🛑" }

    /// 뉴스 아이콘
    var news: String { noEmoji ? "[NEWS]" : "📰" }

    /// 힌트/팁 아이콘
    var hint: String { noEmoji ? "[TIP]" : "💡" }

    /// 구분선 (ASCII 호환)
    var separator: String { "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" }

    // MARK: - 가격 변화 아이콘

    /// 가격 변화에 따른 아이콘 선택
    func changeIcon(change: Double) -> String {
        if change >= 0 {
            return greenCircle
        } else {
            return redCircle
        }
    }

    /// 가격 추세에 따른 방향 아이콘
    func trendIcon(current: Double, previous: Double) -> String {
        if current > previous { return up }
        if current < previous { return down }
        return noEmoji ? "[=]" : "➡️"
    }
}

// MARK: - GlobalOptions

/// 전역 CLI 옵션 — 모든 서브커맨드에서 @OptionGroup으로 사용
import ArgumentParser

struct GlobalOptions: ParsableArguments {
    @Flag(name: .customLong("no-emoji"), help: "이모지 없이 ASCII 대체 문자로 출력합니다 (CI/파이프라인 환경에 적합)")
    var noEmoji: Bool = false
}
