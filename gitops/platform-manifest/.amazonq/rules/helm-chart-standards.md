# Helm 차트 개발 표준

## 차트 구조 표준

### 필수 파일
- `Chart.yaml`: 차트 메타데이터
- `values.yaml`: 기본 설정값
- `templates/`: Kubernetes 리소스 템플릿
- `README.md`: 차트 사용법 및 설명

### 권장 구조
```
charts/{category}/{chart-name}/
├── Chart.yaml
├── values.yaml
├── README.md
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── _helpers.tpl
└── tests/
    └── test-connection.yaml
```

## Values 파일 표준

### 네이밍 규칙
- camelCase 사용: `replicaCount`, `serviceAccount`
- 중첩 구조로 논리적 그룹화
- 환경별 오버라이드 가능하도록 설계

### 필수 섹션
```yaml
# 기본 애플리케이션 설정
image:
  repository: ""
  tag: ""
  pullPolicy: IfNotPresent

# 리소스 관리
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi

# 보안 설정
securityContext:
  runAsNonRoot: true
  runAsUser: 1000

# 서비스 설정
service:
  type: ClusterIP
  port: 80

# 모니터링
monitoring:
  enabled: false
  serviceMonitor:
    enabled: false
```

## 템플릿 베스트 프랙티스

### Labels 표준화
```yaml
metadata:
  labels:
    {{- include "chart.labels" . | nindent 4 }}
    app.kubernetes.io/component: {{ .Values.component | default "app" }}
```

### Annotations 활용
```yaml
metadata:
  annotations:
    {{- with .Values.podAnnotations }}
    {{- toYaml . | nindent 8 }}
    {{- end }}
```

### 조건부 리소스
```yaml
{{- if .Values.serviceAccount.create }}
apiVersion: v1
kind: ServiceAccount
{{- end }}
```

## 보안 표준

### 필수 보안 설정
- `runAsNonRoot: true`
- `readOnlyRootFilesystem: true` (가능한 경우)
- `allowPrivilegeEscalation: false`
- `capabilities.drop: ["ALL"]`

### 시크릿 관리
- External Secrets 연동
- 하드코딩된 시크릿 금지
- ConfigMap과 Secret 분리

## 모니터링 통합

### ServiceMonitor 템플릿
```yaml
{{- if and .Values.monitoring.enabled .Values.monitoring.serviceMonitor.enabled }}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ include "chart.fullname" . }}
spec:
  selector:
    matchLabels:
      {{- include "chart.selectorLabels" . | nindent 6 }}
  endpoints:
  - port: metrics
{{- end }}
```

### Prometheus 메트릭
- `/metrics` 엔드포인트 표준화
- 커스텀 메트릭 네이밍 규칙 준수
- Grafana 대시보드 연동

## 테스트 표준

### Helm Test 작성
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "chart.fullname" . }}-test"
  annotations:
    "helm.sh/hook": test
spec:
  restartPolicy: Never
  containers:
  - name: wget
    image: busybox
    command: ['wget']
    args: ['{{ include "chart.fullname" . }}:{{ .Values.service.port }}']
```

### 로컬 테스트
```bash
# 템플릿 검증
helm template . --values values.yaml

# 린트 검사
helm lint .

# 테스트 실행
helm test <release-name>
```

## 버전 관리

### 시맨틱 버저닝
- `MAJOR.MINOR.PATCH` 형식
- Breaking changes: MAJOR 증가
- 새 기능: MINOR 증가
- 버그 수정: PATCH 증가

### Chart.yaml 예시
```yaml
apiVersion: v2
name: my-addon
description: A Helm chart for my addon
type: application
version: 1.0.0
appVersion: "1.0.0"
dependencies:
- name: common
  version: "^1.0.0"
  repository: "file://../common"
```

## 의존성 관리

### 공통 차트 활용
- `charts/common/`: 공통 템플릿 및 헬퍼
- 중복 코드 최소화
- 표준화된 라벨 및 셀렉터

### 외부 의존성
- 안정적인 버전 고정
- 정기적인 업데이트 계획
- 보안 취약점 모니터링

## 문서화 표준

### README.md 필수 섹션
1. 차트 설명
2. 설치 방법
3. 설정 옵션 (values.yaml 설명)
4. 예제 사용법
5. 업그레이드 가이드
6. 문제 해결

### Values 문서화
```yaml
# 애플리케이션 이미지 설정
image:
  # 컨테이너 이미지 저장소
  repository: nginx
  # 이미지 태그 (기본값: Chart appVersion)
  tag: ""
  # 이미지 풀 정책
  pullPolicy: IfNotPresent
```