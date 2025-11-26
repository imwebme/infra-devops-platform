## 📋 변경 사항 요약

<!-- 이번 PR에서 변경된 내용을 간략히 설명해주세요 -->

## 🎯 관련 이슈

<!-- Jira 티켓이 있다면 연결해주세요 -->
- Jira: INFRA-XXX
- 관련 이슈: #XXX

## 🔧 변경된 인프라 영역

<!-- 해당하는 항목에 체크해주세요 -->
- [ ] AWS (`terraform/infra/aws/`)
- [ ] Datadog (`terraform/infra/datadog/`)
- [ ] GitHub (`terraform/infra/github/`)
- [ ] Sentry (`terraform/infra/sentry/`)
- [ ] Config (`terraform/config/`)

## 🧪 테스트 결과

<!-- terraform plan 결과를 첨부해주세요 -->
```
terraform plan 결과:
Plan: X to add, Y to change, Z to destroy.
```

## 📝 체크리스트

### 코드 품질
- [ ] 리소스명이 의미있게 작성되었나요?
- [ ] 모든 변수에 description이 추가되었나요?
- [ ] 태그가 일관성 있게 적용되었나요? (Environment, Project, Owner)
- [ ] 하드코딩된 시크릿이 없나요?

### 보안
- [ ] 최소 권한 원칙이 적용되었나요?
- [ ] S3 버킷에 암호화가 적용되었나요?
- [ ] 보안 그룹에서 필요한 포트만 열려있나요?
- [ ] 프로덕션 환경에서 deletion_protection이 활성화되었나요?

### 문서화
- [ ] README.md가 업데이트되었나요?
- [ ] 중요한 변경사항에 주석이 추가되었나요?

## 🚀 배포 계획

<!-- 배포 시 주의사항이나 순서가 있다면 명시해주세요 -->
- [ ] 배포 순서나 주의사항 없음
- [ ] 특별한 배포 순서 필요 (아래 명시)

### 배포 순서 (해당시)
1. 
2. 
3. 

## 📸 스크린샷 (선택사항)

<!-- 필요시 terraform plan 결과나 관련 스크린샷을 첨부해주세요 -->

## 🔗 추가 정보

<!-- 리뷰어가 알아야 할 추가 정보가 있다면 작성해주세요 -->