# Composite Models

여러 데이터 소스를 조합한 복합 데이터 컨테이너 모델들입니다.

## 📋 포함된 모델

### YFQuoteResult
- **역할**: price + summaryDetail 데이터 조합 컨테이너
- **구성**: YFQuote + YFQuoteSummaryDetail
- **용도**: quoteSummary API에서 실시간 시세와 상세 분석을 함께 제공
- **특징**: 두 개의 독립적인 데이터 소스 결합

### YFQuoteSummaryDetail
- **역할**: 종목 상세 분석 정보 집합체
- **포함**: 재무 비율, 가격 대역, 거래량 분석, 배당 정보
- **크기**: 가장 큰 단일 모델 (150+ 필드)
- **독립성**: 다른 모델에 의존하지 않는 자립적 구조

## 🔗 데이터 조합 구조

```
YFQuoteResult
├── price: YFQuote (from Core/)
│   ├── basicInfo: YFQuoteBasicInfo
│   ├── marketData: YFQuoteMarketData  
│   ├── volumeInfo: YFQuoteVolumeInfo
│   └── ... (6개 ModularComponents)
│
└── summaryDetail: YFQuoteSummaryDetail
    ├── 호가 정보 (bid/ask)
    ├── 가격 정보 (high/low/open)
    ├── 거래량 정보 (volume/average)
    ├── 52주 데이터 (high/low)
    ├── 이동평균선 (50일/200일)
    ├── 재무 지표 (PE/PSR/Beta/MarketCap)
    ├── 배당 정보 (rate/yield/dates)
    └── 시스템 정보 (maxAge/priceHint)
```

## ✨ 특징

- **비즈니스 로직**: 투자 분석에 필요한 데이터 조합
- **유연성**: 각 구성요소를 독립적으로 사용 가능
- **완전성**: 종목 분석에 필요한 모든 정보 포함
- **확장성**: 새로운 분석 지표 추가 용이