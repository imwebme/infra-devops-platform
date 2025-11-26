# DevOps Monorepo 프로젝트 개요

## 프로젝트 목적
- **DevOps 도구 및 자동화 통합 관리**
- **모노레포 기반 멀티 애플리케이션 개발**
- **DevOps 팀 전용 도구 및 서비스 제공**

## 주요 구성 요소
- **Slack Bot**: GitHub Actions 워크플로우 트리거
- **DevOps CLI**: Kubernetes, AWS, GitOps 통합 관리 도구
- **자동화 스크립트**: 배포, 모니터링, 알림 자동화

## 애플리케이션 구조
```
apps/
├── slack-bot/           # Go 기반 Slack GitHub 봇
│   ├── main.go         # HTTP 서버 및 Slack 이벤트 핸들링
│   ├── github.go       # GitHub API 클라이언트
│   └── README.md       # 상세 사용법 및 배포 가이드
└── levit-devops/       # Go 기반 DevOps CLI 도구
    ├── main.go         # CLI 메인 엔트리포인트
    ├── internal/       # 내부 패키지 (cli, config)
    └── README.md       # CLI 사용법 및 설치 가이드
```

## 기술 스택
- **언어**: Go (주력), Node.js (확장용)
- **컨테이너**: Docker, Docker Compose
- **CI/CD**: GitHub Actions
- **배포**: AWS ECR, Kubernetes
- **모니터링**: Datadog 통합

## 개발 특징
- **모노레포 구조**: 여러 도메인별 앱 그룹핑
- **테스트 커버리지**: 80% 이상 목표
- **자동화된 빌드**: Makefile 기반 일관된 워크플로우
- **컨테이너화**: 멀티스테이지 Docker 빌드

## 파일 다운로드 규칙
- 모든 이미지 및 파일 다운로드는 `~/Downloads/` 경로 사용
- 빌드 아티팩트 및 로그 파일도 동일 경로 활용