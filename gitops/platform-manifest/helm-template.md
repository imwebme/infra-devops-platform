# 🛠️ Helm Template 스크립트 메뉴얼 (`helm-template.sh`)

## 📌 개요

이 스크립트는 Helm 차트를 쿠버네티스 매니페스트로 렌더링하는 자동화 도구입니다. GitHub `values.yaml` URL도 지원하며, 다중 values 파일 적용이 가능합니다.

<br><br>

## ▶️ 기본 사용법

```bash
./scripts/helm-template.sh <chart-name> [values-file-path-or-url...]
```

**예시:**

```bash
# 기본 렌더링
./scripts/helm-template.sh workloads/base-cronjobs

# 로컬 values.yaml 지정
./scripts/helm-template.sh workloads/base-cronjobs values/dev/values.yaml

# 여러 파일 병합
./scripts/helm-template.sh workloads/base-cronjobs values/base.yaml values/dev/values.yaml

# GitHub URL도 가능(다만, 프라이빗 저장소는 GITHUB_TOKEN 환경변수가 설정되어 있어야 함)
./scripts/helm-template.sh workloads/base-cronjobs https://github.com/user/repo/blob/main/values.yaml values/override.yaml
```

<br><br>

## **⚙️ 동작 방식**

- charts/<chart-name> 경로의 Helm 차트를 기준으로 렌더링
- 로컬 파일 외에도 GitHub blob URL 사용 가능 (자동 raw 변환)
- helm template 명령어를 내부적으로 실행
- 임시 파일 생성 및 삭제 자동 처리

<br><br>

## **🧪 예외 처리**

- 차트 디렉토리 또는 values 파일이 없으면 에러 출력
- GitHub 주소에서 다운로드 실패 시 종료
- 모든 오류 발생 시 임시 파일 정리

<br><br>

## **🧹 내부 실행 명령어 예시**

```
helm template charts/<chart-name> -f values1.yaml -f values2.yaml ...
```

<br><br>

## **📝 요구 사항**

- Helm 3.x 이상
- curl, mktemp 명령어 필요
- 루트 디렉토리에서 실행 필요 (즉, charts/ 디렉토리가 있어야 함)
