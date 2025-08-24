# Search Models

종목 검색 결과를 위한 응답 모델들입니다.

## 📋 포함된 모델

- **`YFSearchResult`** - 검색 결과 항목

## 🎯 사용 용도

- 종목명/심볼로 종목 검색
- 자동완성 기능 구현
- 다중 종목 정보 조회

## ✨ 핵심 기능

```swift
let results = try await client.search.fetch(query: "Apple")

for result in results {
    print("심볼: \(result.symbol)")
    print("이름: \(result.shortname ?? result.longname ?? "")")
    print("유형: \(result.quoteType ?? "")")
    print("거래소: \(result.exchange ?? "")")
}
```