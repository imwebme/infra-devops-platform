# Git 컨벤션 및 워크플로우 가이드

## Commit 메시지 컨벤션 (Udacity 스타일)

### 기본 형식
```
<type>: <subject>

<body>

<footer>
```

### Type 종류
- `feat`: 새로운 기능 추가 (새 애드온, 차트, ApplicationSet)
- `fix`: 버그 수정 (배포 실패, 설정 오류 등)
- `docs`: 문서 수정 (README, 가이드 업데이트)
- `style`: 코드 포맷팅, YAML 정리 등 (기능 변경 없음)
- `refactor`: 코드 리팩터링 (차트 구조 개선, ApplicationSet 재구성)
- `test`: 테스트 추가 (Helm test, 검증 스크립트)
- `chore`: 빌드 업무, CI/CD 설정, 의존성 업데이트

### GitOps 특화 예시
```
feat: add prometheus-mongodb-exporter addon for data clusters (DEVOPS-123)

- Create internal helm chart for MongoDB monitoring
- Add ServiceMonitor configuration for Prometheus
- Configure cluster-specific values for data-dev-eks and data-prod-eks

Closes DEVOPS-123
```

```
fix: resolve ArgoCD sync failure in cert-manager ApplicationSet (DEVOPS-124)

- Fix path mapping in git generator
- Update namespace configuration for cert-manager
- Add missing RBAC permissions

Fixes DEVOPS-124
```

## 브랜치 네이밍 컨벤션

### 형식
```
<type>/<jira-ticket>-<brief-description>
```

### GitOps 특화 예시
- `feature/DEVOPS-123-add-mongodb-exporter-addon`
- `fix/DEVOPS-124-cert-manager-appset-sync-failure`
- `docs/DEVOPS-125-update-helm-chart-guidelines`
- `refactor/DEVOPS-126-restructure-addon-applicationsets`
- `chore/DEVOPS-127-update-external-chart-versions`

## PR 제목 컨벤션

### 형식
```
[DEVOPS-XXX] <type>: <description>
```

### 예시
- `[DEVOPS-123] feat: add prometheus-mongodb-exporter addon`
- `[DEVOPS-124] fix: resolve cert-manager ApplicationSet sync failure`
- `[DEVOPS-125] docs: update Helm chart development guidelines`
- `[DEVOPS-126] refactor: restructure addon ApplicationSets for better maintainability`

## Jira 티켓 연동 규칙

### 필수 포함 위치
1. **브랜치명**: `feature/DEVOPS-123-description`
2. **커밋 메시지**: `feat: description (DEVOPS-123)`
3. **PR 제목**: `[DEVOPS-123] feat: description`
4. **PR 본문**: Jira 링크 및 상세 설명

### 자동 연동을 위한 키워드
- `Closes DEVOPS-XXX`: 이슈 완료
- `Fixes DEVOPS-XXX`: 버그 수정 완료
- `Refs DEVOPS-XXX`: 이슈 참조
- `Implements DEVOPS-XXX`: 기능 구현 완료

## GitOps 특화 커밋 가이드라인

### 애드온 관련 커밋
```
feat: add aws-ebs-csi-driver addon for EKS clusters (DEVOPS-123)

- Create internal Helm chart with CSI driver configuration
- Add cluster-specific StorageClass definitions
- Configure IRSA for EBS CSI controller
- Add monitoring with ServiceMonitor

Closes DEVOPS-123
```

### ApplicationSet 변경
```
refactor: improve addons ApplicationSet structure (DEVOPS-124)

- Split helm-external and helm-internal ApplicationSets
- Add better path filtering for cluster selection
- Improve values file hierarchy and inheritance
- Update sync policies for better reliability

Refs DEVOPS-124
```

### Helm 차트 업데이트
```
chore: update external chart versions (DEVOPS-125)

- cert-manager: 1.12.0 -> 1.13.0
- ingress-nginx: 4.7.0 -> 4.8.0
- external-dns: 1.13.0 -> 1.14.0
- Update values for compatibility

Closes DEVOPS-125
```

### 설정 변경
```
fix: correct resource limits for monitoring addons (DEVOPS-126)

- Increase memory limits for Prometheus in prod clusters
- Adjust CPU requests for Grafana
- Update PVC sizes for long-term storage
- Apply changes to demo-prod-eks and data-prod-eks

Fixes DEVOPS-126
```

## PR 템플릿 활용

### 체크리스트 (GitOps 특화)
- [ ] Helm 차트 lint 통과
- [ ] ApplicationSet 템플릿 검증 완료
- [ ] 영향받는 클러스터 확인
- [ ] Values 파일 검증 완료
- [ ] 문서 업데이트 (필요시)
- [ ] 테스트 환경 배포 확인
- [ ] 롤백 계획 수립

### 변경 사항 설명
```markdown
## 변경 내용
- 새로운 애드온 추가: prometheus-mongodb-exporter
- 대상 클러스터: data-dev-eks, data-prod-eks
- 모니터링 대시보드 연동

## 테스트 결과
- [x] Helm template 검증 통과
- [x] 개발 환경 배포 성공
- [x] 메트릭 수집 확인

## 배포 계획
1. 개발 환경 먼저 배포
2. 24시간 모니터링 후 프로덕션 배포
3. 기존 모니터링과 충돌 없음 확인
```

## 릴리스 태깅 규칙

### 시맨틱 버저닝
- `v1.0.0`: 메이저 릴리스 (Breaking changes)
- `v1.1.0`: 마이너 릴리스 (새 기능, 애드온 추가)
- `v1.1.1`: 패치 릴리스 (버그 수정, 설정 변경)

### 태그 메시지 예시
```
git tag -a v1.2.0 -m "Release v1.2.0: Add MongoDB monitoring stack

- Add prometheus-mongodb-exporter addon
- Update Grafana dashboards for database monitoring
- Improve resource allocation for monitoring stack
- Support for new data-prod-eks cluster"
```

## 핫픽스 워크플로우

### 긴급 수정 프로세스
1. `main`에서 `hotfix/DEVOPS-XXX-description` 브랜치 생성
2. 최소한의 변경으로 문제 해결
3. 즉시 PR 생성 및 리뷰
4. 병합 후 즉시 배포
5. 사후 분석 및 문서화

### 핫픽스 커밋 예시
```
hotfix: disable failing addon in production clusters (DEVOPS-999)

- Temporarily disable prometheus-mongodb-exporter in prod
- Add condition to skip deployment until fix is ready
- Prevent cascading failures in monitoring stack

Emergency fix for DEVOPS-999
```