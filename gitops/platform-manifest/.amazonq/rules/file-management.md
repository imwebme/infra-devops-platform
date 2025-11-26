# 파일 관리 규칙

## 다운로드 경로 규칙
- **기본 경로**: `~/Downloads/` 고정 사용
- **모든 이미지 다운로드**: `~/Downloads/` 경로
- **모든 파일 다운로드**: `~/Downloads/` 경로
- **차트 패키징**: `~/Downloads/` 경로

## 파일 네이밍 컨벤션
- **Helm 차트**: `{chart-name}-{version}.tgz`
- **Values 백업**: `{service}-values-backup-{YYYY-MM-DD}.yaml`
- **ApplicationSet 백업**: `{appset-name}-backup-{YYYY-MM-DD}.yaml`
- **임시 파일**: `temp-{purpose}-{YYYY-MM-DD}.{ext}`

## GitOps 관련 파일
- **차트 패키지**: `~/Downloads/{chart-name}-{version}.tgz`
- **설정 백업**: `~/Downloads/{cluster}-config-backup-{YYYY-MM-DD}.yaml`
- **템플릿 출력**: `~/Downloads/helm-template-{chart}-{YYYY-MM-DD}.yaml`

## 정리 규칙
- 30일 이상 된 임시 파일 정리 권장
- 차트 패키지는 배포 완료 후 정리
- 백업 파일은 수동 정리