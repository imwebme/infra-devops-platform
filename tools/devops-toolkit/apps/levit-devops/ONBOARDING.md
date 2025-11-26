# 🚀 DevOps 팀 신입사원 온보딩 가이드

새로운 맥북에서 DevOps 환경을 구축하는 완전한 가이드입니다.

## 📋 체크리스트

- [ ] Homebrew 설치
- [ ] Git 설정
- [ ] example-org-devops CLI 설치
- [ ] 필수 도구 설치
- [ ] AWS 설정
- [ ] Kubernetes 설정
- [ ] ArgoCD 로그인
- [ ] 테스트 실행

## 1️⃣ 기본 환경 설정

### Homebrew 설치
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Git 설정
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@demo.com"
```

### 저장소 클론
```bash
# 작업 디렉터리 생성
mkdir -p ~/workspace/demo/devops
cd ~/workspace/demo/devops

# DevOps 저장소들 클론
git clone https://github.com/demo/devops-monorepo.git
git clone https://github.com/demo/devops-gitops-manifest.git
git clone https://github.com/demo/demo-infrastructure.git
```

## 2️⃣ example-org-devops CLI 설치

### 자동 설치 (권장)
```bash
cd ~/workspace/demo/devops/devops-monorepo/apps/example-org-devops
make build
./install.sh
```

### 새 터미널 열기 또는 PATH 적용
```bash
source ~/.zshrc
# 또는 새 터미널 창 열기
```

### 설치 확인
```bash
example-org-devops --help
# Levit 배너와 함께 도움말이 표시되어야 함
```

## 3️⃣ 필수 도구 설치

### 모든 도구 자동 설치
```bash
example-org-devops install tools
```

### 개별 도구 설치 (필요시)
```bash
example-org-devops install tools kubectl
example-org-devops install tools k9s
example-org-devops install tools helm
example-org-devops install tools argocd
example-org-devops install tools aws
```

### 설치 확인
```bash
example-org-devops update check
```

## 4️⃣ AWS 설정

### AWS CLI 설정
```bash
aws configure
# Access Key ID: [팀장에게 문의]
# Secret Access Key: [팀장에게 문의]
# Default region: ap-northeast-2
# Default output format: json
```

### 프로파일 설정 (멀티 계정)
```bash
# 개발 환경
aws configure --profile demo-dev

# 프로덕션 환경
aws configure --profile demo-prod
```

### AWS 연결 테스트
```bash
example-org-devops aws profile
example-org-devops aws ec2
```

## 5️⃣ Kubernetes 설정

### EKS 클러스터 연결
```bash
# 개발 클러스터
aws eks update-kubeconfig --region ap-northeast-2 --name demo-dev-eks --profile demo-dev

# 프로덕션 클러스터 (권한 확인 후)
aws eks update-kubeconfig --region ap-northeast-2 --name demo-prod-eks --profile demo-prod

# 데이터 클러스터
aws eks update-kubeconfig --region ap-northeast-2 --name data-dev-eks --profile demo-dev
```

### 클러스터 연결 확인
```bash
example-org-devops k8s context
example-org-devops k8s nodes
```

### k9s로 클러스터 탐색
```bash
example-org-devops k8s view demo-dev-eks
```

## 6️⃣ ArgoCD 설정

### ArgoCD 로그인
```bash
# 기본 서버로 로그인
example-org-devops argocd login

# 또는 특정 서버
example-org-devops argocd login argocd.demo.io
```

### ArgoCD 앱 확인
```bash
example-org-devops list all
# ArgoCD 애플리케이션 목록이 표시되어야 함
```

## 7️⃣ 최종 테스트

### 전체 상태 확인
```bash
example-org-devops list all
```

### 각 도구 테스트
```bash
# Kubernetes
example-org-devops k8s pods kube-system

# AWS
example-org-devops aws s3

# GitOps
example-org-devops gitops helm list

# 로그 분석 (Gonzo)
example-org-devops gonzo version

# 로그 조회
example-org-devops logs infra cert-manager
```

## 🔧 문제 해결

### 일반적인 문제들

#### 1. PATH 문제
```bash
# 수동으로 PATH 추가
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc
source ~/.zshrc
```

#### 2. AWS 권한 문제
```bash
# 현재 사용자 확인
aws sts get-caller-identity

# 프로파일 확인
aws configure list-profiles
```

#### 3. Kubernetes 연결 문제
```bash
# 컨텍스트 확인
kubectl config get-contexts

# 클러스터 정보 확인
kubectl cluster-info
```

#### 4. ArgoCD 로그인 문제
```bash
# 수동 로그인
argocd login argocd.demo.io --sso

# 컨텍스트 확인
argocd context
```

## 📞 도움 요청

문제가 해결되지 않으면:
1. **Slack**: #devops-team 채널에 문의
2. **팀장**: 직접 문의
3. **문서**: 이 가이드의 문제 해결 섹션 참조

## 🎯 다음 단계

온보딩 완료 후:
1. **GitOps 워크플로우** 학습
2. **Terraform** 사용법 익히기
3. **모니터링 도구** (Datadog, Grafana) 접근 권한 요청
4. **팀 프로젝트** 참여

---

**축하합니다! 🎉 DevOps 환경 구축이 완료되었습니다.**

이제 `example-org-devops` 명령어로 모든 인프라를 관리할 수 있습니다!