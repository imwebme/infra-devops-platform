# Demo Infrastructure 프로젝트 개요

## 프로젝트 목적
- **레브잇 인프라 운영 코드 관리**
- **Terraform을 통한 AWS 리소스 관리**
- **멀티 서비스 인프라 프로비저닝**

## 주요 구성 요소
- **AWS 인프라**: EKS, VPC, RDS, S3 등
- **Datadog 모니터링**: 메트릭, 로그, APM 설정
- **GitHub 리포지토리**: 자동화된 리포지토리 관리
- **Sentry 에러 트래킹**: 애플리케이션 에러 모니터링

## 디렉터리 구조
```
terraform/
├── infra/
│   ├── aws/          # AWS 리소스 관리
│   ├── datadog/      # Datadog 모니터링 설정
│   ├── github/       # GitHub 리포지토리 설정
│   └── sentry/       # Sentry 에러 트래킹 설정
└── config/           # 환경별 설정값 (tfvars)
```

## 환경 관리
- **개발환경**: dev, beta
- **스테이징환경**: staging
- **프로덕션환경**: prod

## 배포 프로세스
1. 로컬에서 `terraform plan` 실행
2. PR 생성 시 자동 plan 실행
3. 코드 리뷰 후 승인
4. PR 병합 시 자동 apply 실행

## 파일 다운로드 규칙
- 모든 이미지 및 파일 다운로드는 `~/Downloads/` 경로 사용
- 임시 파일 생성 시에도 동일 경로 활용