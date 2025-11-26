.PHONY: build install clean test

# 기본 변수
BINARY_NAME=levit-devops
BUILD_DIR=./bin
INSTALL_DIR=/usr/local/bin

# 빌드
build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	go build -o $(BUILD_DIR)/$(BINARY_NAME) .

# 설치
install: build
	@echo "Installing $(BINARY_NAME) to $(INSTALL_DIR)..."
	sudo cp $(BUILD_DIR)/$(BINARY_NAME) $(INSTALL_DIR)/
	sudo chmod +x $(INSTALL_DIR)/$(BINARY_NAME)

# 개발용 빌드 및 실행
dev: build
	@echo "Running $(BINARY_NAME)..."
	$(BUILD_DIR)/$(BINARY_NAME) --help

# 테스트
test:
	go test ./...

# 정리
clean:
	@echo "Cleaning up..."
	rm -rf $(BUILD_DIR)

# 의존성 설치
deps:
	go mod tidy
	go mod download

# 크로스 컴파일 (Linux, macOS, Windows)
build-all:
	@echo "Building for multiple platforms..."
	@mkdir -p $(BUILD_DIR)
	GOOS=linux GOARCH=amd64 go build -o $(BUILD_DIR)/$(BINARY_NAME)-linux-amd64 .
	GOOS=darwin GOARCH=amd64 go build -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-amd64 .
	GOOS=darwin GOARCH=arm64 go build -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-arm64 .
	GOOS=windows GOARCH=amd64 go build -o $(BUILD_DIR)/$(BINARY_NAME)-windows-amd64.exe .

# 도움말
help:
	@echo "Available commands:"
	@echo "  build     - Build the binary"
	@echo "  install   - Install to system PATH"
	@echo "  dev       - Build and run with help"
	@echo "  test      - Run tests"
	@echo "  clean     - Clean build artifacts"
	@echo "  deps      - Install dependencies"
	@echo "  build-all - Cross-compile for multiple platforms"