# 공통 컨벤션 및 베스트 프랙티스

## Git 컨벤션 (Udacity 스타일)

### Commit 메시지 형식
```
<type>: <subject>

<body>

<footer>
```

### Type 종류
- `feat`: 새로운 서비스 추가
- `fix`: 서비스 설정 수정, 배포 오류 해결
- `docs`: 문서 수정 (README, 가이드)
- `style`: YAML 포맷팅, 설정 정리
- `refactor`: 서비스 구조 개선
- `chore`: 의존성 업데이트, 버전 업그레이드

### 브랜치 네이밍
```
<type>/<jira-ticket>-<brief-description>
```

### PR 제목
```
[SERVICE-XXX] <type>: <description>
```

## Jira 티켓 연동
- **브랜치명**: `feature/SERVICE-123-description`
- **커밋 메시지**: `feat: description (SERVICE-123)`
- **PR 제목**: `[SERVICE-123] feat: description`

## 서비스 배포 베스트 프랙티스
- ECR 이미지 자동 업데이트 활용
- 환경별 리소스 최적화 적용
- Slack 알림 채널 필수 설정
- HPA 및 리소스 제한 적절히 설정

## 파일 관리
- **다운로드 경로**: `~/Downloads/` 고정 사용
- **설정 백업**: 동일 경로에서 관리
- **임시 파일**: 날짜 포함 네이밍 (YYYY-MM-DD)