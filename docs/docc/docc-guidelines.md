# DocC 작성 가이드라인

## ⚠️ 작업 진행 주의사항

### 테스트 케이스 생성 금지
- **DocC 문서화 작업에서는 테스트 케이스를 생성하지 않습니다**
- 문서화는 소스 코드에 직접 DocC 주석을 추가하는 작업입니다
- 문서화 완료 여부는 실제 소스 파일 검토로 확인합니다
- 불필요한 테스트 파일 생성으로 프로젝트 복잡도를 증가시키지 않습니다

### Phase 완료시 필수 절차
각 Phase 완료 후 반드시 다음 절차를 수행합니다:

1. **DocC 빌드 검증**: 컴파일 및 문서 생성 테스트
2. **문서 업데이트**: 체크리스트 및 진행 상황 업데이트  
3. **Git 커밋**: 변경사항을 적절한 커밋 메시지와 함께 커밋

#### 커밋 메시지 형식
```
docs: Complete Phase X DocC documentation

- Add complete DocC comments to [파일명들]
- Verify compilation and DocC build success
- Update documentation checklist

Co-Authored-By: Claude <noreply@anthropic.com>
```

## 🎨 DocC 스타일 가이드

### 필수 포함 요소
1. **클래스/구조체 레벨**
   - 목적과 기능 명확 설명  
   - 주요 기능 bullet point
   - 실용적인 사용 예시
   - 관련 타입 참조 (SeeAlso)

2. **메서드 레벨**
   - 기능 요약
   - 파라미터 상세 설명
   - 반환값 설명  
   - 발생 가능한 에러
   - 사용 예시 (복잡한 경우)

3. **프로퍼티 레벨**
   - 값의 의미와 단위
   - 가능한 범위나 제약사항
   - nil인 경우의 의미 (Optional)

### 예시 코드 품질
- 실제 동작하는 코드
- 일반적인 사용 시나리오 반영
- 에러 처리 포함
- 결과값 활용 방법 제시

## 🔧 DocC 컴파일 및 빌드 방법

### 필수 사전 조건
- **Swift 6.1 이상**: DocC 지원을 위해 필요
- **Xcode**: `xcrun docc` 명령어 사용을 위해 필요

### 컴파일 검증 단계

#### 1단계: 프로젝트 컴파일 확인
```bash
swift build
```
- 모든 소스 파일이 오류 없이 컴파일되는지 확인
- DocC 주석 구문 오류도 이 단계에서 감지됨

#### 2단계: 심볼 그래프 생성
```bash
swift package dump-symbol-graph --pretty-print --minimum-access-level public
```
- 생성된 파일 위치: `.build/arm64-apple-macosx/symbolgraph/`
- SwiftYFinance.symbols.json 파일 확인

#### 3단계: DocC 문서 생성
```bash
xcrun docc convert \
  --additional-symbol-graph-dir .build/arm64-apple-macosx/symbolgraph \
  --output-dir ./docs-output \
  --fallback-display-name "SwiftYFinance" \
  --fallback-bundle-identifier "com.swiftyfinance.library"
```

#### 4단계: 생성된 문서 확인
```bash
# HTML 문서 구조 확인
ls ./docs-output/documentation/swiftyfinance/

# 브라우저에서 문서 열기 (macOS)
open ./docs-output/documentation/swiftyfinance/index.html

# 임시 파일 정리
rm -rf ./docs-output
```

### 문서 생성 성공 지표
- ✅ 컴파일 오류 없음
- ✅ 심볼 그래프 생성 성공
- ✅ HTML 문서 파일 생성 확인
- ✅ 경고 메시지 최소화 (다른 파일의 경고 제외)

### 문제 해결
- **컴파일 오류**: DocC 주석 구문 확인
- **심볼 그래프 실패**: Swift 버전 및 프로젝트 구조 확인  
- **DocC 변환 실패**: 필수 파라미터 및 경로 확인