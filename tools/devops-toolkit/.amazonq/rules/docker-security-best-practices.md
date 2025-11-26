# Docker 보안 베스트 프랙티스

## 베이스 이미지 보안

### 1. 최소 권한 베이스 이미지 사용
```dockerfile
# ❌ 피해야 할 패턴
FROM ubuntu:latest

# ✅ 권장 패턴
FROM golang:1.21-alpine AS builder
FROM scratch
# 또는
FROM gcr.io/distroless/static-debian12
```

### 2. 특정 태그 사용 (latest 금지)
```dockerfile
# ❌ 피해야 할 패턴
FROM golang:latest

# ✅ 권장 패턴
FROM golang:1.21.5-alpine3.18
```

## 사용자 권한 관리

### 3. Non-root 사용자 생성 및 사용
```dockerfile
# 사용자 생성
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# 애플리케이션 파일 소유권 변경
COPY --chown=appuser:appgroup ./app /app

# Non-root 사용자로 전환
USER appuser

# 작업 디렉터리 설정
WORKDIR /app
```

### 4. 읽기 전용 루트 파일시스템
```dockerfile
# 컨테이너 실행 시 읽기 전용 설정
# docker run --read-only --tmpfs /tmp myapp
```

## 시크릿 및 민감 정보 보안

### 5. 빌드 시크릿 사용 (ARG 대신)
```dockerfile
# ❌ 피해야 할 패턴
ARG GITHUB_TOKEN
RUN git clone https://${GITHUB_TOKEN}@github.com/private/repo.git

# ✅ 권장 패턴 (BuildKit 사용)
# syntax=docker/dockerfile:1
RUN --mount=type=secret,id=github_token \
    git clone https://$(cat /run/secrets/github_token)@github.com/private/repo.git
```

### 6. 멀티스테이지 빌드로 시크릿 격리
```dockerfile
# 빌드 스테이지
FROM golang:1.21-alpine AS builder
RUN --mount=type=secret,id=github_token \
    go mod download

# 프로덕션 스테이지 (시크릿 없음)
FROM scratch
COPY --from=builder /app/binary /app
```

## 파일시스템 보안

### 7. 불필요한 파일 제거
```dockerfile
# 빌드 캐시 및 임시 파일 정리
RUN apk add --no-cache git && \
    git clone https://github.com/repo.git && \
    cd repo && make build && \
    cp binary /usr/local/bin/ && \
    cd / && rm -rf /repo && \
    apk del git
```

### 8. .dockerignore 활용
```dockerignore
# .dockerignore
.git
.github
*.md
.env*
node_modules
coverage.out
*.test
.DS_Store
```

## 네트워크 보안

### 9. 최소 포트 노출
```dockerfile
# 필요한 포트만 노출
EXPOSE 8080

# 헬스체크 포함
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1
```

### 10. 네트워크 격리
```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    networks:
      - app-network
    ports:
      - "8080:8080"
networks:
  app-network:
    driver: bridge
```

## 실행 시 보안

### 11. 보안 옵션 설정
```dockerfile
# Dockerfile에서 보안 레이블 설정
LABEL security.scan="enabled"
LABEL security.non-root="true"
```

```bash
# 실행 시 보안 옵션
docker run \
  --read-only \
  --tmpfs /tmp \
  --tmpfs /var/run \
  --user 1001:1001 \
  --cap-drop=ALL \
  --cap-add=NET_BIND_SERVICE \
  --no-new-privileges \
  --security-opt=no-new-privileges:true \
  myapp:latest
```

## 이미지 스캔 및 검증

### 12. 보안 스캔 통합
```dockerfile
# Makefile에 보안 스캔 추가
security-scan:
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy image $(IMAGE_NAME):$(VERSION)

# 또는 Snyk 사용
snyk-scan:
	snyk container test $(IMAGE_NAME):$(VERSION)
```

### 13. 이미지 서명 및 검증
```bash
# Docker Content Trust 활성화
export DOCKER_CONTENT_TRUST=1

# 이미지 서명
docker trust sign myregistry/myapp:v1.0.0

# 서명 검증
docker trust inspect myregistry/myapp:v1.0.0
```

## 완전한 보안 Dockerfile 예제

```dockerfile
# syntax=docker/dockerfile:1
FROM golang:1.21.5-alpine3.18 AS builder

# 보안 업데이트 설치
RUN apk update && apk upgrade && apk add --no-cache ca-certificates git

# Non-root 사용자 생성
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# 작업 디렉터리 설정
WORKDIR /build

# 의존성 파일 복사 (캐시 최적화)
COPY go.mod go.sum ./
RUN go mod download && go mod verify

# 소스 코드 복사
COPY . .

# 정적 바이너리 빌드
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o app ./cmd/main.go

# 프로덕션 스테이지
FROM scratch

# 메타데이터 추가
LABEL maintainer="devops@example.com"
LABEL security.scan="enabled"
LABEL security.non-root="true"

# CA 인증서 복사 (HTTPS 통신용)
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Non-root 사용자 정보 복사
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# 애플리케이션 바이너리 복사
COPY --from=builder --chown=1001:1001 /build/app /app

# Non-root 사용자로 전환
USER 1001:1001

# 포트 노출
EXPOSE 8080

# 헬스체크 (가능한 경우)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/app", "health"] || exit 1

# 애플리케이션 실행
ENTRYPOINT ["/app"]
```

## CI/CD 파이프라인 보안 검사

```yaml
# .github/workflows/security.yml
name: Security Scan
on: [push, pull_request]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build Docker image
        run: docker build -t test-image .
        
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'test-image'
          format: 'sarif'
          output: 'trivy-results.sarif'
          
      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
```

## 체크리스트

### 빌드 시 확인사항
- [ ] 최소 권한 베이스 이미지 사용
- [ ] 특정 버전 태그 사용 (latest 금지)
- [ ] Non-root 사용자 생성 및 사용
- [ ] 멀티스테이지 빌드로 공격 표면 최소화
- [ ] 불필요한 패키지 및 파일 제거
- [ ] .dockerignore로 민감 파일 제외

### 실행 시 확인사항
- [ ] 읽기 전용 루트 파일시스템
- [ ] 최소 권한 실행 (--cap-drop=ALL)
- [ ] 네트워크 격리 설정
- [ ] 리소스 제한 설정
- [ ] 보안 스캔 통과

### 배포 전 확인사항
- [ ] 취약점 스캔 완료
- [ ] 이미지 서명 및 검증
- [ ] 보안 정책 준수 확인
- [ ] 모니터링 및 로깅 설정