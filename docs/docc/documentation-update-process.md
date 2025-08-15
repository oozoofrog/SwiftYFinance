# 문서 업데이트 프로세스

SwiftYFinance 프로젝트의 문서를 체계적으로 관리하고 업데이트하기 위한 가이드입니다.

## 📋 개요

이 문서는 SwiftYFinance의 문서화 작업을 일관성 있고 효율적으로 수행하기 위한 표준 프로세스를 정의합니다.

## 🔄 업데이트 사이클

### 1. 정기 업데이트 (매월)

**첫째 주**: 코드 변경사항 반영
- 새로운 API 추가 시 문서화
- 기존 API 변경 시 문서 수정
- Deprecated API 표시 및 대안 제시

**둘째 주**: 예시 코드 검증
- 모든 코드 예시 컴파일 및 실행 테스트
- 최신 Swift 버전 호환성 확인
- 플랫폼별 동작 검증

**셋째 주**: 문서 품질 검토
- 문법 및 맞춤법 검사
- 용어 일관성 검증
- 링크 유효성 확인

**넷째 주**: 사용자 피드백 반영
- GitHub Issues 리뷰
- 커뮤니티 피드백 수집
- 개선사항 구현

### 2. 긴급 업데이트 (필요시)

다음 상황에서 즉시 문서 업데이트:
- 중요한 버그 수정
- 보안 관련 변경사항
- Yahoo Finance API 정책 변경
- 플랫폼 호환성 문제

## 📝 문서 업데이트 체크리스트

### API 문서화 체크리스트

#### 새로운 API 추가 시
- [ ] 클래스/구조체 상단 주석 작성
- [ ] 모든 public 메서드 문서화
- [ ] 매개변수 및 반환값 설명
- [ ] 사용 예시 코드 포함
- [ ] 에러 케이스 문서화
- [ ] 관련 타입 링크 추가

#### 기존 API 수정 시
- [ ] 변경사항 changelog에 기록
- [ ] 기존 예시 코드 업데이트
- [ ] Deprecated 표시 (필요시)
- [ ] 마이그레이션 가이드 작성
- [ ] 버전 호환성 정보 업데이트

### 가이드 문서 체크리스트

#### 신규 가이드 작성 시
- [ ] 목표 독자 명확화
- [ ] 단계별 설명 구조화
- [ ] 실행 가능한 예시 제공
- [ ] 주의사항 및 제약사항 명시
- [ ] 관련 문서 링크 연결

#### 기존 가이드 업데이트 시
- [ ] 최신 API 사용법 반영
- [ ] 스크린샷 및 출력 결과 업데이트
- [ ] 성능 벤치마크 갱신
- [ ] 커뮤니티 피드백 반영
- [ ] SEO 최적화 키워드 검토

## 🛠️ 문서화 도구 및 워크플로우

### 1. 로컬 개발 환경

```bash
# DocC 문서 빌드
swift package generate-documentation

# 로컬 서버에서 문서 확인
swift package --disable-sandbox preview-documentation
```

### 2. 자동화된 품질 검사

```bash
#!/bin/bash
# docs/scripts/validate-docs.sh

echo "📚 문서 품질 검사 시작..."

# 1. DocC 빌드 검증
echo "🔨 DocC 빌드 확인..."
swift package generate-documentation || {
    echo "❌ DocC 빌드 실패"
    exit 1
}

# 2. 링크 유효성 검사
echo "🔗 링크 유효성 검사..."
find Sources -name "*.md" -exec grep -l "<doc:" {} \; | while read file; do
    echo "검사 중: $file"
    # 링크 검증 로직
done

# 3. 코드 예시 컴파일 검증
echo "💻 코드 예시 검증..."
# 임시 Swift 파일 생성하여 컴파일 테스트

# 4. 용어 일관성 검사
echo "📖 용어 일관성 검사..."
grep -r "symbol\|ticker" Sources/SwiftYFinance/SwiftYFinance.docc/ | \
    awk -F: '{print $1":"$2}' | sort | uniq -c

echo "✅ 문서 품질 검사 완료"
```

### 3. GitHub Actions 통합

```yaml
# .github/workflows/docs-validation.yml
name: Documentation Validation

on:
  pull_request:
    paths:
      - 'Sources/**/*.swift'
      - 'Sources/**/*.md'
      - 'docs/**/*.md'

jobs:
  validate-docs:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Swift
      uses: swift-actions/setup-swift@v1
      with:
        swift-version: '6.1'
    
    - name: Build Documentation
      run: swift package generate-documentation
    
    - name: Run Documentation Validation
      run: ./docs/scripts/validate-docs.sh
    
    - name: Check for Broken Links
      run: |
        # 링크 검증 스크립트 실행
        python docs/scripts/check-links.py
```

## 📈 버전 관리 및 배포

### 1. 시맨틱 버전 관리

**Major (X.0.0)**
- 호환성을 깨는 API 변경
- 주요 아키텍처 변경
- 문서 구조 대규모 개편

**Minor (X.Y.0)**
- 새로운 기능 추가
- 새로운 가이드 문서 추가
- 기존 기능의 확장

**Patch (X.Y.Z)**
- 버그 수정
- 문서 오탈자 수정
- 예시 코드 개선

### 2. 문서 배포 프로세스

```bash
#!/bin/bash
# docs/scripts/deploy-docs.sh

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "사용법: ./deploy-docs.sh <version>"
    exit 1
fi

echo "📦 문서 배포 준비: v$VERSION"

# 1. 문서 빌드
swift package generate-documentation

# 2. 버전 태그 생성
git tag -a "docs-v$VERSION" -m "Documentation version $VERSION"

# 3. 배포용 아카이브 생성
tar -czf "swiftyfinance-docs-v$VERSION.tar.gz" .build/documentation

echo "✅ 문서 v$VERSION 배포 준비 완료"
```

## 🤝 협업 가이드

### 1. 문서 리뷰 프로세스

**작성자 체크리스트**:
- [ ] 맞춤법 및 문법 검사
- [ ] 코드 예시 동작 확인
- [ ] 관련 문서와의 일관성 확인
- [ ] 적절한 리뷰어 지정

**리뷰어 체크리스트**:
- [ ] 내용의 정확성 검증
- [ ] 초보자 이해도 확인
- [ ] 기존 문서와의 중복 검토
- [ ] 용어 사용 일관성 확인

### 2. 이슈 트래킹

**문서 관련 이슈 라벨**:
- `documentation`: 일반 문서 이슈
- `docs-bug`: 문서 오류
- `docs-enhancement`: 문서 개선
- `docs-question`: 문서 관련 질문

**이슈 템플릿**:
```markdown
## 문서 개선 요청

**대상 문서**: (예: Authentication.md)
**섹션**: (예: CSRF Authentication)

**현재 문제점**:
- 설명이 불명확함
- 예시 코드가 동작하지 않음

**제안하는 개선사항**:
- 단계별 설명 추가
- 실행 가능한 예시 코드 제공

**추가 정보**:
- 사용 환경: macOS 15.0, Swift 6.1
- 참고 자료: (링크나 문서)
```

## 📊 문서 품질 메트릭

### 1. 자동 수집 메트릭

```swift
struct DocumentationMetrics {
    let totalDocumentedAPIs: Int
    let documentationCoverage: Double // %
    let averageExamplesPerAPI: Double
    let brokenLinksCount: Int
    let outdatedExamplesCount: Int
    
    func generateReport() -> String {
        return """
        📊 문서 품질 리포트
        ├─ 문서화 커버리지: \(String(format: "%.1f", documentationCoverage))%
        ├─ API당 평균 예시: \(String(format: "%.1f", averageExamplesPerAPI))개
        ├─ 깨진 링크: \(brokenLinksCount)개
        └─ 업데이트 필요 예시: \(outdatedExamplesCount)개
        """
    }
}
```

### 2. 사용자 피드백 수집

```markdown
<!-- 각 문서 하단에 포함할 피드백 섹션 -->
## 📝 피드백

이 문서가 도움이 되었나요?

- 👍 [매우 도움됨](피드백 링크)
- 👌 [도움됨](피드백 링크)  
- 👎 [개선 필요](피드백 링크)

**개선 제안이나 질문이 있다면 [GitHub Issues](링크)에 등록해 주세요.**
```

## 🎯 문서 품질 목표

### 단기 목표 (3개월)
- [ ] API 문서화 커버리지 95% 달성
- [ ] 모든 가이드에 실행 가능한 예시 코드 포함
- [ ] 깨진 링크 0개 유지
- [ ] 자동화된 품질 검사 구축

### 중기 목표 (6개월)
- [ ] 다국어 지원 (영어 번역)
- [ ] 인터랙티브 튜토리얼 추가
- [ ] 비디오 가이드 제작
- [ ] 커뮤니티 기여 가이드라인 완성

### 장기 목표 (1년)
- [ ] 업계 최고 수준의 문서화 품질 달성
- [ ] 문서 자동 생성 도구 개발
- [ ] 사용자 만족도 95% 이상
- [ ] 문서화 베스트 프랙티스 표준화

---

이 프로세스는 SwiftYFinance 프로젝트의 지속적인 발전과 사용자 경험 향상을 위해 정기적으로 검토하고 개선해야 합니다.