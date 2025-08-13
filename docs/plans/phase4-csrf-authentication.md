# Phase 4.3: Yahoo Finance CSRF 인증 시스템

## 🎯 목표
Yahoo Finance의 비공개 API 접근을 위한 CSRF 토큰 기반 인증 시스템 구현

## 📚 참조 분석
- **Python 구현**: yfinance-reference/yfinance/data.py
- **핵심 메서드**: `_get_cookie_and_crumb()`, `_get_crumb_basic()`, `_get_crumb_csrf()`
- **인증 전략**: basic (기본 쿠키) vs csrf (CSRF 토큰) 방식

## 📊 진행 상황
- **전체 진행률**: 0% 시작
- **현재 상태**: 설계 및 계획 단계

## 🔍 Yahoo Finance CSRF 인증 분석

### 인증 프로세스 (yfinance 방식)
1. **쿠키 획득**: `https://guce.yahoo.com/consent`에서 동의 프로세스
2. **CSRF 토큰**: csrfToken과 sessionId 추출 
3. **동의 처리**: POST 요청으로 동의 처리
4. **Crumb 토큰**: `https://query2.finance.yahoo.com/v1/test/getcrumb`에서 획득
5. **API 호출**: 모든 요청에 crumb 파라미터 자동 추가

### 전략별 차이점
- **basic 전략**: `https://query1.finance.yahoo.com/v1/test/getcrumb`
- **csrf 전략**: `https://query2.finance.yahoo.com/v1/test/getcrumb`

## Phase 4.3.1: CSRF 인증 기반 구조 설계

### YFSession CSRF 지원 확장 → YFSessionTests.swift
- [ ] testSessionCSRFTokenAcquisition - CSRF 토큰 획득
  - 📚 참조: yfinance-reference/yfinance/data.py:_get_cookie_csrf()
  - 🎯 목표: guce.yahoo.com에서 csrfToken/sessionId 추출
  - 🔍 확인사항: BeautifulSoup 파싱 로직을 Swift로 구현
- [ ] testSessionConsentProcess - 동의 프로세스 자동화
  - 📚 참조: yfinance-reference/yfinance/data.py consent POST 요청
  - 🎯 목표: 동의 처리 후 쿠키 획득
  - 🔍 확인사항: sessionId 기반 POST/GET 요청 순서
- [ ] testSessionCrumbAcquisition - Crumb 토큰 획득
  - 📚 참조: yfinance-reference/yfinance/data.py:_get_crumb_csrf()
  - 🎯 목표: `/v1/test/getcrumb`에서 crumb 토큰 추출
  - 🔍 확인사항: 쿠키 기반 인증 후 crumb 요청

### YFRequestBuilder Crumb 자동 추가 → YFRequestBuilderTests.swift
- [ ] testRequestBuilderWithCrumb - crumb 파라미터 자동 추가
  - 📚 참조: yfinance-reference/yfinance/data.py:get() 메서드
  - 🎯 목표: 모든 Yahoo Finance API 요청에 crumb 자동 추가
  - 🔍 확인사항: params에 crumb 수동 추가 방지 로직
- [ ] testRequestBuilderCrumbFallback - crumb 실패시 재시도
  - 📚 참조: yfinance-reference/yfinance/data.py 전략 전환 로직
  - 🎯 목표: basic ↔ csrf 전략 자동 전환
  - 🔍 확인사항: 401/403 응답시 재인증 로직

## Phase 4.3.2: CSRF 인증 시스템 구현

### Swift HTML 파싱 구현 → YFHTMLParserTests.swift
- [ ] testHTMLParserCSRFExtraction - HTML에서 CSRF 토큰 추출
  - 📚 참조: yfinance-reference/yfinance/data.py BeautifulSoup 로직
  - 🎯 목표: `<input name="csrfToken" value="...">` 추출
  - 🔍 확인사항: 정규표현식 또는 간단한 문자열 파싱
- [ ] testHTMLParserSessionIdExtraction - sessionId 추출
  - 📚 참조: yfinance-reference/yfinance/data.py sessionId 처리
  - 🎯 목표: `<input name="sessionId" value="...">` 추출
  - 🔍 확인사항: HTML 구조 변경에 대한 견고성

### 쿠키 관리 시스템 → YFCookieManagerTests.swift
- [ ] testCookieManagerStorage - 쿠키 저장/불러오기
  - 📚 참조: yfinance-reference/yfinance/data.py cookie 캐싱
  - 🎯 목표: HTTPCookieStorage 활용 쿠키 관리
  - 🔍 확인사항: 세션간 쿠키 지속성
- [ ] testCookieManagerStrategy - 전략별 쿠키 처리
  - 📚 참조: yfinance-reference/yfinance/data.py _cookie_strategy
  - 🎯 목표: basic/csrf 전략별 쿠키 관리
  - 🔍 확인사항: 전략 전환시 쿠키 초기화

## Phase 4.3.3: quoteSummary API 연동

### quoteSummary API 구조체 정의 → QuoteSummaryTests.swift  
- [ ] testQuoteSummaryResponse - API 응답 구조체 파싱
  - 📚 참조: yfinance-reference/yfinance/scrapers/quote.py QuoteSummary 구조
  - 🎯 목표: price, summaryDetail 모듈 파싱
  - 🔍 확인사항: ValueContainer<T> 구조 정의
- [ ] testQuoteSummaryErrorHandling - API 에러 응답 처리
  - 📚 참조: yfinance-reference/yfinance/scrapers/quote.py 에러 처리
  - 🎯 목표: quoteSummary.error 구조 파싱
  - 🔍 확인사항: 다양한 에러 코드 처리

### fetchQuote 실제 구현 → YFClientTests.swift
- [ ] testFetchQuoteWithCSRF - CSRF 인증 기반 fetchQuote
  - 📚 참조: yfinance-reference/yfinance/scrapers/quote.py
  - 🎯 목표: quoteSummary API 실제 호출
  - 🔍 확인사항: crumb 토큰 자동 추가 및 응답 파싱
- [ ] testFetchQuoteAuthFailover - 인증 실패시 재시도
  - 📚 참조: yfinance-reference/yfinance/data.py 재시도 로직
  - 🎯 목표: 401/403 에러시 재인증 후 재시도
  - 🔍 확인사항: 최대 재시도 횟수 제한

## 🚧 구현 우선순위

### 1단계: HTML 파싱 기반 구조 (이번 주)
1. **YFHTMLParser 구현** - CSRF 토큰/sessionId 추출
2. **YFSession CSRF 지원** - 동의 프로세스 자동화
3. **Crumb 토큰 획득** - getcrumb API 호출

### 2단계: 인증 시스템 통합 (다음 주)  
1. **YFRequestBuilder crumb 자동 추가** - 모든 API 요청 지원
2. **재인증 로직** - 실패시 자동 재시도
3. **fetchQuote 실제 구현** - quoteSummary API 연동

## 📋 테스트 전략

### 단위 테스트
- HTML 파싱 로직 독립 테스트
- 쿠키 관리 시스템 단위 테스트  
- CSRF 토큰 획득 프로세스 테스트

### 통합 테스트
- 전체 인증 플로우 E2E 테스트
- API 호출 with crumb 통합 테스트
- 재인증 시나리오 테스트

### 에러 시나리오 테스트
- 네트워크 오류시 처리
- HTML 구조 변경시 견고성
- Rate limiting 대응

## 🔗 연관 문서
- [Phase 4: API Integration](phase4-api-integration.md)
- [Phase 3: Network Layer](phase3-network.md)
- [파일 조직화 규칙](file-organization.md)