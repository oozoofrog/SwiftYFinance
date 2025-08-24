# Domain Models

도메인/섹터 데이터를 위한 응답 모델들입니다.

## 📋 포함된 모델

- **`YFDomainResponse`** - 도메인별 종목 리스트
- **`YFDomainSectorResponse`** - 섹터별 상세 데이터

## 🎯 사용 용도

- 섹터별 종목 현황
- 산업별 분류 데이터
- 시장별 종목 리스트

## ✨ 핵심 기능

```swift
// 기술 섹터 종목들
let techStocks = try await client.domain.fetch(
    type: .sector, 
    value: YFSector.technology.rawValue
)

for stock in techStocks {
    print("기술주: \(stock.symbol) - \(stock.name)")
}

// 미국 시장 종목들
let usMarket = try await client.domain.fetch(
    type: .market,
    value: YFMarket.us.rawValue
)
```