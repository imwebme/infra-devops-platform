# DevOps 애드온 배포 가이드

## 프로젝트 개요
- **목적**: 멀티 클러스터 인프라 애드온 및 데이터베이스 워크로드 관리
- **클러스터 구조**: `{service}-{env}-eks` (예: demo-dev-eks, data-prod-eks)
- **ApplicationSet**: 클러스터별 세분화된 관리

## 애드온 배포 파일 생성 가이드

### 필수 파일 구조
```
configs/{cluster}/addons/helm-internal-elements.yaml
environments/base/addons/{namespace}/{addon-name}.yaml
clusters/{cluster}/addons/{namespace}/{addon-name}.yaml
```

### 애드온 정의 파일 (configs/{cluster}/addons/helm-internal-elements.yaml)
```yaml
key:
  components:
    - chart:
        name: {addon-name}
        repo: https://github.com/wetripod/devops-gitops-manifest
        path: {addon-name}
        version: main
        namespace: {target-namespace}
        values_path: {namespace}/{addon-name}.yaml
        auto_sync: true
```

### 기본 Values 파일 (environments/base/addons/{namespace}/{addon-name}.yaml)
```yaml
image:
  repository: {image-repo}
  tag: {version}
  pullPolicy: IfNotPresent

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi

securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true

monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
```

### 클러스터별 Values 파일 (clusters/{cluster}/addons/{namespace}/{addon-name}.yaml)
```yaml
resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 150m
    memory: 192Mi

env:
  CLUSTER_NAME: {cluster}
  ENVIRONMENT: {env}
```

## ApplicationSet 매칭 규칙
```yaml
generators:
- clusters:
    selector:
      matchLabels:
        aws_cluster_name: "{{ index .path.segments 1 }}"
```

## 네이밍 컨벤션
- **Application**: `devops-{cluster}-addon-{addon-name}`
- **네임스페이스**: `monitoring`, `cert-manager`, `external-secrets`

## 체크리스트
- [ ] Helm 차트 준비
- [ ] 애드온 정의 파일 생성
- [ ] 기본 Values 파일 작성
- [ ] 클러스터별 설정 확인
- [ ] 네임스페이스 및 RBAC 설정
- [ ] 모니터링 설정 확인

## 파일 다운로드 규칙
- 모든 파일 다운로드는 `~/Downloads/` 경로 사용
- 차트 패키징 및 백업 파일도 동일 경로 활용