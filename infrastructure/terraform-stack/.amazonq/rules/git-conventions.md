# Git 컨벤션 및 워크플로우 가이드

## Commit 메시지 컨벤션 (Udacity 스타일)

### 기본 형식
```
<type>: <subject>

<body>

<footer>
```

### Type 종류
- `feat`: 새로운 기능 추가
- `fix`: 버그 수정
- `docs`: 문서 수정
- `style`: 코드 포맷팅, 세미콜론 누락 등 (기능 변경 없음)
- `refactor`: 코드 리팩터링
- `test`: 테스트 추가
- `chore`: 빌드 업무 수정, 패키지 매니저 설정 등

### 예시
```
feat: add VPC module for multi-AZ deployment (INFRA-123)

- Create VPC with public/private subnets
- Add NAT Gateway for private subnet internet access
- Configure route tables and security groups

Closes INFRA-123
```

## 브랜치 네이밍 컨벤션

### 형식
```
<type>/<jira-ticket>-<brief-description>
```

### 예시
- `feature/INFRA-123-add-vpc-module`
- `fix/INFRA-124-security-group-rules`
- `docs/INFRA-125-update-readme`
- `refactor/INFRA-126-restructure-modules`

## PR 제목 컨벤션

### 형식
```
[INFRA-XXX] <type>: <description>
```

### 예시
- `[INFRA-123] feat: add VPC module for multi-AZ deployment`
- `[INFRA-124] fix: correct security group ingress rules`
- `[INFRA-125] docs: update deployment process documentation`

## Jira 티켓 연동 규칙

### 필수 포함 위치
1. **브랜치명**: `feature/INFRA-123-description`
2. **커밋 메시지**: `feat: description (INFRA-123)`
3. **PR 제목**: `[INFRA-123] feat: description`
4. **PR 본문**: Jira 링크 포함

### 자동 연동을 위한 키워드
- `Closes INFRA-XXX`: 이슈 완료
- `Fixes INFRA-XXX`: 버그 수정 완료
- `Refs INFRA-XXX`: 이슈 참조