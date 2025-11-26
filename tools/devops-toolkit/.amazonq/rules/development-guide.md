# 개발 가이드

## 모노레포 구조
- **apps/**: 애플리케이션별 디렉터리
- **shared/**: 공통 라이브러리 및 유틸리티 (향후 확장)
- **.github/**: CI/CD 워크플로우
- **docs/**: 프로젝트 문서

## 새 애플리케이션 추가 가이드

### 1. 디렉터리 생성
```bash
mkdir -p apps/{app-name}
cd apps/{app-name}
```

### 2. Go 애플리케이션 초기화
```bash
go mod init github.com/wetripod/devops-monorepo/apps/{app-name}
```

### 3. 필수 파일 생성
- `main.go`: 메인 애플리케이션 로직
- `README.md`: 애플리케이션별 상세 문서
- `Makefile`: 빌드 및 테스트 자동화
- `Dockerfile`: 컨테이너화 설정
- `.gitignore`: Go 프로젝트용 ignore 패턴

### 4. 테스트 구조
```
{app-name}/
├── main.go
├── main_test.go
├── internal/
│   ├── handler/
│   │   ├── handler.go
│   │   └── handler_test.go
│   └── service/
│       ├── service.go
│       └── service_test.go
```

## 개발 워크플로우

### 1. 로컬 개발
```bash
# 의존성 설치
make deps

# 코드 포맷팅
make fmt

# 린팅 실행
make lint

# 테스트 실행
make test

# 애플리케이션 실행
make run
```

### 2. Docker 개발
```bash
# Docker 이미지 빌드
make docker-build

# Docker 컨테이너 실행
make docker-run

# Docker Compose 실행
make compose-up
```

### 3. 배포 준비
```bash
# 프로덕션 빌드
make build-prod

# 보안 스캔
make security-scan

# 성능 테스트
make benchmark
```

## 코드 품질 기준

### Go 코드 스타일
- `gofmt`로 포맷팅 필수
- `golangci-lint` 통과 필수
- 함수/메서드 주석 작성
- 에러 핸들링 명시적 처리

### 테스트 요구사항
- 단위 테스트 커버리지 80% 이상
- 통합 테스트 포함
- 벤치마크 테스트 (성능 중요 함수)
- 테이블 드리븐 테스트 활용

### 문서화 기준
- README.md 필수 섹션 포함
- API 문서화 (Swagger/OpenAPI)
- 코드 주석 (godoc 형식)
- 사용 예제 포함

## CI/CD 통합

### GitHub Actions 워크플로우
```yaml
name: {app-name}
on:
  push:
    paths:
      - 'apps/{app-name}/**'
  pull_request:
    paths:
      - 'apps/{app-name}/**'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v4
      - run: make test
        working-directory: apps/{app-name}
```

### 배포 전략
- **개발환경**: PR 병합 시 자동 배포
- **스테이징환경**: 태그 생성 시 자동 배포
- **프로덕션환경**: 수동 승인 후 배포

## 보안 가이드라인

### 시크릿 관리
- 환경변수로 시크릿 관리
- AWS Secrets Manager 연동
- 하드코딩된 시크릿 절대 금지

### 의존성 관리
- `go mod tidy` 정기 실행
- 취약점 스캔 (`govulncheck`)
- 의존성 업데이트 자동화

## 모니터링 및 로깅

### 구조화된 로깅
```go
import "log/slog"

logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
logger.Info("application started", "port", port)
```

### 메트릭스 수집
- Prometheus 메트릭스 노출
- 헬스체크 엔드포인트 필수
- 성능 지표 추적

## 파일 다운로드 규칙
- 모든 파일 다운로드는 `~/Downloads/` 경로 사용
- 빌드 아티팩트 및 로그 파일도 동일 경로 활용