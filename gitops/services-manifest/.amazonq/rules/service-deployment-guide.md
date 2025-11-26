# Demo 서비스 배포 가이드

## 프로젝트 개요
- **목적**: Demo 서비스 애플리케이션 배포 전용
- **환경 구조**: `{env}` (dev, staging, prod)
- **ApplicationSet**: 환경별 통합 관리

## 신규 서비스 배포 파일 생성 가이드

### 필수 파일 구조
```
configs/{env}/workloads/demo-services/{service-name}.yaml
environments/base/workloads/demo-services/{service-name}-values.yaml
environments/{env}/workloads/demo-services/{type}/{service-name}-values.yaml
```

### 서비스 정의 파일 (configs/{env}/workloads/demo-services/{service-name}.yaml)
```yaml
application_name: {service-name}
chart_name: {service-name}
chart_version: 0.0.1
slack_channel: C082JSFBL7L  # 알림 채널
type: active  # active, batch, worker 중 선택
source: nodejs  # nodejs, java, python 등
source_repo: https://github.com/wetripod/{service-name}
# 선택사항
disableAutoSync: false  # 자동 동기화 비활성화
ecrRepo: custom-ecr-repo  # 커스텀 ECR 저장소
branch_name: main  # 기본값: main
```

### 기본 Values 파일 (environments/base/workloads/demo-services/{service-name}-values.yaml)
```yaml
tolerations:
  - effect: NoSchedule
    key: DemoServicesOnly
    value: "true"
    operator: Equal

nodeSelector:
  service: demo-services

deployment:
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi
  port: 3000
  
hpa:
  enabled: true
  minReplicas: 1
  maxReplicas: 3
  targetCPUUtilizationPercentage: 70
```

### 환경별 Values 파일 (environments/{env}/workloads/demo-services/{type}/{service-name}-values.yaml)
```yaml
deployment:
  image:
    repository: 123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/demo-{env}-ecr_{service-name}
    tag: latest
  resources:
    requests:
      cpu: 200m
      memory: 512Mi
    limits:
      cpu: 400m
      memory: 1Gi
  env:
  - name: DD_SERVICE
    value: {service-name}
  - name: DD_ENV
    value: {env}

hpa:
  minReplicas: 2
  maxReplicas: 5

ingress:
- name: {service-name}
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    external-dns.alpha.kubernetes.io/hostname: {service-name}.{env}.example.com
  rules:
  - host: {service-name}.{env}.example.com
    paths:
    - path: /
      pathType: Prefix
```

## ApplicationSet 매칭 규칙
```yaml
generators:
- clusters:
    selector:
      matchLabels:
        environment: "{{ index .path.segments 1 }}"
```

## 네이밍 컨벤션
- **Application**: `levit-{cluster}-workload-{service-name}`
- **네임스페이스**: `demo-services`, `demo-scrapers`, `demo-cronjobs`

## ArgoCD Image Updater 설정
- ECR 이미지 자동 업데이트
- Helm values 자동 커밋
- 태그 패턴 매칭: `^\\d+.*-.*$`

## 체크리스트
- [ ] 서비스 정의 파일 생성
- [ ] 기본 Values 파일 작성
- [ ] 환경별 Values 파일 설정
- [ ] ECR 저장소 확인
- [ ] 네임스페이스 존재 확인
- [ ] Slack 채널 설정

## 파일 다운로드 규칙
- 모든 파일 다운로드는 `~/Downloads/` 경로 사용
- 설정 백업 및 임시 파일도 동일 경로 활용