# `values.yaml`

---

```yaml
# -- 서비스 이름 정의 (정의 하지 않을 경우 default 설정됨 - 설정 권장)
# @default -- `""` (default: {{ .Release.Name }})

appName: ""

tolerations: []
affinity: {}
# @default -- `{}`  (If you set a value, the fixed value is removed (requires setting).
#  podAntiAffinity:
#    preferredDuringSchedulingIgnoredDuringExecution:
#      - weight: 99
#        podAffinityTerm:
#          labelSelector:
#            matchExpressions:
#            - key: "app.kubernetes.io/name"
#              operator: In
#              values:
#              - {{ include "base-helm.realname" . }}
#          topologyKey: "kubernetes.io/hostname"
nodeSelector: {}

# -- Deployment 정의
deployment:
  replicas: 1
  # -- deployment 추가 label 설정
  # @default -- `{}` (default: {{ base-helm.selectorLabels }})
  labels: {}
  #  app: test-app
  annotations: {}
  image:
    # -- 사용 할 컨테이너 이미지
    # @default -- `""` (default: nginx)
    repository: ""
    # -- 사용 한 컨테이너 이미지 태그
    # @default -- `""` (default: nginx:1.14.2)
    tag: ""
    # -- 이미지 pull 정책
    # @default -- `""` (default: IfNotPresent)
    # @options -- IfNotPresent, Always, Never
    imagePullPolicy: ""
  env: []
  #  - name: DB_PASSWORD
  #    value: null
  command: []
  #  - "echo"
  args: []
  #  - "test"
  securityContext: {}
  # @default --
  # runAsNonRoot: true
  # runAsUser: 1000
  # runAsGroup: 3000
  port: 80
  volumes: []
  #  - name: test-vol
  #    emptyDir: {}
  volumeMounts: []
  #  - mountPath: /temp
  #    name: test-vol
  livenessProbe: {}
  #  failureThreshold: 3
  #  httpGet:
  #    path: /health-check
  #    port: http
  #  initialDelaySeconds: 10
  #  periodSeconds: 10
  #  successThreshold: 1
  #  timeoutSeconds: 1
  readinessProbe: {}
  #  failureThreshold: 3
  #  httpGet:
  #    path: /health-check
  #    port: http
  #  initialDelaySeconds: 10
  #  periodSeconds: 10
  #  successThreshold: 1
  #  timeoutSeconds: 1
  startupProbe: {}
  #  failureThreshold: 3
  #  httpGet:
  #    path: /health-check
  #    port: http
  #  initialDelaySeconds: 10
  #  periodSeconds: 10
  #  successThreshold: 1
  #  timeoutSeconds: 1
  resources: {}
  #  requests:
  #    memory: "64Mi" (default: 1024Mi)
  #    cpu: "250m" (default: 250m)
  #  limits:
  #    memory: "128Mi" (default: 1024Mi)
  #    cpu: "500m" (default: 2000m)
  # @default -- `""` (default: 4)
  revisionHistoryLimit: ""
  # @default -- `""` (default: 25%)
  maxSurge: ""
  # @default -- `""` (default: 0)
  maxUnavailable: ""

additionalPorts:
  - targetPort: 8002
    servicePort: 8002
    portName: metric

ingress:
  enabled: false
  gatewayEnabled: true
  # http 요청시 https로 redirect 시킴
  httpsRedirect: true
  loaclityLBEnabled: false
  protocol: HTTP
  trafficPolicy: {}
  targetHost:
  # `Values.global.ingress.targetHostWeight`을 통해 가중치는 이미 100으로 설정되어 있음
  # 기본 EB에서 마이그레이션을 할경우 트래픽을 일부씩 옮기기 위해서는 해당 `targetHostWeight` 0 ~ 100까지 수정하여 단계별로 트래픽을 증가시킬 수 있음
  targetHostWeight:
  identifier:
  host: []
  # - test-app.beta.iexample-org.com

rollout:
  enabled: false
  blue_green:
    enabled: false
    options: {}
    #  https://argoproj.github.io/argo-rollouts/features/bluegreen/
    #  autoPromotionEnabled: false
  canary:
    enabled: false
    options: {}
    #  https://argoproj.github.io/argo-rollouts/features/canary/

service:
  type: ClusterIP
  port: 80
  portName: ""
  annotations: {}
  # - service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"

secrets:
  enabled: false
  annotations: {}
  #  kubernetes.io/service-account.name: "test-sa"
  data: []
  #  - env: dev
  #    name: db_password
  #  - env: common
  #    name: slack_token

configmap:
  enabled: false
  data: {}
  #  app.name: "test-app"
  #  app.url: "https://test-app.beta.iexample-org.com"
  #  app.propertiers: |
  # env=prod
  # check=/health-check

hpa:
  # default - false (global.hpa.enabled)
  enabled:
  # default - 2 (global.hpa.minReplicas)
  minReplicas:
  # default - 10 (global.hpa.maxReplicas)
  maxReplicas:
  # default - 60 (global.hpa.targetCPUUtilizationPercentage)
  targetCPUUtilizationPercentage:
  targetMemoryUtilizationPercentage:

sa:
  enabled: false
  annotations: {}
  #  eks.amazonaws.com/role-arn: arn:aws:iam::517727162249:role/test-app-eks-iam-role

securityGroups:
  enabled: false
  groupIds: []
  # - sg-0101010101010101

pdb:
  # @default -- `""` (default: 1)
  maxUnavailable: 1

datadog:
  enabled:
  profiling:

global:
  deployment:
    labels: {}
    annotations: {}

  ingress:
    targetHost:
    targetHostWeight: 100
    identifier:

  sa:
    enabled: false
    annotations: {}
    #  eks.amazonaws.com/role-arn: arn:aws:iam::517727162249:role/test-app-eks-iam-role

  securityGroups:
    groupIds: []
    # - sg-0101010101010101

  hpa:
    enabled: false
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 60

  datadog:
    enabled: true
    profiling: false
```
