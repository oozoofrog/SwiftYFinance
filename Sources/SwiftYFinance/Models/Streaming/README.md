# Streaming

WebSocket을 통한 실시간 데이터 스트리밍 관련 모델들을 정의합니다.

## 📋 포함된 모델

### Real-time Data
- **`YFLiveStreamMessage`** - 실시간 가격 데이터 메시지
- **`YFSubscription`** - WebSocket 구독 상태 관리
- **`YFWebSocketState`** - 연결 상태 enum
- **`YFLiveStreamHandler`** - 실시간 데이터 핸들러 타입
- **`YFWebSocketStateHandler`** - 상태 변경 핸들러 타입

## 🎯 목적

Yahoo Finance WebSocket을 통한 실시간 시세 데이터 처리를 담당합니다.

## ✨ 특징

- **실시간 처리**: 밀리초 단위 가격 업데이트
- **상태 관리**: 연결/구독 상태 추적
- **에러 처리**: 연결 실패 및 파싱 오류 대응
- **타입 안전성**: Sendable 준수로 동시성 보장

## 📖 사용 예시

```swift
// 실시간 스트리밍 시작
let client = YFClient()
let stream = try await client.startRealTimeStreaming(
    symbols: ["AAPL", "TSLA", "MSFT"]
)

// 실시간 데이터 수신
for await message in stream {
    if let error = message.error {
        print("스트림 에러: \(error)")
        continue
    }
    
    guard let symbol = message.symbol,
          let price = message.price else { continue }
    
    print("\(symbol): $\(price)")
    
    if let change = message.changePercent {
        print("변동률: \(change)%")
    }
}

// 구독 관리
let subscription = YFSubscription(
    symbols: ["AAPL", "GOOGL"]
)
let updated = subscription.adding(["MSFT", "TSLA"])
```

## 🔄 데이터 흐름

1. **연결 설정**: WebSocket 연결 및 인증
2. **심볼 구독**: 관심 종목 구독 요청
3. **실시간 수신**: 가격 변동 실시간 수신
4. **상태 관리**: 연결/구독 상태 추적