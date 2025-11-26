# Alwayz GitOps Manifest 프로젝트 개요

## 프로젝트 목적
- **Alwayz 서비스 애플리케이션 배포 전용**
- **환경별 통합 관리**
- **서비스 중심의 GitOps 워크플로우**

## 관리 대상
- **Alwayz 서비스**: API, BFF, Admin 등 비즈니스 애플리케이션
- **크론잡**: 배치 작업 및 스케줄링 태스크
- **스크래퍼**: 데이터 수집 및 처리 워크로드

## 환경 구조
- **개발환경**: dev
- **스테이징환경**: staging  
- **프로덕션환경**: prod

## ApplicationSet 패턴
- **환경별 통합**: environment 라벨 기반 매칭
- **서비스 타입별 분리**: demo-services, demo-scrapers, demo-cronjobs
- **ECR 이미지 자동 업데이트**: ArgoCD Image Updater 연동

## 배포 특징
- **자동 이미지 업데이트**: ECR 태그 패턴 매칭
- **Slack 알림 연동**: 배포 상태 실시간 알림
- **환경별 리소스 최적화**: dev < staging < prod

## 네임스페이스 전략
- **demo-services**: 메인 비즈니스 서비스
- **demo-scrapers**: 데이터 수집 서비스
- **demo-cronjobs**: 배치 및 스케줄 작업

## 파일 다운로드 규칙
- 모든 이미지 및 파일 다운로드는 `~/Downloads/` 경로 사용
- 설정 파일 백업 및 임시 파일도 동일 경로 활용