# Response Wrappers

Yahoo Finance API 응답을 직접 매핑하는 최상위 래퍼 모델들입니다.

## 📋 포함된 모델

### YFQuoteSummaryResponse
- **역할**: quoteSummary API의 최상위 응답 래퍼
- **포함**: YFQuoteSummary 객체
- **용도**: quoteSummary 엔드포인트 응답 파싱

### YFQuoteResponse  
- **역할**: query1 quote API의 응답 래퍼
- **포함**: YFQuote 배열과 에러 메시지
- **특징**: Custom decoding 로직 포함
- **용도**: query1 엔드포인트 응답 파싱

### YFQuoteSummary
- **역할**: quoteSummary API 데이터 컨테이너  
- **포함**: YFQuoteResult 배열과 에러 메시지
- **용도**: 성공/실패 응답 처리

## 🔗 관계도

```
Yahoo Finance API Response
         ↓
YFQuoteSummaryResponse → YFQuoteSummary → YFQuoteResult[]
                                              ↓
YFQuoteResponse → YFQuote[]                   ↓
                    ↓                         ↓  
              [Core Models] ←─────────────────┘
```

## ✨ 특징

- **API 직접 매핑**: JSON 응답 구조와 1:1 대응
- **에러 처리**: API 에러 메시지 캐치 및 전달
- **Custom Decoding**: 복잡한 JSON 구조 파싱
- **타입 안전성**: 컴파일 타임 타입 검증