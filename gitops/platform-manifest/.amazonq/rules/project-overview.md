# DevOps GitOps Manifest 프로젝트 개요

## 프로젝트 목적
- **전체 클러스터 총괄 관리**
- **코어성 애드온 및 워크로드 관리**
- **데브옵스 전용 GitOps 레포지토리**

## 관리 대상
- **인프라 애드온**: cert-manager, ingress-nginx, monitoring 등
- **데이터베이스 워크로드**: MongoDB, PostgreSQL, Redis 등
- **보안 도구**: external-secrets, karpenter, robusta 등

## 클러스터 구조
- **서비스별 클러스터**: `{service}-{env}-eks`
  - demo-dev-eks, demo-prod-eks
  - data-dev-eks, data-prod-eks
  - security-prod-eks

## ApplicationSet 패턴
- **클러스터별 세분화**: aws_cluster_name 기반 매칭
- **애드온 타입별 분리**: helm-external, helm-internal, raw-internal
- **워크로드 타입별 분리**: db-*, monitoring-*

## 배포 전략
- **자동 동기화**: 개발/스테이징 환경
- **수동 승인**: 프로덕션 환경 (중요 리소스)
- **단계적 롤아웃**: 개발 → 스테이징 → 프로덕션

## 파일 다운로드 규칙
- 모든 이미지 및 파일 다운로드는 `~/Downloads/` 경로 사용
- 차트 패키징 및 임시 파일도 동일 경로 활용