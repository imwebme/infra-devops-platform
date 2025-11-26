# 공통 컨벤션 및 베스트 프랙티스

## Git 컨벤션 (Udacity 스타일)

### Commit 메시지 형식
```
<type>: <subject>

<body>

<footer>
```

### Type 종류
- `feat`: 새로운 기능 추가 (새 CLI 명령어, 봇 기능)
- `fix`: 버그 수정 (API 오류, 명령어 실행 오류)
- `docs`: 문서 수정 (README, 가이드)
- `style`: 코드 포맷팅, Go fmt 적용
- `refactor`: 코드 리팩터링 (구조 개선)
- `test`: 테스트 추가 (단위 테스트, 통합 테스트)
- `chore`: 빌드 업무, 의존성 업데이트

### 브랜치 네이밍
```
<type>/<jira-ticket>-<brief-description>
```

### PR 제목
```
[DEVOPS-XXX] <type>: <description>
```

## Go 개발 베스트 프랙티스
- `go fmt`, `go vet`, `golangci-lint` 필수 실행
- 에러 핸들링 명시적 처리
- 구조체 태그 일관성 유지
- 테스트 커버리지 80% 이상 목표

## Docker 컨벤션
- 멀티스테이지 빌드 사용
- 최소 베이스 이미지 (alpine, scratch)
- 보안 스캔 통과 필수
- 헬스체크 엔드포인트 포함

## 파일 관리
- **다운로드 경로**: `~/Downloads/` 고정 사용
- **빌드 아티팩트**: 동일 경로에서 관리
- **로그 파일**: 날짜 포함 네이밍 (YYYY-MM-DD)