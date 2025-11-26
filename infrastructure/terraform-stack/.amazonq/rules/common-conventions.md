# 공통 컨벤션 및 베스트 프랙티스

## Git 컨벤션 (Udacity 스타일)

### Commit 메시지 형식
```
<type>: <subject>

<body>

<footer>
```

### Type 종류
- `feat`: 새로운 기능 추가
- `fix`: 버그 수정
- `docs`: 문서 수정
- `style`: 코드 포맷팅 (기능 변경 없음)
- `refactor`: 코드 리팩터링
- `test`: 테스트 추가
- `chore`: 빌드 업무, 의존성 업데이트

### 브랜치 네이밍
```
<type>/<jira-ticket>-<brief-description>
```

### PR 제목
```
[JIRA-XXX] <type>: <description>
```

## Jira 티켓 연동
- **브랜치명**: `feature/INFRA-123-description`
- **커밋 메시지**: `feat: description (INFRA-123)`
- **PR 제목**: `[INFRA-123] feat: description`

## 보안 규칙
- 하드코딩된 시크릿 절대 금지
- 최소 권한 원칙 적용
- 모든 리소스에 적절한 태그 적용

## 파일 관리
- **다운로드 경로**: `~/Downloads/` 고정 사용
- **임시 파일**: 동일 경로에서 관리
- **백업 파일**: 날짜 포함 네이밍 (YYYY-MM-DD)