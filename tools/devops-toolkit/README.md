# DevOps Monorepo

A comprehensive monorepo containing DevOps tools, automation scripts, and infrastructure utilities built with Go and modern development practices.

## Overview

This repository provides:
- **Slack Integration**: GitHub Actions workflow triggering via Slack commands
- **DevOps CLI Tools**: Kubernetes, AWS, and GitOps management utilities
- **Automation Scripts**: Deployment, monitoring, and alerting automation
- **Docker Support**: Multi-stage builds with security best practices

## Applications

### 🤖 Slack GitHub Bot (`apps/slack-bot/`)

**Purpose**: Trigger GitHub Actions workflows directly from Slack channels

**Key Features:**
- `/devops-action` slash command for workflow dispatch
- Parameterized workflow execution with custom inputs
- Real-time status updates and feedback
- Secure webhook signature verification
- Production-ready Docker containerization

**Technology Stack:**
- **Language**: Go 1.21+
- **Framework**: HTTP server with Slack SDK
- **Security**: HMAC signature verification
- **Deployment**: Docker with multi-stage builds

**Quick Start:**
```bash
cd apps/slack-bot
make deps         # Install dependencies
make test-mock    # Start with mock credentials
make test-curl    # Test the bot endpoints
make docker-build # Build production image
```

**Production Configuration:**
- Domain: `devops-bot.prod.example.com`
- Environment variables: `SLACK_SIGNING_SECRET`, `GITHUB_TOKEN`
- Health check endpoint: `/health`

### 🛠️ DevOps CLI (`apps/example-org-devops/`)

**Purpose**: Unified command-line interface for DevOps operations

**Planned Features:**
- Kubernetes cluster management
- AWS resource operations
- GitOps workflow automation
- Infrastructure monitoring
- Deployment pipeline management

## Development Workflow

### Prerequisites
- Go 1.21 or later
- Docker and Docker Compose
- Make (for build automation)
- Git (for version control)

### Getting Started

```bash
# Clone the repository
git clone https://github.com/wetripod/devops-monorepo.git
cd devops-monorepo

# Install dependencies for all apps
make deps-all

# Run tests
make test-all

# Build all applications
make build-all
```

### Adding New Applications

1. Create new directory: `mkdir -p apps/{app-name}`
2. Initialize Go module: `go mod init github.com/wetripod/devops-monorepo/apps/{app-name}`
3. Add Makefile with standard targets
4. Create Dockerfile with multi-stage build
5. Add CI/CD workflow in `.github/workflows/`

### Code Quality Standards

- **Formatting**: `go fmt` and `gofmt` compliance
- **Linting**: `golangci-lint` with strict rules
- **Testing**: Minimum 80% code coverage
- **Security**: `gosec` security scanning
- **Documentation**: Comprehensive README and godoc comments

## Repository Structure

```
devops-monorepo/
├── apps/                         # Application directories
│   ├── slack-bot/                # Slack GitHub integration bot
│   │   ├── main.go               # HTTP server and Slack handlers
│   │   ├── github.go             # GitHub API client
│   │   ├── Dockerfile            # Multi-stage Docker build
│   │   ├── Makefile              # Build and test automation
│   │   └── README.md             # Application-specific docs
│   └── example-org-devops/             # DevOps CLI tool (planned)
├── shared/                       # Common libraries (future)
├── .github/                      # CI/CD workflows
│   └── workflows/                # GitHub Actions
├── docs/                         # Project documentation
├── Makefile                      # Root-level build commands
└── package.json                  # Workspace metadata
```

## CI/CD Pipeline

- **Pull Request**: Automated testing, linting, and security scanning
- **Main Branch**: Automated building and Docker image publishing
- **Release Tags**: Automated binary releases for multiple platforms
- **Security**: Dependency vulnerability scanning with Snyk

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

## License & Copyright

Copyright (c) 2024 **Kim YongHyun** (https://github.com/hulkong) and **Developer 2**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Authors

Created and maintained by:
- **Developer 1**
  - GitHub: [@hulkong](https://github.com/hulkong)
  - Email: cdfgogo0615@naver.com
  - Phone: 010-2763-9988
- **Developer 2**
  - GitHub: [@kimyoungjae96](https://github.com/kimyoungjae96)
  - Email: sskim5421@gmail.com
  - Phone: 010-5427-8851

### Acknowledgments

This DevOps monorepo was designed and implemented by Kim YongHyun and Kim YoungJae for DevOps tools and automation.
