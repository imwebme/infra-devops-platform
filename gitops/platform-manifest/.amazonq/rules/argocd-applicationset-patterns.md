# ArgoCD ApplicationSet 패턴 가이드

## ApplicationSet 기본 구조

### 표준 템플릿
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: {category}-{type}-appset
  namespace: argocd
spec:
  generators:
  - git:
      repoURL: https://github.com/demo/devops-gitops-manifest
      revision: HEAD
      directories:
      - path: "configs/*/{{category}}"
  template:
    metadata:
      name: "{{path.basename}}-{{category}}-{{path[1]}}"
    spec:
      project: default
      source:
        repoURL: https://github.com/demo/devops-gitops-manifest
        targetRevision: HEAD
        path: "{{category}}/{{path[1]}}"
      destination:
        server: https://kubernetes.default.svc
        namespace: "{{path[1]}}"
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

## Generator 패턴

### Git Directory Generator
- 클러스터별 자동 배포를 위한 표준 패턴
- `configs/*/addons` 구조로 클러스터 자동 감지
- Path 기반 필터링으로 환경 분리

### Cluster Generator (멀티 클러스터)
```yaml
generators:
- clusters:
    selector:
      matchLabels:
        environment: production
```

### Matrix Generator (복합 조건)
```yaml
generators:
- matrix:
    generators:
    - git: {...}
    - clusters: {...}
```

## 카테고리별 ApplicationSet 패턴

### Addons (인프라 애드온)
- **helm-external**: 외부 Helm 차트 (cert-manager, ingress-nginx 등)
- **helm-internal**: 내부 Helm 차트 (커스텀 애드온)
- **raw-internal**: Raw YAML 리소스 (CRDs, ConfigMaps 등)

### Workloads (애플리케이션)
- **helm-external**: 외부 애플리케이션 차트
- **helm-internal**: 내부 애플리케이션 차트
- **db-***: 데이터베이스 관련 워크로드

### Administrations (관리 도구)
- **admins**: 관리자 도구 및 설정
- **globals**: 전역 리소스 (네임스페이스, RBAC 등)

## 동기화 정책 표준

### 자동 동기화 (권장)
```yaml
syncPolicy:
  automated:
    prune: true      # 삭제된 리소스 자동 정리
    selfHeal: true   # 드리프트 자동 복구
  syncOptions:
  - CreateNamespace=true
  - PrunePropagationPolicy=foreground
  - PruneLast=true
```

### 수동 동기화 (중요 리소스)
```yaml
syncPolicy:
  syncOptions:
  - CreateNamespace=true
  retry:
    limit: 5
    backoff:
      duration: 5s
      factor: 2
      maxDuration: 3m
```

## Values 파일 관리 패턴

### 계층적 Values 구조
1. `environments/base/`: 기본값
2. `configs/{cluster}/`: 클러스터별 설정
3. ApplicationSet에서 자동 병합

### Helm Values 참조
```yaml
source:
  helm:
    valueFiles:
    - "../../environments/base/{{category}}/{{path[1]}}/values.yaml"
    - "../../configs/{{path.basename}}/{{category}}/{{path[1]}}/values.yaml"
```

## 네이밍 컨벤션

### ApplicationSet 이름
- `{category}-{type}-appset`: addons-helm-external-appset
- `{category}-{subcategory}-appset`: workloads-db-psmdb-appset

### Application 이름 (생성되는)
- `{{path.basename}}-{{category}}-{{path[1]}}`
- 예: `demo-dev-eks-addons-cert-manager`

### 네임스페이스 매핑
```yaml
destination:
  namespace: |
    {{- if eq .path[1] "cert-manager" -}}
    cert-manager
    {{- else if eq .path[1] "monitoring" -}}
    monitoring
    {{- else -}}
    {{.path[1]}}
    {{- end -}}
```

## 조건부 배포 패턴

### 환경별 필터링
```yaml
generators:
- git:
    directories:
    - path: "configs/*/addons"
      exclude: "configs/*-prod-*/addons"  # 프로덕션 제외
```

### 파일 존재 여부 확인
```yaml
generators:
- git:
    files:
    - path: "configs/*/addons/*/enabled"
```

### 라벨 기반 필터링
```yaml
template:
  metadata:
    labels:
      environment: "{{path.basename | regexFind \"(dev|staging|prod)\"}}"
```

## 에러 처리 및 디버깅

### 일반적인 문제
1. **Path 매칭 실패**: 디렉터리 구조 확인
2. **Values 파일 누락**: 기본값 설정 확인
3. **네임스페이스 충돌**: 네임스페이스 생성 정책 확인

### 디버깅 도구
```bash
# ApplicationSet 상태 확인
kubectl get applicationset -n argocd

# 생성된 Application 확인
kubectl get application -n argocd

# ApplicationSet 로그 확인
kubectl logs -n argocd deployment/argocd-applicationset-controller
```

## 보안 고려사항

### RBAC 설정
- ApplicationSet별 최소 권한 부여
- 네임스페이스 격리 원칙 준수
- 클러스터 관리자 권한 최소화

### 시크릿 관리
- Git 저장소에 시크릿 저장 금지
- External Secrets Operator 활용
- Sealed Secrets 또는 SOPS 사용

## 모니터링 및 알림

### ApplicationSet 메트릭
- 동기화 성공/실패 비율
- 배포 시간 추적
- 드리프트 감지 빈도

### 알림 설정
```yaml
metadata:
  annotations:
    notifications.argoproj.io/subscribe.on-sync-succeeded.slack: gitops-alerts
    notifications.argoproj.io/subscribe.on-sync-failed.slack: gitops-alerts
```