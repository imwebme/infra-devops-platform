# demo-cron

이 프로젝트는 크론 작업을 위한 프로젝트입니다.

EKS 환경에 본인이 생성한 크론잡을 등록하고자 한다면, 다음의 [NodeJS 기반 CronJob 실행 메뉴얼](https://www.notion.so/NodeJS-CronJob-5460949186244684943c67b76ae603fb)를 참고해 주세요.

<br>

## 실행 환경

---

- mac(Apple silicon)
- docker: v20.10.21 컨테이너 런타임
- MongoDB: v7, 데이터베이스
- nodeJs: v18.19.0

<br><br>

## 로컬환경 구축

---

### 1) 저장소 복제

```bash
git clone https://github.com/wetripod/demo-cron.git
cd demo-cron
```

<br>

### 2) 라이브러리 설치
```bash
npm install
```

<br>

### 3) docker 설치

```bash
# Homebrew on OS X
# https://docs.docker.com/desktop/install/mac-install/
brew install cask docker

docker -v
Docker version 20.10.21, build baeda1f
```

<br>

### 4) [demo-config](https://github.com/wetripod/demo-config.git) 레포에서 환경변수 파일 받기

- [.env.local](https://github.com/wetripod/demo-config/blob/main/templates/demo-cron.env.local.njk): 로컬 환경변수
- [.env.dev](https://github.com/wetripod/demo-config/blob/main/templates/demo-cron.env.dev.njk): 개발 환경변수
- [.env.prod](https://github.com/wetripod/demo-config/blob/main/templates/demo-cron.env.prod.njk): 운영 환경변수

```bash
# 다음 빌드한 결과물의 .env.{ENVIRONMENT} 파일을 demo-cron 레포에 옮김
cd demo-config
npm run build
```

<br>

### 5) 로컬에서 자신이 생성한 Job 테스트

```bash
# 로컬환경에서 Job 테스트하는 명령어
# ENVIRONMENT: local, dev, prod
NODE_ENV={ENVIRONMENT} node main.js "로깅 메시지" 'SERVICE.FUNCTION(arg1, ......)'
```

<br>

아래는 여러가지 상황을 고려하여 Job을 실행시키는 예제들입니다.

```bash
# 1. TestService 내에 test1 함수를 실행시키는 예제
NODE_ENV=local node main.js '이건 테스트!' 'TestService.test1()'

# 2. TestService 내에 test3 함수에 boolean 파라미터를 전달하여 실행시키는 예제
NODE_ENV=local node main.js '이건 테스트!' 'TestService.test3(true)'

# 3. TestService 내에 test4 함수에 여러 타입의 파라미터를 전달하여 실행시키는 예제
NODE_ENV=local node main.js '이건 테스트!' 'TestService.test4(120, [40, 60], 6, 30, [{ "a": "1", "b": "50" }], [{ "c": "300" }], true, false)’

# 4. TestService 내에 test1, test2, test3 함수를 실행하는 예제각 함수는 동기적으로 실행됌
NODE_ENV=local node main.js '이건 테스트!' "TestService.test1() TestService.test2() TestService.test3(false)"
```

<br>
다음은 로컬에서 .env.prod 환경파일을 기반으로 테스트를 진행할 때, 슬랙 알람을 비활성화 하기 위한 방법입니다.

```bash
NODE_ENV=local ENABLE_SLACK=false node main.js '이건 테스트!' 'TestService.test1()'
```

<br><br>

## 참고

---

- [Writing a CronJob spec](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#writing-a-cronjob-spec)
- [NodeJS 기반 CronJob 실행 메뉴얼](https://www.notion.so/NodeJS-CronJob-5460949186244684943c67b76ae603fb)
- [ArgoCD Cronjobs 애플리케이션](https://argocd.iexample-org.com/applications/argocd/demo-cronjobs?view=tree&resource=)
- [데이터독 대시보드](https://app.datadoghq.com/dash/integration/30464/kubernetes-jobs-and-cronjobs-overview?fromUser=false&refresh_mode=sliding&view=spans&from_ts=1716180707842&to_ts=1716267107842&live=true)