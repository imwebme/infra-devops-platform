# GitOps 컨벤션 및 베스트 프랙티스

## 프로젝트 개요
- EKS 클러스터 전체에 코어 애드온과 공통 애드온을 일괄 배포/관리하는 GitOps 레포지토리
- ArgoCD ApplicationSet을 통한 멀티 클러스터 관리
- 내부 Helm 차트 관리 및 배포

## 디렉터리 구조 규칙

### 핵심 디렉터리
- `bootstraps/`: ArgoCD ApplicationSet 정의 (addons, administrations, workloads)
- `charts/`: 내부 Helm 차트 (addons, workloads)
- `clusters/`: 클러스터별 특화 설정
- `configs/`: 클러스터별 values 파일
- `environments/`: 환경별 공통 설정
- `global/`: 전역 리소스 (namespaces, CRDs, priority-classes)

### 네이밍 컨벤션
- 클러스터명: `{service}-{env}-eks` (예: demo-dev-eks, data-prod-eks)
- ApplicationSet: `{type}-{category}-appset.yaml` (예: addons-helm-internal-appset.yaml)
- Helm 차트: kebab-case 사용 (예: aws-ebs-csi, prometheus-mongodb-exporter)

## ApplicationSet 패턴

### 표준 ApplicationSet 타입
- `addons-helm-external-appset.yaml`: 외부 Helm 차트 애드온
- `addons-helm-internal-appset.yaml`: 내부 Helm 차트 애드온
- `addons-raw-internal-appset.yaml`: Raw YAML 애드온
- `workloads-*-appset.yaml`: 워크로드 배포용

### Generator 패턴
- Git generator 사용으로 클러스터별 자동 배포
- Path 기반 필터링으로 환경별 분리
- Values 파일은 configs/ 디렉터리에서 관리

## Helm 차트 관리

### 내부 차트 구조
- `charts/addons/`: 인프라 애드온 차트
- `charts/workloads/`: 애플리케이션 워크로드 차트
- 각 차트는 독립적인 Chart.yaml과 values.yaml 보유

### Values 우선순위
1. `environments/base/`: 기본값
2. `configs/{cluster}/`: 클러스터별 설정
3. `clusters/{cluster}/`: 클러스터별 오버라이드

## 보안 및 베스트 프랙티스

### 시크릿 관리
- External Secrets Operator 사용
- AWS Secrets Manager/Parameter Store 연동
- 하드코딩된 시크릿 절대 금지

### 리소스 관리
- Priority Classes 적용 (core-addons > common-addons > monitoring-addons)
- Resource limits/requests 필수 설정
- Namespace 분리 원칙 준수

### 모니터링
- ServiceMonitor/PodMonitor CRD 활용
- Prometheus 메트릭 수집 표준화
- Datadog 통합 모니터링

## Git 워크플로우

### Commit 메시지 (Udacity 스타일)
- `feat: add new addon for EKS cluster monitoring`
- `fix: resolve helm chart dependency issue`
- `docs: update GitOps deployment guide`
- `refactor: restructure addon ApplicationSets`

### 브랜치 전략
- `feature/DEVOPS-XXX-description`: 새 기능 개발
- `fix/DEVOPS-XXX-description`: 버그 수정
- `hotfix/DEVOPS-XXX-description`: 긴급 수정

### PR 규칙
- 제목: `[DEVOPS-XXX] type: description`
- Helm 차트 변경 시 template 테스트 필수
- ApplicationSet 변경 시 영향받는 클러스터 명시

## 배포 프로세스

### CI/CD 파이프라인
- PR 생성 시: Helm template 검증
- 병합 시: ArgoCD 자동 동기화
- 차트 변경 시: 자동 버전 업데이트

### 롤백 전략
- Git revert를 통한 즉시 롤백
- ArgoCD UI를 통한 수동 롤백
- 클러스터별 독립적 롤백 가능

## 문제 해결

### 일반적인 이슈
- ApplicationSet 동기화 실패: path 필터 확인
- Helm 차트 배포 실패: values 파일 검증
- 클러스터별 설정 충돌: 우선순위 확인

### 디버깅 도구
- `argocd app sync`: 수동 동기화
- `helm template`: 로컬 템플릿 검증
- `kubectl describe`: 리소스 상태 확인