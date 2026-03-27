# 제품 스펙: swift-yf-tools 문서 정비 & 설치 경험 개선

## 개요

swift-yf-tools(구 swiftyfinance-mcp)는 Yahoo Finance API Swift 라이브러리 + CLI 도구 + MCP 서버를 하나의 저장소에 제공하는 프로젝트입니다.
최근 저장소 이름이 변경되었으나 문서 곳곳에 이전 이름(SwiftYFinance CLI, SwiftYFinance MCP, swiftyfinance)이 잔존합니다.
이번 작업은 이름 통일, MCP 설치 경험 현대화, README 재구성, 설치 스크립트 신규 제공을 목표로 합니다.
사람과 AI Agent 모두 GitHub 링크만 보고 즉시 설치·사용 가능해야 합니다.

## 대상 플랫폼

macOS 15+ / CLI (Swift Package Manager 기반)

## 핵심 기능 (작업 범위)

1. 이전 이름(swiftyfinance, SwiftYFinanceMCP, SwiftYFinance CLI 등) 전수 탐지 및 swift-yf-tools로 통일
2. 루트 README.md를 "설치 우선" 구조로 완전 재작성 — 사람과 Agent 양쪽에서 바로 읽을 수 있는 형태
3. `claude mcp add` / `swift-yf-tools mcp install` 두 경로 모두를 README 최상단에 명시
4. install.sh 현대적 설치 스크립트 신규 생성 (curl one-liner 지원, `--client` 선택, PATH 등록)
5. 상세 사용법을 USAGE.md로 분리 (CLI 명령어 레퍼런스, MCP 툴 목록, 예제)
6. CLI/README.md를 CLI 전용 빠른 시작 문서로 재정비
7. CLI/README-MCP.md를 MCP 전용 참조 문서로 재정비 (tool 목록, JSON-RPC 테스트 방법)
8. CLI/setup.sh 이름 통일 및 내용 현대화
9. json-samples/README.md 이름 참조 정비
10. Sources/SwiftYFinance/SwiftYFinance.docc/CLI.md 이름 참조 정비

## 기술 스택

- Shell: Bash (install.sh)
- 문서: Markdown
- CLI 도구: swift-yf-tools (ArgumentParser 기반)
- MCP 프로토콜: stdio JSON-RPC 2.0
- 참조 문서: 없음 (Apple 프레임워크 불관련 — 순수 문서/스크립트 작업)

## 환경

- Xcode MCP: 미연결 (빌드 검증은 Bash로 대체)
- 검증 도구: `swift build` (CLI 디렉토리 내), `bash -n`(스크립트 문법 검사)
- 프로젝트 규칙: CLAUDE.md 준수 — Swift 6.2, Sendable, nonisolated, 한국어 주석
- Git 상태: 많은 변경 파일이 이미 staged/modified 상태 (현재 상태 기반 작업)
- 시뮬레이터 자동화: 없음 (CLI/문서 작업)

## 사용자 맥락

- 핵심 우선순위: 설치 경험 — GitHub 링크만 보고 바로 설치 가능해야 함
- 차별화 방향: `claude mcp add` CLI 명령 + curl one-liner install.sh
- 기술적 제약: 기존 Swift 소스 파일(SwiftYFinanceCLI, SwiftYFinanceMCP 타겟명)은 변경하지 않음 — 문서와 스크립트만 정비
- 디자인 취향: 깔끔하고 현대적, 이모지 최소화, 코드 블록 우선

## 차별화 기능

- `claude mcp add swift-yf-tools` 명령을 README 최상단에 원클릭 설치로 배치
- curl로 install.sh를 받아 실행하는 one-liner 설치 경로 제공
- Agent 친화적: 설치 후 즉시 쓸 수 있는 MCP tool 목록을 USAGE.md에 구조화
- dry-run 지원 설치 스크립트로 실제 쓰기 전 미리 확인 가능

## 범위 외

- Swift 소스 코드 변경 (SwiftYFinanceCLI, SwiftYFinanceMCP 타겟명은 내부 구현이므로 유지)
- 새로운 기능 구현 (MCP 툴 추가, 새 CLI 명령어 등)
- Package.swift의 name 필드 변경 (이미 swift-yf-tools로 설정된 것 확인 필요)
- 테스트 코드 수정 (기능 변경 없으므로 불필요)
