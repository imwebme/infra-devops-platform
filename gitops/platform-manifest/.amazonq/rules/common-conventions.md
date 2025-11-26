# 공통 컨벤션 및 베스트 프랙티스

## Git 컨벤션 (Udacity 스타일)

### Commit 메시지 형식
```
<type>: <subject>

<body>

<footer>
```

### Type 종류
- `feat`: 새로운 기능 추가 (새 애드온, 차트)
- `fix`: 버그 수정 (배포 실패, 설정 오류)
- `docs`: 문서 수정 (README, 가이드)
- `style`: 코드 포맷팅, YAML 정리
- `refactor`: 코드 리팩터링 (차트 구조 개선)
- `test`: 테스트 추가 (Helm test, 검증)
- `chore`: 빌드 업무, CI/CD 설정

### 브랜치 네이밍
```
<type>/<jira-ticket>-<brief-description>
```

### PR 제목
```
[DEVOPS-XXX] <type>: <description>
```

## Jira 티켓 연동
- **브랜치명**: `feature/DEVOPS-123-description`
- **커밋 메시지**: `feat: description (DEVOPS-123)`
- **PR 제목**: `[DEVOPS-123] feat: description`

## GitOps 베스트 프랙티스
- ApplicationSet 우선 사용
- Values 파일 계층화 (base → environment → cluster)
- 자동 동기화는 개발환경만 활성화
- 프로덕션은 수동 승인 필수

## 파일 관리
- **다운로드 경로**: `~/Downloads/` 고정 사용
- **차트 패키징**: 동일 경로에서 관리
- **백업 파일**: 날짜 포함 네이밍 (YYYY-MM-DD)