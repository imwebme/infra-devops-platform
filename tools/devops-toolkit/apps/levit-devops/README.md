# example-org-devops

DevOps 팀을 위한 통합 CLI 도구

## 주요 기능

### 1. Kubernetes 관리
```bash
# 컨텍스트 관리
example-org-devops k8s context                    # kubectl config get-contexts
example-org-devops k8s context demo-dev-eks     # kubectl config use-context demo-dev-eks
example-org-devops k8s view demo-dev-eks        # k9s --context demo-dev-eks

# 클러스터 정보
example-org-devops k8s nodes                      # kubectl get nodes
example-org-devops k8s pods <namespace>           # kubectl get pods -n <namespace>
example-org-devops k8s logs <pod> <namespace>     # kubectl logs <pod> -n <namespace>
```

### 2. AWS 관리
```bash
# 프로파일 관리
example-org-devops aws profile                    # aws configure list-profiles
example-org-devops aws profile demo-prod       # aws configure set profile demo-prod

# 리소스 조회
example-org-devops aws ec2                        # aws ec2 describe-instances (formatted)
example-org-devops aws rds                        # aws rds describe-db-instances (formatted)
example-org-devops aws s3                         # aws s3 ls
```

### 3. GitOps 관리
```bash
# ArgoCD 관리
example-org-devops argocd apps                    # argocd app list
example-org-devops argocd sync <app>              # argocd app sync <app>
example-org-devops argocd status <app>            # argocd app get <app>

# Gonzo 로그 분석
example-org-devops gonzo version                  # Gonzo 버전 정보
example-org-devops gonzo logs -f /var/log/app.log # 로그 파일 분석
example-org-devops gonzo follow /var/log/app.log  # 로그 실시간 추적
kubectl logs -f deployment/app | example-org-devops gonzo  # kubectl 로그 분석

# Helm 관리
example-org-devops helm list                      # helm list --all-namespaces
example-org-devops helm template <chart>          # helm template validation
```

### 4. 모니터링 & 로깅
```bash
# 로그 조회
example-org-devops logs app <app-name>            # 애플리케이션 로그 조회
example-org-devops logs infra <component>         # 인프라 컴포넌트 로그

# 메트릭 조회
example-org-devops metrics cpu                    # CPU 사용률 조회
example-org-devops metrics memory                 # 메모리 사용률 조회
```

### 5. 도구 관리
```bash
# 도구 설치 (체크섬 검증 포함)
example-org-devops install self                   # example-org-devops 자체 설치
example-org-devops install tools                  # 모든 필수 도구 안전 설치
example-org-devops install tools kubectl         # 특정 도구 안전 설치

# 도구 검증
example-org-devops validate tools                 # 설치된 도구 검증
example-org-devops validate config                # 설정 파일 검증

# 버전 관리
example-org-devops update check                   # 버전 확인
example-org-devops update tools                   # 모든 도구 업데이트
example-org-devops update tools kubectl          # 특정 도구 업데이트
```

### 6. 클러스터 분석
```bash
# 전체 클러스터 상태 분석
example-org-devops analyze popeye                 # Popeye로 전체 분석
example-org-devops analyze popeye monitoring      # 특정 네임스페이스 분석

# 리소스 사용량 분석
example-org-devops analyze krr                    # KRR로 리소스 분석
example-org-devops analyze resources              # 리소스 사용량 테이블

# 보안 분석
example-org-devops analyze security               # 종합 보안 체크
example-org-devops security rbac                  # RBAC 설정 분석
example-org-devops security secrets               # 시크릿 관리 분석
example-org-devops security network               # 네트워크 정책 분석
```

### 7. 개발 도구
```bash
# 터널링
example-org-devops tunnel db <db-name>            # 데이터베이스 터널링
example-org-devops tunnel service <service>       # 서비스 포트 포워딩

# 디버깅
example-org-devops debug pod <pod-name>           # kubectl exec -it <pod> -- /bin/bash
example-org-devops debug network <service>        # 네트워크 연결 테스트
```

## 설치

## 자동 설치
```bash
cd apps/example-org-devops
make build
./install.sh
```

## 수동 설치
```bash
cd apps/example-org-devops
make build
make install  # sudo 권한 필요
```

## 개발용 설치
```bash
cd apps/example-org-devops
make build
# 별칭 설정
alias example-org-devops='$(pwd)/bin/example-org-devops'
```

## 설정

```yaml
# ~/.example-org-devops/config.yaml
clusters:
  - name: demo-dev-eks
    context: demo-dev-eks
    environment: dev
  - name: demo-prod-eks
    context: demo-prod-eks
    environment: prod
  - name: data-dev-eks
    context: data-dev-eks
    environment: dev
  - name: data-prod-eks
    context: data-prod-eks
    environment: prod

aws_profiles:
  - name: demo-dev
    profile: demo-dev
  - name: demo-prod
    profile: demo-prod

tools:
  k9s: /usr/local/bin/k9s
  kubectl: /usr/local/bin/kubectl
  aws: /usr/local/bin/aws
  argocd: /usr/local/bin/argocd
  helm: /usr/local/bin/helm
  gonzo: /usr/local/bin/gonzo
```