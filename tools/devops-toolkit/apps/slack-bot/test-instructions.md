# GitHub Workflow 트리거 테스트 가이드

## 🔧 사전 준비

### 1. GitHub Personal Access Token 생성
- GitHub → Settings → Developer settings → Personal access tokens
- "Generate new token" (classic) 선택
- 필요한 권한:
  - `repo` (Full control of private repositories)
  - `workflow` (Update GitHub Action workflows)

### 2. 환경 변수 설정

#### 옵션 A: Signing Secret 사용 (권장)
```bash
export GITHUB_TOKEN="ghp_your_actual_token_here"
export SLACK_BOT_TOKEN="xoxb-your-bot-token"
export SLACK_SIGNING_SECRET="your-signing-secret"
```

#### 옵션 B: Verification Token 사용 (레거시)
```bash
export GITHUB_TOKEN="ghp_your_actual_token_here" 
export SLACK_BOT_TOKEN="xoxb-your-bot-token"
export SLACK_VERIFICATION_TOKEN="your-verification-token"
```

#### 옵션 C: 모든 Slack App 정보 사용
```bash
export GITHUB_TOKEN="ghp_your_actual_token_here"
export SLACK_BOT_TOKEN="xoxb-your-bot-token"
export SLACK_CLIENT_ID="your-client-id"
export SLACK_CLIENT_SECRET="your-client-secret"
export SLACK_SIGNING_SECRET="your-signing-secret"
export SLACK_VERIFICATION_TOKEN="your-verification-token"
```

#### 옵션 D: 개발 모드 (검증 우회)
```bash
export GITHUB_TOKEN="ghp_your_actual_token_here"
export SLACK_BOT_TOKEN="xoxb-test-token"
export SLACK_SIGNING_SECRET="test-secret"
export SKIP_SLACK_VERIFICATION="true"
```

## 🚀 테스트 실행

### 터미널 1: 서버 실행
```bash
cd apps/slack-bot
make clean-run
```

### 터미널 2: 워크플로우 트리거
```bash
# 기본 테스트 (CI process(TFC) 워크플로우)
curl -X POST http://localhost:8080/slack/commands \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "command=/devops-action&text=wetripod/demo-infrastructure ci-infra-terraform-cloud.yml workspace_name test-workspace-$(date +%s) working_directory terraform/infra/aws project_name Alwayz&user_id=U123456789&channel_id=C123456789&timestamp=$(date +%s)"

# 또는 URL 인코딩된 형태
curl -X POST "http://localhost:8080/slack/commands" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "command=/devops-action" \
  -d "text=wetripod/demo-infrastructure ci-infra-terraform-cloud.yml workspace_name test-workspace working_directory terraform/infra/aws project_name Alwayz" \
  -d "user_id=U123456789" \
  -d "channel_id=C123456789"
```

## 🎯 테스트 시나리오

### 1. 성공적인 워크플로우 트리거
**명령어:**
```bash
/devops-action wetripod/demo-infrastructure ci-infra-terraform-cloud.yml workspace_name my-test-workspace working_directory terraform/infra/aws project_name Alwayz
```

**예상 결과:**
- HTTP 200 응답
- GitHub Actions 탭에서 워크플로우 실행 확인
- Terraform Cloud에서 워크스페이스 생성 시도

### 2. 잘못된 파라미터 테스트
**명령어:**
```bash
/devops-action wetripod/demo-infrastructure ci-infra-terraform-cloud.yml
```

**예상 결과:**
- 파라미터 부족 에러 메시지

### 3. 존재하지 않는 워크플로우 테스트
**명령어:**
```bash
/devops-action wetripod/demo-infrastructure non-existent-workflow.yml workspace_name test
```

**예상 결과:**
- 워크플로우를 찾을 수 없다는 에러 메시지

## 🔍 확인 방법

### 1. 로컬 로그 확인
서버 실행 터미널에서 다음과 같은 로그 확인:
```
2025/07/16 21:47:28 Received slash command: /devops-action
2025/07/16 21:47:28 Triggering workflow: ci-infra-terraform-cloud.yml for repo: wetripod/demo-infrastructure
2025/07/16 21:47:28 Workflow triggered successfully
```

### 2. GitHub Actions 확인
브라우저에서 다음 URL 접속:
```
https://github.com/wetripod/demo-infrastructure/actions/workflows/ci-infra-terraform-cloud.yml
```

### 3. API 응답 확인
curl 명령의 응답으로 다음과 같은 JSON 확인:
```json
{
  "response_type": "in_channel",
  "text": "✅ Successfully triggered workflow 'ci-infra-terraform-cloud.yml' for repository 'wetripod/demo-infrastructure'"
}
```

## 🐛 문제 해결

### 1. 인증 에러
```
Error: 401 Unauthorized
```
**해결:** GitHub 토큰 권한 확인 및 재생성

### 2. 포트 사용 중 에러
```
Error: listen tcp :8080: bind: address already in use
```
**해결:** `make kill-port` 실행

### 3. 워크플로우 찾을 수 없음
```
Error: 404 Not Found
```
**해결:** 리포지토리 이름과 워크플로우 파일명 확인

## 🎛️ 추가 워크플로우 테스트

### Datadog CI 워크플로우
```bash
/devops-action wetripod/demo-infrastructure ci-datadog.yml
```

### AWS 인프라 CI 워크플로우
```bash
/devops-action wetripod/demo-infrastructure demo-aws-prod-infra-ci.yml
```

## 🎉 성공 확인

1. ✅ 서버가 정상 실행됨
2. ✅ Slack 명령어 처리됨  
3. ✅ GitHub API 호출 성공
4. ✅ 워크플로우가 GitHub Actions에서 실행됨
5. ✅ Terraform Cloud에서 결과 확인 (해당하는 경우)

모든 단계가 성공하면 slack-bot이 완벽하게 작동하는 것입니다! 🚀 

## 🎯 요약

완벽한 로컬 테스트 환경이 준비되었습니다! 

### **✅ 준비 완료된 항목들:**

1. **Slack GitHub Bot** - `/devops-action` 명령어로 GitHub 워크플로우 트리거
2. **대상 워크플로우** - `wetripod/demo-infrastructure`의 "CI process(TFC)" 워크플로우
3. **Graceful Shutdown** - Ctrl+C로 포트 깔끔하게 해제
4. **포트 관리** - `make kill-port`, `make clean-run` 명령어
5. **완전한 테스트 가이드** - `test-instructions.md` 파일

### **🚀 실제 테스트 진행 방법:**

1. **GitHub 토큰 생성** (repo, workflow 권한)
2. **환경 변수 설정**:
   ```bash
   export GITHUB_TOKEN="ghp_your_actual_token"
   export SLACK_BOT_TOKEN="xoxb-test"
   export SLACK_SIGNING_SECRET="test-secret"
   ```

3. **서버 실행** (터미널 1):
   ```bash
   make clean-run
   ```

4. **워크플로우 트리거** (터미널 2):
   ```bash
   curl -X POST "http://localhost:8080/slack/commands" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "command=/devops-action" \
     -d "text=wetripod/demo-infrastructure ci-infra-terraform-cloud.yml workspace_name test-workspace working_directory terraform/infra/aws project_name Alwayz" \
     -d "user_id=U123456789" \
     -d "channel_id=C123456789"
   ```

5. **결과 확인**:
   - 로컬 서버 로그
   - GitHub Actions 탭: https://github.com/wetripod/demo-infrastructure/actions
   - Terraform Cloud 워크스페이스 생성 여부

### **🎛️ 테스트 가능한 다른 워크플로우들:**
- `ci-datadog.yml` - Datadog 모니터링 설정
- `demo-aws-prod-infra-ci.yml` - AWS 프로덕션 인프라
- `aws-data-dev-infra-ci.yml` - 데이터 개발 인프라

실제 GitHub 토큰을 설정하고 위의 명령어를 실행하면 `wetripod/demo-infrastructure` 리포지토리의 "CI process(TFC)" 워크플로우가 트리거되어 Terraform Cloud 워크스페이스가 생성됩니다! 🎉 
