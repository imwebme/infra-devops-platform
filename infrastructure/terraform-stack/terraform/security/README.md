# Security Infrastructure

Demo 프로젝트의 보안 관련 인프라 설정을 관리하는 디렉토리입니다.

## 디렉토리 구조

```
security/
├── aws/                   # AWS 보안 설정
│   ├── aws_config/        # AWS Config 설정
│   ├── cloudtrail/        # AWS cloudtrail 설정
│   ├── guardduty/         # AWS guardduty 설정
│   ├── identity_center/   # AWS identity_center 설정
│   ├── security_hub/      # AWS security_hub 설정
│   └── ...                # 기타 AWS 보안 모듈
├── saas/                  # SaaS형 보안시스템 설정
└── README.md              # security terraform 가이드
```

## 설정 파일 설명

1. **security-aws-core-infra.yml**

   - 계정 레벨의 보안 서비스 설정
   - CloudTrail, Security Hub, GuardDuty, AWS Config, identity center 등
   - 개발환경 구분 없이 전체 계정에 적용되는 설정

2. **security-saas-infra.yml**

   - 정보보안에서 사용하는 SaaS 시스템 설정
   - Okta, Tailscale, Datadog, GitHub 등
   - 외부 보안 서비스 연동 설정

3. **security-aws-{env}-infra.yml**
   - 각 환경별 보안 리소스 설정
   - Security Group, Secret Manager, IAM 등
   - 환경별로 독립적인 보안 정책 적용

## 담당자

- **주 담당자**: kjg@iexample-org.com
- **부 담당자**: ops Team

## 주의사항

- 모든 보안 관련 변경사항은 DevSecOps 검토가 필요합니다
- 중요 변경사항은 보안팀과 협의가 필요합니다
- 정기적인 감사 및 규정 준수 검사가 필요합니다
- 환경별 설정 변경 시 다른 환경에 미치는 영향 검토가 필요합니다
