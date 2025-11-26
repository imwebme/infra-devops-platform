# Slack GitHub Bot

A Go-based Slack bot that triggers GitHub Actions through Slack commands and mentions.

## 🚀 Features

- **Slash Commands**: Trigger GitHub Actions directly from Slack
- **Bot Mentions**: Natural language commands for common operations
- **GitHub Integration**: Direct integration with GitHub Actions API
- **Health Monitoring**: Built-in health check endpoint
- **Secure**: Request verification and token-based authentication
- **Containerized**: Docker support with multi-stage builds

## 📁 Project Structure

```
slack-bot/
├── main.go              # Main application entry point with HTTP handlers
├── github.go            # GitHub API client implementation
├── main_test.go         # Unit tests for main application logic
├── github_test.go       # Unit tests for GitHub client
├── go.mod              # Go module dependencies
├── go.sum              # Go module checksums (auto-generated)
├── Dockerfile          # Multi-stage Docker build configuration
├── docker-compose.yml   # Docker Compose for local development
├── Makefile            # Build automation and development tasks
├── .gitignore          # Git ignore patterns
├── .dockerignore       # Docker build ignore patterns
└── README.md           # This documentation file
```

### 📄 File Descriptions

#### Core Application Files

- **`main.go`**: 메인 애플리케이션 파일로 HTTP 서버, 라우팅, Slack 이벤트 핸들링을 담당합니다. 슬래시 커맨드와 봇 멘션을 처리하는 핵심 로직이 포함되어 있습니다.

- **`github.go`**: GitHub API와의 통신을 담당하는 클라이언트 구현체입니다. 워크플로우 트리거, 워크플로우 목록 조회 등의 기능을 제공합니다.

#### Test Files

- **`main_test.go`**: 메인 애플리케이션의 단위 테스트입니다. HTTP 핸들러, 명령어 처리, 구성 검증 등을 테스트합니다.

- **`github_test.go`**: GitHub 클라이언트의 단위 테스트입니다. API 호출, 에러 처리, 응답 파싱 등을 테스트합니다.

#### Configuration Files

- **`go.mod`**: Go 모듈 정의 파일로 프로젝트 의존성을 관리합니다.

- **`go.sum`**: Go 모듈의 체크섬 파일로 의존성의 무결성을 보장합니다.

#### Container & Deployment

- **`Dockerfile`**: 멀티 스테이지 빌드를 사용한 최적화된 컨테이너 이미지 생성 파일입니다.

- **`docker-compose.yml`**: 로컬 개발 환경을 위한 Docker Compose 설정 파일입니다.

#### Development Tools

- **`Makefile`**: 빌드, 테스트, 린팅, 도커 관리 등의 개발 작업을 자동화하는 파일입니다.

- **`.gitignore`**: Git 버전 관리에서 제외할 파일 패턴을 정의합니다.

- **`.dockerignore`**: Docker 빌드 시 제외할 파일 패턴을 정의합니다.

## 📋 Prerequisites

- Go 1.21 or higher
- Docker (for containerization)
- Slack App with Bot Token
- GitHub Personal Access Token
- AWS CLI (for ECR deployment)

## 🛠️ Environment Setup

### Required Environment Variables

```bash
export SLACK_BOT_TOKEN="xoxb-your-bot-token"
export SLACK_SIGNING_SECRET="your-signing-secret"
export GITHUB_TOKEN="ghp_your-github-token"
export GITHUB_ORG="wetripod"  # Optional, defaults to "wetripod"
export PORT="8080"            # Optional, defaults to "8080"
```

### Slack App Configuration

1. Create a new Slack App at https://api.slack.com/apps
2. Enable the following OAuth Scopes:
   - `app_mentions:read`
   - `chat:write`
   - `commands`
3. Subscribe to the following events:
   - `app_mention`
4. Create a slash command:
   - Command: `/devops-action`
   - Request URL: `https://your-domain.com/slack/commands`
5. Set the Event Subscriptions URL: `https://your-domain.com/slack/events`

### GitHub Token Permissions

The GitHub token needs the following permissions:
- `actions:write` (to trigger workflows)
- `contents:read` (to read repository information)

## 🏗️ Development Guide

### Local Development

1. **Clone and navigate to the project:**
   ```bash
   cd devops-monorepo/apps/slack-bot
   ```

2. **Install dependencies:**
   ```bash
   make deps
   ```

3. **Set environment variables:**
   ```bash
   # Create .env file with your values
   export SLACK_BOT_TOKEN="your-token"
   export SLACK_SIGNING_SECRET="your-secret"
   export GITHUB_TOKEN="your-github-token"
   ```

4. **Run the application:**
   ```bash
   make run
   ```

5. **Test the health endpoint:**
   ```bash
   curl http://localhost:8080/health
   ```

### Development Commands

```bash
# Install dependencies
make deps

# Format code
make fmt

# Run linting
make lint

# Run tests
make test

# Run tests with coverage
make test-coverage

# Build application
make build

# Run application
make run

# Build Docker image
make docker-build

# Run with Docker
make docker-run

# Clean build artifacts
make clean
```

### Testing

Run unit tests:
```bash
make test
```

Run tests with coverage:
```bash
make test-coverage
```

Run static analysis:
```bash
make lint
```

### Building

Build for current platform:
```bash
make build
```

Build for Linux (for Docker):
```bash
make build-linux
```

## 🐳 Docker

### Building the Docker Image

```bash
make docker-build
```

### Running with Docker

```bash
make docker-run
```

### Docker Compose

```bash
# Start services
make compose-up

# Stop services
make compose-down

# View logs
make compose-logs
```

## 🚀 Deployment

### ECR Deployment

The project includes a GitHub Actions workflow for automatic deployment to ECR:

1. **Manual deployment:**
   ```bash
   # Build and tag
   make docker-build
   
   # Tag for ECR
   docker tag slack-bot:latest ${ECR_REGISTRY}/slack-bot:latest
   
   # Push to ECR
   docker push ${ECR_REGISTRY}/slack-bot:latest
   ```

2. **Automated deployment:**
   - Push to `main` branch triggers automatic deployment
   - Use workflow dispatch for manual deployments

## 💬 Usage

### Slash Commands

```
/devops-action <repository> <workflow> [key value pairs...]
```

Examples:
```
/devops-action user-service deploy.yml environment staging
/devops-action payment-api build.yml
/devops-action notification-service test.yml
```

### Bot Mentions

Mention the bot in any channel:

```
@slack-bot deploy staging user-service
@slack-bot build payment-service
@slack-bot test notification-service
@slack-bot help
```

### Available Commands

- `deploy <environment> <service>` - Deploy a service to an environment
- `build <service>` - Build a service
- `test <service>` - Run tests for a service
- `help` - Show help message

## 🔧 Configuration

### GitHub Workflows

Your GitHub repositories should have the following workflow files:

- `.github/workflows/deploy.yml` - For deployments
- `.github/workflows/build.yml` - For builds
- `.github/workflows/test.yml` - For testing

Example workflow with `workflow_dispatch`:

```yaml
name: Deploy

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        default: 'dev'
      service:
        description: 'Service to deploy'
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy
        run: |
          echo "Deploying ${{ github.event.inputs.service }} to ${{ github.event.inputs.environment }}"
```

## 🧪 Testing Strategy

### Unit Tests

- **Function-level testing**: 각 함수의 입력/출력과 에러 케이스를 테스트
- **HTTP handler testing**: HTTP 요청/응답 처리 로직 테스트
- **Mock services**: 외부 API 호출을 모킹하여 테스트

### Integration Tests

- **End-to-end workflow**: 실제 Slack 이벤트부터 GitHub API 호출까지의 전체 플로우 테스트
- **Error handling**: 다양한 에러 시나리오 테스트

### Test Coverage

목표 커버리지: 80% 이상

```bash
# Run tests with coverage
make test-coverage

# View coverage report
open coverage.html
```

## 🐛 Troubleshooting

### Common Issues

1. **Bot not responding to mentions:**
   - Check if the bot is added to the channel
   - Verify the `app_mentions:read` scope is enabled
   - Check server logs for errors

2. **Slash command not working:**
   - Verify the request URL in Slack app settings
   - Check if the signing secret is correct
   - Ensure the `/slack/commands` endpoint is accessible

3. **GitHub Action not triggering:**
   - Verify GitHub token permissions
   - Check if the workflow file exists
   - Ensure the repository and workflow names are correct

### Logs

Check application logs:
```bash
# Docker logs
make docker-logs

# Kubernetes logs
kubectl logs deployment/slack-bot
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run `make check` to ensure code quality
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support, contact the DevOps team or create an issue in the repository. 

## ✅ 완료된 작업들

### 1. 📁 **계층구조 조정 (한 depth 더 들어간 구조)**
- 기존: `devops-monorepo/apps/slack-bot/`
- 변경: `devops-monorepo/apps/slack-bot/`
- 여러 개발자가 여러 도메인의 서비스를 개발할 수 있도록 구조 개선

### 2. 📄 **README에 각 파일 설명 추가**
새로운 README에 포함된 내용:
- **프로젝트 구조**: 전체 디렉토리 구조 도식화
- **파일별 상세 설명**: 각 파일의 역할과 목적을 한국어로 상세 설명
  - `main.go`: HTTP 서버, 라우팅, Slack 이벤트 핸들링
  - `github.go`: GitHub API 클라이언트 구현
  - `main_test.go`, `github_test.go`: 단위 테스트 파일들
  - `Dockerfile`, `docker-compose.yml`: 컨테이너 설정
  - `Makefile`: 빌드 자동화
  - 설정 파일들: `.gitignore`, `.dockerignore`, `go.mod`
- **개발 가이드**: 환경 설정, 빌드, 테스트, 배포 방법
- **테스트 전략**: 단위 테스트, 통합 테스트, 커버리지 목표

### 3. 🎯 **.cursor 규칙 추가**
`devops-monorepo/.cursor/rules/devops-guidelines.md`에 포함된 규칙들:
- **Go 개발 가이드라인**: 코딩 스타일, 에러 핸들링, 테스팅
- **TypeScript/Node.js 가이드라인**: 새로운 프로젝트용
- **Docker 가이드라인**: 멀티스테이지 빌드, 보안, 최적화
- **문서화 표준**: README 작성법, 코드 주석
- **Git 워크플로우**: 브랜치 명명, 커밋 메시지, PR 가이드라인
- **보안 가이드라인**: 시크릿 관리, 의존성 관리
- **CI/CD 가이드라인**: GitHub Actions, 배포 절차
- **성능 가이드라인**: Go 및 Node.js 최적화
- **모니터링 및 로깅**: 구조화된 로깅, 메트릭스
- **파일 조직**: 명명 규칙, 디렉토리 구조
- **코드 리뷰 가이드라인**: 리뷰어와 작성자 체크리스트

### 4. 🧪 **포괄적인 테스트 코드 작성**

#### `main_test.go`:
- **헬스 체크 테스트**: HTTP 엔드포인트 테스트
- **환경변수 테스트**: getEnv 함수 테스트
- **명령어 처리 테스트**: 다양한 슬랙 명령어 시나리오
- **슬래시 커맨드 테스트**: 잘못된 입력 처리
- **라우터 설정 테스트**: HTTP 라우팅 및 메서드 테스트
- **구성 검증 테스트**: 필수 환경변수 검증

#### `github_test.go`:
- **GitHub 클라이언트 생성 테스트**: 클라이언트 초기화
- **워크플로우 트리거 성공/실패 테스트**: Mock 서버 사용
- **워크플로우 목록 조회 테스트**: API 응답 파싱
- **에러 처리 테스트**: 다양한 HTTP 에러 시나리오
- **헤더 검증 테스트**: 인증 헤더 등 확인

### 5. 🗂️ **완성된 파일 구조**
```
devops-monorepo/
├── apps/
│   └── slack-app/
│       └── slack-bot/
│           ├── main.go              # 메인 애플리케이션
│           ├── github.go            # GitHub API 클라이언트
│           ├── main_test.go         # 메인 로직 테스트
│           ├── github_test.go       # GitHub 클라이언트 테스트
│           ├── go.mod              # Go 모듈 정의
│           ├── Dockerfile          # 컨테이너 설정
│           ├── docker-compose.yml   # 로컬 개발용
│           ├── Makefile           # 빌드 자동화
│           ├── .gitignore         # Git 제외 파일
│           ├── .dockerignore      # Docker 제외 파일
│           └── README.md          # 상세 문서
├── .cursor/
│   └── rules/
│       └── devops-guidelines.md    # 종합 개발 가이드라인
├── .github/
│   ├── workflows/
│   │   └── slack-bot.yml   # CI/CD 파이프라인 (경로 업데이트됨)
│   └── pull_request_template.md   # PR 템플릿 (JIRA 링크 포함)
```

### 6. 🎯 **주요 개선사항**
- **모노레포 확장성**: 도메인별 앱 그룹핑으로 여러 팀 개발 지원
- **테스트 커버리지**: 80% 이상 목표로 포괄적인 테스트 작성
- **개발자 경험**: Makefile로 일관된 개발 워크플로우 제공
- **문서화**: 한국어로 상세한 파일 설명 및 개발 가이드
- **코딩 표준**: .cursor 규칙으로 일관된 코드 품질 보장
- **CI/CD**: GitHub Actions로 자동화된 빌드/테스트/배포

이제 여러 개발자가 각자의 도메인(slack-app, data-app, monitoring-app 등)에서 효율적으로 개발할 수 있는 견고한 모노레포 구조가 완성되었습니다! 🚀 

## 🎯 추천 도메인들

### **1차 추천 (DevOps 중심)**
```bash
devops-bot.example.com           # 가장 직관적
devops.example.com              # 간결함
automation.example.com          # 자동화 강조
ci-cd.example.com              # CI/CD 전용
workflow.example.com           # 워크플로우 관리
```

### **2차 추천 (운영 중심)**
```bash
ops.example.com                # 매우 간결
infra.example.com             # 인프라 관리
deploy.example.com            # 배포 전용
tools.example.com             # 개발 도구
platform.example.com         # 플랫폼 서비스
```

### **3차 추천 (내부 도구)**
```bash
internal.example.com          # 내부 도구 전용
admin.example.com             # 관리자 도구
hub.example.com               # 통합 허브
console.example.com           # 콘솔 인터페이스
control.example.com           # 제어 센터
```

## 🔥 **최종 추천: `devops.example.com`**

### **선택 이유:**
1. **간결성**: 기억하기 쉽고 입력하기 편함
2. **확장성**: DevOps 관련 모든 서비스를 포괄 가능
3. **전문성**: DevOps 팀의 전문성을 보여줌
4. **범용성**: Slack 봇뿐만 아니라 다른 DevOps 도구도 호스팅 가능

## 📁 도메인 구조 제안

### **서브패스 활용**
```bash
# 메인 DevOps 허브
https://devops.example.com

# 서비스별 엔드포인트
https://devops.example.com/slack/commands     # Slack 봇
https://devops.example.com/api/webhooks       # GitHub Webhooks
https://devops.example.com/health             # 헬스체크
https://devops.example.com/metrics            # 모니터링
https://devops.example.com/dashboard          # 웹 대시보드 (향후)
```

### **서브도메인 활용 (확장 시)**
```bash
slack.devops.example.com      # Slack 봇 전용
api.devops.example.com        # API 서버
monitoring.devops.example.com # 모니터링 도구
```

## 🛠️ 실제 구현에서 사용할 URL

### **Slack App Request URL**
```bash
https://devops.example.com/slack/commands
```

### **코드에서의 설정**
```go
<code_block_to_apply_changes_from>
```

## 🎨 추가 도메인 아이디어

만약 다른 스타일을 선호한다면:

### **Creative & Modern**
```bash
devbot.example.com           # 봇 특화
automate.example.com         # 자동화 강조
pipeline.iexample-org.com         # 파이프라인 강조
```

### **Enterprise Style**
```bash
enterprise-devops.example.com
dev-platform.example.com
engineering-tools.example.com
```

## 📋 도메인 설정 체크리스트

1. **DNS 설정**: A 레코드 또는 CNAME으로 ALB 연결
2. **SSL 인증서**: AWS ACM으로 HTTPS 설정
3. **보안 그룹**: 80/443 포트 오픈
4. **Slack App 업데이트**: Request URL 변경

**최종 추천**: `devops.example.com` - 간결하고 전문적이며 확장 가능한 최고의 선택입니다! 🚀

어떤 도메인이 가장 마음에 드시나요?

// main.go에서 헬스체크 확인
https://devops.example.com/health

// GitHub Webhook (향후 확장)
https://devops.example.com/api/webhooks/github 
