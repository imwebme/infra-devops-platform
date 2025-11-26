# Demo Infrastructure Documentation

이 디렉터리는 Demo 인프라 관련 문서들을 관리합니다.

## 📚 문서 목록

### Infrastructure Modules
- [RDS-README.md](./RDS-README.md) - RDS Terraform 모듈 사용 가이드

## 📁 문서 구조

```
docs/
├── README.md           # 이 파일
├── RDS-README.md      # RDS 모듈 가이드
└── ...                # 추가 문서들
```

## 🔧 문서 작성 가이드

새로운 인프라 모듈이나 기능에 대한 문서를 작성할 때는:

1. 해당 모듈명으로 파일 생성 (예: `EKS-README.md`)
2. 위 목록에 링크 추가
3. 사용법, 설정 예시, 트러블슈팅 포함
4. 실제 사용 사례와 예시 코드 제공

## 📝 문서 템플릿

```markdown
# [모듈명] 사용 가이드

## 개요
- 모듈의 주요 기능
- 지원하는 기능들

## 설정 방법
### 1. Config 파일 설정
### 2. Terraform 실행
### 3. 추가 설정 (필요시)

## 사용 예시
- 실제 설정 예시
- 코드 스니펫

## 트러블슈팅
- 일반적인 문제들
- 해결 방법

## 참고 자료
- 관련 문서 링크
```