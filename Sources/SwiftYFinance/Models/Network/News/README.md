# News Models

뉴스 데이터를 위한 응답 모델들입니다.

## 📋 포함된 모델

- **`YFNews`** - 뉴스 기사 데이터

## 🎯 사용 용도

- 종목별 관련 뉴스 조회
- 시장 뉴스 및 분석
- 센티멘트 분석 데이터

## ✨ 핵심 기능

```swift
let news = try await client.news.fetch(ticker: ticker)

for article in news {
    print("제목: \(article.title)")
    print("요약: \(article.summary ?? "")")
    print("발행시간: \(article.providerPublishTime)")
    
    if let sentiment = article.sentiment {
        print("센티멘트: \(sentiment)")
    }
}
```