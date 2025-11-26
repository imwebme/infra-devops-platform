# 파일 관리 규칙

## 다운로드 경로 규칙
- **기본 경로**: `~/Downloads/` 고정 사용
- **모든 이미지 다운로드**: `~/Downloads/` 경로
- **모든 파일 다운로드**: `~/Downloads/` 경로
- **임시 파일 생성**: `~/Downloads/` 경로

## 파일 네이밍 컨벤션
- **백업 파일**: `{filename}-backup-{YYYY-MM-DD}.{ext}`
- **임시 파일**: `temp-{purpose}-{YYYY-MM-DD}.{ext}`
- **다운로드 파일**: 원본 이름 유지

## Terraform 관련 파일
- **Plan 출력**: `~/Downloads/terraform-plan-{env}-{YYYY-MM-DD}.txt`
- **State 백업**: `~/Downloads/terraform-state-backup-{env}-{YYYY-MM-DD}.tfstate`
- **설정 파일**: `~/Downloads/terraform-config-{env}-{YYYY-MM-DD}.tfvars`

## 정리 규칙
- 30일 이상 된 임시 파일 정리 권장
- 백업 파일은 수동 정리
- 다운로드 파일은 용도 완료 후 정리