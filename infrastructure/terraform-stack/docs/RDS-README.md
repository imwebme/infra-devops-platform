# RDS Terraform 모듈 사용 가이드

## 개요

이 RDS Terraform 모듈은 다음 기능을 제공합니다:

- **다중 엔진 지원**: PostgreSQL, Aurora PostgreSQL, Aurora MySQL
- **기본 계정 생성**: example-org_admin 마스터 계정 자동 생성
- **자동 보안 설정**: 암호화, 보안 그룹, 서브넷 그룹
- **기존 리소스 Import**: 콘솔에서 생성된 RDS 리소스 가져오기

## 설정 방법

### 1. Config 파일 설정

환경별 config 파일(예: `alwayz-aws-dev-infra.yml`)에 RDS 설정을 추가합니다:

```yaml
rds:
  databases:
    # PostgreSQL Aurora 클러스터
    - identifier: "platform"
      engine: "aurora-postgresql"
      engine_version: "16"
      database_name: "platform_db"
      instance_class: "db.t4g.medium"
      instance_count: 2
      port: 5432
      backup_retention_period: 7
      deletion_protection: true
      skip_final_snapshot: false

    # 독립형 PostgreSQL 인스턴스
    - identifier: "mlflow"
      engine: "postgres"
      engine_version: "16"
      database_name: "mlflow_db"
      instance_class: "db.t4g.small"
      allocated_storage: 200
      port: 5432

    # Aurora MySQL 클러스터
    - identifier: "analytics"
      engine: "aurora-mysql"
      engine_version: "8.0"
      database_name: "analytics_db"
      instance_class: "db.t4g.medium"
      port: 3306
```

### 2. Terraform 실행

```bash
# 계획 확인
terraform -chdir=terraform/infra/aws plan

# 적용
terraform -chdir=terraform/infra/aws apply
```

### 3. 데이터베이스 접속 확인

Terraform 적용 후 생성된 RDS에 접속하여 정상 동작을 확인합니다:

```bash
# RDS 자격증명 확인
aws secretsmanager get-secret-value --secret-id "<prefix>/rds/<db-identifier>/credentials" --query SecretString --output text | jq .

# PostgreSQL 접속 테스트
psql -h <rds-endpoint> -U example-org_admin -d <database-name>
```

## 추가 사용자 및 권한 관리

Terraform은 RDS 클러스터와 example-org_admin 마스터 계정만 생성합니다. 추가 사용자나 권한 설정은 개발팀에서 필요에 따라 수동으로 진행하세요.

## 기존 RDS 리소스 Import

### 1. Import 스크립트 사용

```bash
# terraform/infra/aws 디렉터리에서 실행
cd terraform/infra/aws
./import-existing-rds.sh
```

### 2. 수동 Import

```bash
# terraform/infra/aws 디렉터리에서 실행
cd terraform/infra/aws

# Aurora 클러스터 import
terraform import 'aws_rds_cluster.aurora["platform"]' prod-platform-cluster

# Aurora 인스턴스 import
terraform import 'aws_rds_cluster_instance.aurora["platform-0"]' prod-platform-1

# 독립형 인스턴스 import
terraform import 'aws_db_instance.standalone["mlflow"]' prod-mlflow-instance-1

# 파라미터 그룹 import
terraform import 'aws_rds_cluster_parameter_group.aurora_postgresql["platform"]' prod-platform-aurorapg16

# 서브넷 그룹 import
terraform import 'aws_db_subnet_group.main["platform"]' prod-db-subnet-group
```

## 보안 설정

### 자동 적용되는 보안 설정

- **암호화**: 모든 RDS 인스턴스/클러스터에 저장 시 암호화 적용
- **보안 그룹**: VPC CIDR 내에서만 접근 허용
- **서브넷 그룹**: Private 서브넷에만 배치
- **백업**: 기본 7일 보존, Point-in-time 복구 지원

### 자격 증명 관리

- **AWS Secrets Manager**: 모든 RDS 자격 증명 자동 저장
- **랜덤 패스워드**: 16자리 복잡한 패스워드 자동 생성

## 모니터링 및 로깅

### 파라미터 그룹 설정

PostgreSQL 인스턴스에 다음 설정이 자동 적용됩니다:

**PostgreSQL 독립형 인스턴스:**
- `log_statement = all`
- `log_min_duration_statement = 1000`
- `log_lock_waits = 1`
- `idle_in_transaction_session_timeout = 300000`
- `statement_timeout = 7200000`
- `shared_preload_libraries = pg_stat_statements`

**Aurora PostgreSQL 클러스터:**
- 위 설정 + `pgaudit`, `max_connections = 5000`

**Aurora MySQL 클러스터:**
- `slow_query_log = 1`
- `long_query_time = 1`
- `innodb_lock_wait_timeout = 300`

## 파일 구조

```
terraform/infra/aws/
├── rds.tf                    # 메인 RDS 리소스 정의
├── import-existing-rds.sh    # Import 스크립트
terraform/config/
└── example.yml              # 설정 예시
docs/
└── RDS-README.md            # 이 파일
```

## 주의사항

1. **삭제 보호**: 프로덕션 환경에서는 `deletion_protection = true` 설정
2. **백업**: 중요한 데이터베이스는 `skip_final_snapshot = false` 설정
3. **접속 확인**: Terraform 적용 후 RDS 접속 및 정상 동작 확인
4. **Import**: 기존 리소스 import 시 설정값이 일치하는지 확인

## 트러블슈팅

### 일반적인 문제

1. **서브넷 그룹 오류**: `local.private_data_subnet_ids`가 올바르게 설정되었는지 확인
2. **파라미터 그룹 충돌**: 기존 파라미터 그룹과 이름이 중복되지 않는지 확인
3. **Import 오류**: 리소스 식별자와 Terraform 리소스 이름이 정확한지 확인

### 로그 확인

```bash
# RDS 로그 확인
aws rds describe-db-log-files --db-instance-identifier <instance-id>
aws rds download-db-log-file-portion --db-instance-identifier <instance-id> --log-file-name <log-file>
```

## 참고 자료

- [AWS RDS 문서](https://docs.aws.amazon.com/rds/)
- [PostgreSQL Role 관리](https://www.postgresql.org/docs/current/user-manag.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)