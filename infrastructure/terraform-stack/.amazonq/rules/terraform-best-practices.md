# Terraform Infrastructure Best Practices for Demo

## 코딩 스타일 및 네이밍 규칙

- 리소스명은 의미있게 작성: `demo_vpc_public_subnet` (O), `subnet_1` (X)
- 변수명은 snake_case 사용
- 태그는 일관성 있게 적용 (Environment, Project, Owner)
- 모든 리소스에 description 추가

## 보안 및 베스트 프랙티스

- 하드코딩된 시크릿 절대 금지
- 최소 권한 원칙 적용
- 모든 S3 버킷에 암호화 적용
- 보안 그룹은 최소한의 포트만 오픈
- 프로덕션 환경에서는 deletion_protection 활성화

## 프로젝트 구조

### Terraform 디렉터리 구조
- `terraform/infra/aws/`: AWS 리소스 관리
- `terraform/infra/datadog/`: Datadog 모니터링 설정
- `terraform/infra/github/`: GitHub 리포지토리 및 설정
- `terraform/infra/sentry/`: Sentry 에러 트래킹 설정
- `terraform/config/`: 환경별 설정값 관리 (tfvars)

### 코드 구조
- 모듈화를 통한 재사용성 확보
- variables.tf, outputs.tf, main.tf 분리
- 환경별 tfvars 파일은 terraform/config/ 에서 관리
- 상태 파일은 원격 백엔드 사용 (Terraform Cloud)

## Terraform 실행 플로우

### 명령어 실행 방식
- 상위 디렉터리에서 `-chdir=terraform/infra/{service}` 옵션 사용
- 예시: `terraform -chdir=terraform/infra/aws plan`
- 환경별 설정: `terraform/config/` 디렉터리의 tfvars 파일 참조

### CI/CD 워크플로우
- PR 오픈 시: `.github/workflows/` 의 워크플로우가 `terraform plan` 실행
- PR 병합 시: 자동으로 `terraform apply` 실행
- 모든 워크플로우는 `.github/workflows/` 디렉터리에서 관리

## Git 컨벤션

### Commit 메시지 (Udacity 스타일)
- `feat: 새로운 기능 추가`
- `fix: 버그 수정`
- `docs: 문서 수정`
- `style: 코드 포맷팅`
- `refactor: 코드 리팩터링`
- `test: 테스트 추가`
- `chore: 빌드 업무 수정`

### 브랜치 및 Jira 연동
- 브랜치명: `feature/INFRA-123-add-vpc-module`
- 커밋 메시지에 Jira 티켓 포함: `feat: add VPC module (INFRA-123)`
- PR 제목에도 티켓 번호 명시

## 문서화

- 모든 변수에 description 필수
- README.md에 사용법 명시
- 중요한 변경사항은 주석으로 설명
- Jira 티켓 번호를 PR 및 커밋에 연결

## 배포 프로세스

- 로컬에서는 plan만 실행
- 모든 변경사항은 PR을 통해 진행
- 코드 리뷰 필수 (최소 1명 승인)
- PR 병합 시 자동으로 apply 실행
- Jira 티켓과 연동하여 추적성 확보