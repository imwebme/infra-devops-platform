# demo-python-cron

이 프로젝트는 크론 작업을 위한 프로젝트입니다.

EKS 환경에 본인이 생성한 크론잡을 등록하고자 한다면, 다음의 [Python 기반 CronJob 실행 메뉴얼](https://www.notion.so/Python-CronJob-04a9c5b6654646b6bd4579259a3e833a)를 참고해 주세요.

<br>

## 실행 환경

---

- mac(Apple silicon)
- docker: v20.10.21 컨테이너 런타임
- MongoDB: v7, 데이터베이스
- Python: v3.10

<br><br>

## 로컬환경 구축

---

### 1) 저장소 복제

```bash
git clone https://github.com/wetripod/demo-python-cron.git
cd demo-python-cron
```

<br>

### 2) docker 설치

```bash
# Homebrew on OS X
# https://docs.docker.com/desktop/install/mac-install/
brew install cask docker

docker -v
Docker version 20.10.21, build baeda1f
```

<br>

### 3) [demo-config](https://github.com/wetripod/demo-config.git) 레포에서 환경변수 파일 받기

- [.env.local](https://github.com/wetripod/demo-config/blob/main/templates/demo-cron-python.env.local.njk): 로컬 환경변수
- [.env.dev](https://github.com/wetripod/demo-config/blob/main/templates/demo-cron-python.dev.njk): 개발 환경변수
- [.env.prod](https://github.com/wetripod/demo-config/blob/main/templates/demo-cron-python.env.prod.njk): 운영 환경변수

```bash
# 다음 빌드한 결과물의 .env.{ENVIRONMENT} 파일을 demo-python-cron 레포에 옮김
cd demo-config
npm run build
```

<br>

### 4) 가상환경 세팅
```bash
pipenv shell
pipenv install
```

<br>

### 5) 로컬에서 자신이 생성한 Job 테스트

```bash
# 로컬환경에서 Job 테스트하는 명령어
# ENVIRONMENT: local, dev, prod
ENV={ENVIRONMENT} python main.py --name "Job 이름" --files "실행할 파이썬 스크립트1" "실행할 파이썬 스크립트2"
```

<br>

아래는 여러가지 상황을 고려하여 Job을 실행시키는 예제들입니다.

```bash
# 03-oncall_to_slack.py 파일을 로컬에서 실행시키는 예제
ENV=local python main.py --name test --files "03-oncall_to_slack.py"
```

<br>
다음은 로컬에서 .env.prod 환경파일을 기반으로 테스트를 진행할 때, 슬랙 알람을 비활성화 하기 위한 방법입니다.

```bash
ENV=prod ENABLE_SLACK=false python main.py --name test --files "03-oncall_to_slack.py"
```

<br><br>

## 참고

---

- [Writing a CronJob spec](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#writing-a-cronjob-spec)
- [Python 기반 CronJob 실행 메뉴얼](https://www.notion.so/Python-CronJob-04a9c5b6654646b6bd4579259a3e833a)
- [ArgoCD Cronjobs 애플리케이션](https://argocd.iexample-org.com/applications/argocd/demo-cronjobs-python?view=tree&resource=)
- [데이터독 대시보드](https://app.datadoghq.com/dash/integration/30464/kubernetes-jobs-and-cronjobs-overview?fromUser=false&refresh_mode=sliding&view=spans&from_ts=1716180707842&to_ts=1716267107842&live=true)

## [Amazon Q] 코드 보안 게이트

이 프로젝트는 GitHub Actions를 통한 Amazon Q 코드 보안 게이트를 포함하고 있습니다. 이 보안 게이트는 다음과 같은 기능을 제공합니다:

### 주요 기능

- Pull Request 및 브랜치 푸시 시 자동 보안 스캔
- Amazon Q Developer를 활용한 코드 취약점 분석 및 코드 리뷰
- 다음 취약점 유형 감지:
  - 하드코딩된 비밀번호, API 키, 토큰
  - SQL 인젝션 취약점
  - 명령어 인젝션 취약점
  - 안전하지 않은 직렬화/역직렬화
  - 안전하지 않은 암호화 방식
  - 권한 검증 부재
  - 입력값 검증 부재
  - 로깅 및 모니터링 부재
  - 안전하지 않은 파일 업로드/다운로드
  - 안전하지 않은 리다이렉트

### 설정 방법

1. GitHub 저장소 설정에서 다음 시크릿을 추가합니다:
   - `AWS_ROLE_TO_ASSUME`: Amazon Q Developer에 접근할 수 있는 IAM 역할 ARN
   - `AWS_REGION`: AWS 리전 (기본값: ap-northeast-2)
2. Pull Request를 생성하면 자동으로 보안 스캔과 코드 리뷰가 실행됩니다.
3. 발견된 취약점과 코드 개선 제안이 PR에 코멘트로 추가됩니다.

### 수동 실행

워크플로우 페이지에서 "[Amazon Q] 코드 보안 게이트" 워크플로우를 수동으로 실행할 수도 있습니다.