.PHONY: help build test clean run docker-build docker-run deps fmt vet lint

# Variables
APP_NAME := slack-bot
VERSION := $(shell git describe --tags --always --dirty)
BUILD_TIME := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
LDFLAGS := -ldflags "-X main.version=$(VERSION) -X main.buildTime=$(BUILD_TIME)"

# Default target
help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Development
deps: ## Download dependencies
	go mod download
	go mod tidy

fmt: ## Format code
	go fmt ./...

vet: ## Run go vet
	go vet ./...

lint: ## Run staticcheck
	staticcheck ./...

test: ## Run tests
	go test -v -race -coverprofile=coverage.out ./...

test-coverage: test ## Run tests with coverage report
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

# Build
build: ## Build the application
	CGO_ENABLED=0 go build $(LDFLAGS) -o $(APP_NAME) .

build-linux: ## Build for Linux
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o $(APP_NAME) .

# Run
run: ## Run the application
	go run .

run-dev: ## Run with air for development (requires air: go install github.com/cosmtrek/air@latest)
	air

# Port management
kill-port: ## Kill any process using port 8080
	@echo "Killing any process using port 8080..."
	@lsof -ti:8080 | xargs kill -9 2>/dev/null || echo "No process found on port 8080"

clean-run: kill-port ## Kill port 8080 and run the application
	@sleep 1
	@$(MAKE) run

clean-run-dev: kill-port ## Kill port 8080 and run with verification disabled for development
	@sleep 1
	@echo "🚀 Starting in development mode (verification disabled)..."
	@SKIP_SLACK_VERIFICATION=true $(MAKE) run

test-mock: kill-port ## Run bot with mock environment variables for testing
	@echo "🚀 Starting bot with mock environment variables..."
	@sleep 1
	@SKIP_SLACK_VERIFICATION=true SLACK_BOT_TOKEN="xoxb-mock-token" SLACK_VERIFICATION_TOKEN="mock-token" GITHUB_TOKEN="ghp_mock_token" PORT=8080 GITHUB_ORG="wetripod" go run . &
	@echo "Bot started in background. Use 'make test-curl' to test it."

test-curl: ## Test the bot with a curl command
	@echo "🧪 Testing Slack GitHub Bot..."
	@curl -v -X POST "http://localhost:8080/slack/commands" \
		-H "Content-Type: application/x-www-form-urlencoded" \
		-d "command=/devops-action&text=wetripod/demo-infrastructure ci-infra-terraform-cloud.yml workspace_name test-workspace-$$(date +%s) working_directory terraform/infra/aws project_name Alwayz&user_id=U123456789&channel_id=C123456789"
	@echo ""
	@echo "📋 Expected: 'Bad credentials' error (mock token) = SUCCESS!"

# Docker
docker-build: ## Build Docker image
	docker build -t $(APP_NAME):$(VERSION) .
	docker tag $(APP_NAME):$(VERSION) $(APP_NAME):latest

docker-run: ## Run Docker container
	docker run -d --name $(APP_NAME) -p 8080:8080 \
		-e SLACK_BOT_TOKEN=$(SLACK_BOT_TOKEN) \
		-e SLACK_SIGNING_SECRET=$(SLACK_SIGNING_SECRET) \
		-e GITHUB_TOKEN=$(GITHUB_TOKEN) \
		-e GITHUB_ORG=$(GITHUB_ORG) \
		$(APP_NAME):latest

docker-stop: ## Stop Docker container
	docker stop $(APP_NAME) || true
	docker rm $(APP_NAME) || true

docker-logs: ## Show Docker logs
	docker logs -f $(APP_NAME)

# Docker Compose
compose-up: ## Start services with docker-compose
	docker-compose up -d

compose-down: ## Stop services with docker-compose
	docker-compose down

compose-logs: ## Show docker-compose logs
	docker-compose logs -f

# Clean
clean: ## Clean build artifacts
	rm -f $(APP_NAME)
	rm -f coverage.out
	rm -f coverage.html
	docker rmi $(APP_NAME):latest || true
	docker rmi $(APP_NAME):$(VERSION) || true

# Check
check: deps fmt vet lint test ## Run all checks

# CI
ci: check build ## Run CI pipeline

# Install development tools
install-tools: ## Install development tools
	go install honnef.co/go/tools/cmd/staticcheck@latest
	go install github.com/cosmtrek/air@latest
