# DevOps 도구 가이드

## 필수 도구 설치

### 1. Kubernetes 도구

#### kubectl
```bash
# macOS
brew install kubectl

# 또는 직접 다운로드
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

#### k9s (Kubernetes CLI UI)
```bash
# macOS
brew install k9s

# 또는 직접 다운로드
curl -sS https://webinstall.dev/k9s | bash
```

#### kubectx/kubens (컨텍스트 전환)
```bash
# macOS
brew install kubectx

# 사용법
kubectx                    # 컨텍스트 목록
kubectx alwayz-dev-eks     # 컨텍스트 전환
kubens monitoring          # 네임스페이스 전환
```

### 2. AWS 도구

#### AWS CLI v2
```bash
# macOS
brew install awscli

# 또는 직접 설치
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

#### AWS Session Manager Plugin
```bash
# macOS
brew install --cask session-manager-plugin

# 사용법 (RDS 터널링)
aws ssm start-session --target i-1234567890abcdef0 \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters '{"host":["mydb.cluster-123.us-east-1.rds.amazonaws.com"],"portNumber":["3306"],"localPortNumber":["3306"]}'
```

#### eksctl (EKS 관리)
```bash
# macOS
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

# 사용법
eksctl get cluster
eksctl utils write-kubeconfig --cluster=alwayz-dev-eks
```

### 3. GitOps 도구

#### ArgoCD CLI
```bash
# macOS
brew install argocd

# 로그인
argocd login <argocd-server>
argocd app list
argocd app sync <app-name>
```

#### Helm
```bash
# macOS
brew install helm

# 사용법
helm list --all-namespaces
helm template ./charts/my-chart
helm upgrade --install my-app ./charts/my-chart
```

#### Gonzo (로그 분석 도구)
```bash
# Homebrew로 설치
brew install gonzo

# 또는 example-org-devops를 통해 자동 설치
example-org-devops install tools gonzo

# 사용법
gonzo -f /var/log/app.log     # 로그 파일 분석
gonzo -f app.log --follow     # 실시간 로그 추적
kubectl logs -f pod/app | gonzo  # kubectl 로그 분석
gonzo --otlp-enabled          # OTLP 리스너 시작
```

**보안 고려사항:**
- 민감한 로그 데이터 처리 시 주의 필요
- AI 분석 사용 시 OpenAI API 키 보안 관리
- 로컬 데이터만 처리하며 외부 전송 없음
- 로그 데이터는 메모리에만 저장되고 디스크에 저장되지 않음

### 4. 모니터링 도구

#### Prometheus CLI (promtool)
```bash
# macOS
brew install prometheus

# 사용법
promtool query instant 'up'
promtool config check prometheus.yml
```

#### Grafana CLI
```bash
# macOS
brew install grafana

# 사용법 (대시보드 관리)
grafana-cli plugins list-remote
grafana-cli plugins install grafana-piechart-panel
```

### 5. 네트워킹 도구

#### stern (멀티 파드 로그)
```bash
# macOS
brew install stern

# 사용법
stern -n monitoring prometheus
stern --selector app=nginx
```

#### httpie (HTTP 클라이언트)
```bash
# macOS
brew install httpie

# 사용법
http GET https://api.example.com/health
http POST https://api.example.com/data name=test
```

#### jq (JSON 처리)
```bash
# macOS
brew install jq

# 사용법
kubectl get pods -o json | jq '.items[].metadata.name'
aws ec2 describe-instances | jq '.Reservations[].Instances[].InstanceId'
```

### 6. 보안 도구

#### SOPS (시크릿 암호화)
```bash
# macOS
brew install sops

# 사용법
sops -e secrets.yaml > secrets.enc.yaml
sops -d secrets.enc.yaml
```

#### Trivy (보안 스캐너)
```bash
# macOS
brew install trivy

# 사용법
trivy image nginx:latest
trivy fs ./Dockerfile
```

## 권장 도구 조합

### 일상 운영
- `k9s`: 클러스터 모니터링
- `stern`: 로그 스트리밍
- `kubectx/kubens`: 빠른 컨텍스트 전환

### 디버깅
- `kubectl debug`: 파드 디버깅
- `httpie`: API 테스트
- `jq`: JSON 데이터 파싱

### 배포 관리
- `argocd`: GitOps 배포
- `helm`: 차트 관리
- `kubectl apply`: 직접 배포

### AWS 관리
- `aws cli`: 리소스 관리
- `eksctl`: EKS 클러스터 관리
- `session-manager-plugin`: 보안 접속

## 설정 파일 위치

```bash
# Kubernetes
~/.kube/config

# AWS
~/.aws/config
~/.aws/credentials

# ArgoCD
~/.argocd/config

# Helm
~/.config/helm/

# example-org-devops
~/.example-org-devops/config.yaml
```

## 유용한 별칭 (alias)

```bash
# ~/.bashrc 또는 ~/.zshrc에 추가
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kdp='kubectl describe pod'
alias kl='kubectl logs'
alias kex='kubectl exec -it'

alias h='helm'
alias hl='helm list'
alias ht='helm template'

alias a='argocd'
alias al='argocd app list'
alias as='argocd app sync'

alias g='gonzo'
alias gf='gonzo -f'
alias gfl='gonzo --follow'
alias gv='gonzo version'

# example-org-devops 별칭
alias ld='example-org-devops'
alias ldk='example-org-devops k8s'
alias lda='example-org-devops aws'
alias ldg='example-org-devops gitops'
alias ldgz='example-org-devops gonzo'
```