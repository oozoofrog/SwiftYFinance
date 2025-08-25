# Modular Components

단일 책임 원칙을 따르는 원자적 데이터 모델들입니다.

## 📋 포함된 모델

### YFQuoteBasicInfo
- **책임**: 종목 식별 정보
- **포함**: symbol, longName, shortName, quoteType
- **특징**: 변하지 않는 기본 정보

### YFQuoteExchangeInfo  
- **책임**: 거래소 및 통화 정보
- **포함**: exchange, exchangeName, currency, currencySymbol
- **특징**: 거래 환경 메타데이터

### YFQuoteMarketData
- **책임**: 실시간 시세 정보
- **포함**: price, open, high, low, change, changePercent
- **특징**: 가장 자주 업데이트되는 핵심 데이터

### YFQuoteVolumeInfo
- **책임**: 거래량 및 시장 상태
- **포함**: volume, averageVolume, marketCap, marketState
- **특징**: 거래 활동성 지표

### YFQuoteExtendedHoursData  
- **책임**: 장전/장후 거래 정보
- **포함**: preMarket/postMarket price, change, time
- **특징**: 시간대별 거래 데이터 분리

### YFQuoteMetadata
- **책임**: 시간 및 데이터 출처 정보
- **포함**: updateTime, maxAge, sourceName, priceHint
- **특징**: 데이터 품질 및 신뢰성 메타데이터

## 🎯 설계 원칙

### Single Responsibility Principle (SRP)
```
각 모델은 하나의 명확한 책임만 가짐
├── BasicInfo → 종목 식별만 담당
├── MarketData → 시세 데이터만 담당  
├── VolumeInfo → 거래량 정보만 담당
└── ... (각각 독립적 책임)
```

### High Cohesion, Low Coupling
```
모듈 내부는 높은 응집도
├── 관련된 필드들끼리 그룹화
└── 논리적으로 함께 사용되는 데이터 집합

모듈 간에는 낮은 결합도  
├── 상호 의존성 없음
├── Foundation만 import
└── 독립적 사용 가능
```

## ✨ 장점

- **재사용성**: 필요한 모듈만 선택적 사용
- **테스트 용이성**: 각 모듈별 독립적 테스트
- **유지보수성**: 변경 영향 범위 최소화
- **성능**: 필요한 데이터만 디코딩
- **타입 안전성**: 도메인별 강타입 보장