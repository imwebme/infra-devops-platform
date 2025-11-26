# 파일 관리 규칙

## 다운로드 경로 규칙
- **기본 경로**: `~/Downloads/` 고정 사용
- **모든 이미지 다운로드**: `~/Downloads/` 경로
- **모든 파일 다운로드**: `~/Downloads/` 경로
- **설정 파일 백업**: `~/Downloads/` 경로

## 파일 네이밍 컨벤션
- **서비스 설정**: `{service-name}-config-{env}-{YYYY-MM-DD}.yaml`
- **Values 백업**: `{service-name}-values-backup-{YYYY-MM-DD}.yaml`
- **Application 백업**: `{app-name}-backup-{YYYY-MM-DD}.yaml`
- **임시 파일**: `temp-{purpose}-{YYYY-MM-DD}.{ext}`

## 서비스 관련 파일
- **설정 백업**: `~/Downloads/{service}-config-backup-{env}-{YYYY-MM-DD}.yaml`
- **이미지 정보**: `~/Downloads/{service}-image-info-{YYYY-MM-DD}.txt`
- **배포 로그**: `~/Downloads/{service}-deploy-log-{YYYY-MM-DD}.txt`

## 정리 규칙
- 30일 이상 된 임시 파일 정리 권장
- 배포 관련 파일은 배포 완료 후 정리
- 백업 파일은 수동 정리