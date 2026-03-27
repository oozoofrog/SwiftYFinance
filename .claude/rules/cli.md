---
globs: CLI/**/*.swift
---

# CLI 규칙

SwiftYFinance 라이브러리를 사용하는 별도 SPM 패키지의 커맨드라인 도구.

## 구조

- `CLI/Package.swift` — 별도 패키지 매니페스트 (루트 Package.swift와 독립)
- `Commands/` — 각 기능별 커맨드 (Quote, History, Search, News, Options 등)
- `Utils/` — 에러 핸들링, 포매터, JSON 출력, 파서, 아이콘

## 빌드

```bash
cd CLI && swift build
```

## 주의

- 루트 SwiftYFinance 패키지와는 별도로 빌드/테스트
- CLI 변경이 라이브러리 API에 영향을 주지 않도록 유지
