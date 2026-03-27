---
globs: Sources/SwiftYFinance/Models/**/*.swift
---

# Models 레이어 규칙

Yahoo Finance API 응답과 비즈니스 로직을 위한 데이터 모델.

## 구조

- `Primitives/` — 기본 타입: YFError, YFPrice, YFQuoteType, YFTicker
- `Configuration/` — API 설정: YFDomain, YFQuoteSummaryModule, YFSearchQuery
- `Business/` — 비즈니스 모델: 재무제표(BalanceSheet, CashFlow), 실적(Earnings), 기술지표
- `Network/` — API 응답 매핑 모델 (Chart, Domain, Financials, News, Options, Quote, Screening, Search)
- `Screener/` — 스크리너 쿼리 모델
- `Streaming/` — WebSocket 스트리밍 모델

## 패턴

- 모든 모델은 `struct` + `Sendable` + `Decodable`
- Network 모델은 Yahoo Finance JSON 응답 구조를 그대로 반영
- Business 모델은 사용자 친화적으로 변환된 형태
- Quote 모델은 모듈화 설계: Core, ModularComponents, CompositeModels, ResponseWrappers로 분리
