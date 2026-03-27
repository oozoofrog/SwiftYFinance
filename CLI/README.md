# swift-yf-tools CLI

Yahoo Finance 데이터를 터미널에서 바로 조회하는 CLI 도구 + MCP 서버.

- 상세 사용법: [USAGE.md](../USAGE.md)
- MCP 서버 참조: [README-MCP.md](README-MCP.md)
- 설치 안내: [루트 README](../README.md)

---

## 빌드

```bash
# CLI 디렉토리에서 실행 (별도 SPM 패키지)
cd CLI
swift build -c release --product swift-yf-tools

# 빌드 결과 확인
.build/release/swift-yf-tools --version
.build/release/swift-yf-tools --help
```

## 개발 빌드 및 테스트

```bash
# setup.sh — 빌드 + 래퍼 스크립트 생성 + 동작 확인
bash setup.sh

# 전체 통합 테스트 (네트워크 필요)
bash integration_test.sh

# 성능 벤치마크
bash benchmark.sh
```

## 빠른 실행 예시

```bash
cd CLI
swift build -c release --product swift-yf-tools

# 시세 조회
.build/release/swift-yf-tools quote AAPL TSLA

# 과거 데이터
.build/release/swift-yf-tools history AAPL --period 1mo

# 종합 기업 정보
.build/release/swift-yf-tools quotesummary AAPL --type essential

# 뉴스
.build/release/swift-yf-tools news AAPL

# 스크리닝
.build/release/swift-yf-tools screening day_gainers --limit 10

# WebSocket 실시간 스트리밍
.build/release/swift-yf-tools websocket AAPL TSLA --duration 30
```

## MCP 빠른 설치

MCP 설정은 CLI 안에 내장되어 있습니다.

```bash
# claude CLI로 원클릭 등록 (권장)
claude mcp add swift-yf-tools -- .build/release/swift-yf-tools mcp serve

# 또는 내장 mcp install 사용
.build/release/swift-yf-tools mcp install --client claude
.build/release/swift-yf-tools mcp install --client cursor
.build/release/swift-yf-tools mcp install --client local

# 설정 미리 보기 (파일 쓰기 없음)
.build/release/swift-yf-tools mcp install --client claude --dry-run

# MCP 서버 직접 실행 (stdio JSON-RPC 2.0)
.build/release/swift-yf-tools mcp serve
```

## PATH 등록

```bash
# /usr/local/bin에 심볼릭 링크 (시스템 전역)
sudo ln -sf "$(pwd)/.build/release/swift-yf-tools" /usr/local/bin/swift-yf-tools

# 또는 홈 디렉토리 bin에 등록
mkdir -p ~/.local/bin
ln -sf "$(pwd)/.build/release/swift-yf-tools" ~/.local/bin/swift-yf-tools
# export PATH="$HOME/.local/bin:$PATH" 를 셸 설정 파일에 추가
```

## 명령어 목록

| 명령어 | 설명 |
|---|---|
| `quote` | 단일/복수 종목 시세 |
| `quotesummary` | 종합 기업 정보 |
| `history` | 과거 가격 데이터 (OHLCV) |
| `search` | 종목 검색 |
| `fundamentals` | 재무 시계열 데이터 |
| `news` | 종목 뉴스 |
| `options` | 옵션 체인 |
| `screening` | 사전 정의 스크리닝 |
| `domain` | 섹터/산업/시장 도메인 |
| `custom-screening` | 사용자 조건 스크리닝 |
| `websocket` | 실시간 WebSocket 스트리밍 |
| `mcp` | MCP 설정 설치 및 서버 실행 |

각 명령어의 상세 옵션: [USAGE.md](../USAGE.md)

## JSON 출력

모든 명령어에서 `--json` 옵션으로 Yahoo Finance API의 원본 JSON 응답을 받을 수 있습니다.

```bash
.build/release/swift-yf-tools quote AAPL --json
.build/release/swift-yf-tools quotesummary AAPL --type essential --json
.build/release/swift-yf-tools history AAPL --period 1mo --json
```

## 라이선스

루트 패키지와 동일한 [Apache License 2.0](../LICENSE.md)을 따릅니다.
