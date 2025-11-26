# base-cronjobs

레브잇에서 제공하는 cronjobs 차트 입니다. </br>
cronjob을 이용해 batch 작업을 스케줄링 하기 위해 사용합니다.

## Use the Chart

```bash
# Add Chart Repo
helm repo add example-org https://
helm repo update

# Install the Chart with default values
helm install my-release example-org/base-cronjobs
```


## Values
```yaml
# Default values for base-cronjobs.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.
appName: 

rbac:
  rules: []
  # - apiGroups: ["argoproj.io"]
  #   resources: ["applications"]
  #   verbs: ["get","list","watch"]
  # - apiGroups: [""]
  #   resources: ["configmaps"]
  #   verbs: ["get","list","watch"]
  # clusterRole: view
   
  
secrets:
  vaultPath: 'k8s_kv/se'
  useEnv: true
  data: []
    # - secretKey: test
    #   vaultKey: boo
    
nodeSelector: {}
  # service: infra

tolerations: []
  # - effect: NoSchedule
  #   key: CriticalAddonsOnly
  #   operator: Equal
  #   value: 'true'

configMap:
  json: {}
    # protectedEnvs:
    #   {
    #     dev: "",
    #     qa: "",
    #     stage: ""
    #   }
  string: {}
    # PROFILE: dev

cronJobDefault:
  # cron config
  failedJobsHistoryLimit: 1
  successfulJobsHistoryLimit: 1

  # common config
  labels: {}
  annotations: {}
  sa:
    labels: {}
    annotations: {}
  image:
    repository: nginx
    pullPolicy: IfNotPresent
  resources:
    limits:
      cpu: 100m
      memory: 128Mi
    requests:
      cpu: 100m
      memory: 128Mi
  tolerations: []
  nodeSelector: {}
  volumeMounts: {}
  volumes: {}
  env: []
    # - name: foo
    #   value: bar
  extraEnvFrom: []
    # - configMapRef:
    #     name: env-configmap
    # - secretRef:
    #     name: env-secrets
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 3000

cronJobs: []
  # - name: app-syncer
  #   image: 
  #     tag: latest
  #   cronTimeExpression: "* * * * *"  
  #   rbacRule: 
  # - name: dev-app-turn-off
  #   image: 
  #     name: app-switcher
  #     tag: latest
  #   cronTimeExpression: "59 14 * * *" 
  # - name: qa-app-turn-off
  #   image: 
  #     name: app-switcher
  #     tag: latest
  #   cronTimeExpression: "59 14 * * *"  
  # - name: stage-app-turn-off
  #   image: 
  #     name: app-switcher
  #     tag: latest
  #   cronTimeExpression: "59 14 * * *"  
  # - name: dev-app-turn-on
  #   image: 
  #     name: app-switcher
  #     tag: latest
  #   cronTimeExpression: "30 22 * * 0-4"  
  # - name: qa-app-turn-on
  #   image: 
  #     name: app-switcher
  #     tag: latest
  #   cronTimeExpression: "30 22 * * 0-4"  
  # - name: stage-app-turn-on
  #   image: 
  #     name: app-switcher
  #     tag: latest
  #   cronTimeExpression: "30 22 * * 0-4"  
```
