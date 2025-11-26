# Services Manifest 보일러플레이트 템플릿

이 레포지토리는 보일러플레이트 템플릿으로 정리되었습니다. 새로운 서비스를 추가할 때 아래 템플릿 파일들을 참고하여 사용하세요.

## 템플릿 파일들

### 1. 설정 파일 템플릿
- `TEMPLATE-config.yaml`: 환경별 설정 파일 템플릿
  - CronJob 서비스와 일반 서비스 두 가지 형태 포함
  - `{ENV}` 플레이스홀더를 실제 환경(dev/prod/staging)으로 변경

### 2. Values 파일 템플릿  
- `TEMPLATE-service-values.yaml`: 일반 서비스용 values 템플릿 (Deployment 기반)
  - 리소스, HPA, 인그레스 등 모든 설정 포함
- `TEMPLATE-cronjob-values.yaml`: CronJob 서비스용 values 템플릿
  - CronJob 전용 설정 포함
- `TEMPLATE-scraper-values.yaml`: Scraper 서비스용 values 템플릿
  - StatefulSet 기반 설정 포함
  - `{ENV}` 플레이스홀더를 실제 환경으로 변경

## 남겨진 대표 파일들

### configs 디렉토리
- `configs/dev/workloads/demo-crons/nodejs-config.yaml`
- `configs/dev/workloads/demo-services/demo-back.yaml`
- `configs/dev/workloads/demo-scrapers/demo-node-scraper.yaml`
- `configs/prod/workloads/demo-crons/nodejs-config.yaml`
- `configs/prod/workloads/demo-services/active-demo-back.yaml`
- `configs/staging/workloads/demo-services/demo-back.yaml`

### environments 디렉토리
- `environments/base/workloads/demo-services/demo-back-values.yaml`
- `environments/base/workloads/demo-scrapers/demo-node-scraper-values.yaml`
- `environments/dev/workloads/demo-services/active/demo-back-values.yaml`
- `environments/prod/workloads/demo-services/active/demo-back-values.yaml`

## 사용 방법

1. 새로운 서비스 추가 시 템플릿 파일을 복사
2. `{ENV}` 플레이스홀더를 실제 환경으로 변경
3. 서비스별 설정값 수정 (리소스, 포트, 환경변수 등)
4. 적절한 디렉토리에 배치

## 환경별 차이점

### Dev 환경
- slack_channel: C082JSFBL7L
- 낮은 리소스 할당 (CPU: 400m, Memory: 750Mi)
- 적은 replica 수 (min: 2, max: 4)

### Prod 환경  
- slack_channel: C0794BUEYAX
- 높은 리소스 할당 (CPU: 1200m, Memory: 1100Mi)
- 많은 replica 수 (min: 10, max: 1500)
- 추가 로드밸런서 설정 및 로깅

### Staging 환경
- Dev와 유사하지만 별도 설정 가능