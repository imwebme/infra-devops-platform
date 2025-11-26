# 파일 관리 규칙

## 다운로드 경로 규칙
- **기본 경로**: `~/Downloads/` 고정 사용
- **모든 이미지 다운로드**: `~/Downloads/` 경로
- **모든 파일 다운로드**: `~/Downloads/` 경로
- **빌드 아티팩트**: `~/Downloads/` 경로

## 파일 네이밍 컨벤션
- **바이너리 파일**: `{app-name}-{version}-{os}-{arch}`
- **로그 파일**: `{app-name}-{YYYY-MM-DD}.log`
- **백업 파일**: `{filename}-backup-{YYYY-MM-DD}.{ext}`
- **임시 파일**: `temp-{purpose}-{YYYY-MM-DD}.{ext}`

## 애플리케이션별 파일
- **Slack Bot**: `~/Downloads/slack-bot-{version}.tar.gz`
- **DevOps CLI**: `~/Downloads/levit-devops-{version}-{os}-{arch}`
- **Docker 이미지**: `~/Downloads/{app-name}-{version}.tar`
- **테스트 결과**: `~/Downloads/test-results-{app}-{YYYY-MM-DD}.xml`

## Go 프로젝트 관련 파일
- **빌드 출력**: `~/Downloads/go-build-{app}-{YYYY-MM-DD}.log`
- **테스트 커버리지**: `~/Downloads/coverage-{app}-{YYYY-MM-DD}.html`
- **벤치마크 결과**: `~/Downloads/benchmark-{app}-{YYYY-MM-DD}.txt`

## 정리 규칙
- 30일 이상 된 임시 파일 정리 권장
- 빌드 아티팩트는 배포 완료 후 정리
- 로그 파일은 수동 정리