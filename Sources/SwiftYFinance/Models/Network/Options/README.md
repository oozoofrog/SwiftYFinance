# Options Models

옵션 체인 데이터를 위한 응답 모델들입니다.

## 📋 포함된 모델

- **`YFOptions`** - 옵션 체인 및 Greeks 데이터

## 🎯 사용 용도

- 옵션 체인 정보 조회
- Greeks (Delta, Gamma, Theta, Vega) 분석
- 만료일별 옵션 현황

## ✨ 핵심 기능

```swift
let options = try await client.options.fetch(ticker: ticker)

// 콜 옵션 분석
for call in options.calls {
    print("행사가: $\(call.strike)")
    print("프리미엄: $\(call.lastPrice)")
    print("델타: \(call.delta ?? 0)")
    print("만료일: \(call.expiration)")
}

// 풋 옵션 분석
for put in options.puts {
    print("행사가: $\(put.strike)")
    print("프리미엄: $\(put.lastPrice)")
    print("감마: \(put.gamma ?? 0)")
}
```