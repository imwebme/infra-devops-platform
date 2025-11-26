---
description: Terraform Infrastructure as Code (IaC) Best Practices Ruleset for Alwayz Infrastructure
globs:
  - "terraform/**/*.tf"
  - "terraform/**/*.tfvars"
  - "terraform/**/*.hcl"
  - "**/*.tf"
  - "**/*.tfvars"
  - "**/*.hcl"
  - ".github/**/*.yml"
  - ".github/**/*.yaml"
  - ".github/**/*.md"
alwaysApply: true
---

# Terraform Infrastructure as Code Best Practices for Alwayz Infrastructure

You are an expert Terraform Infrastructure as Code (IaC) engineer. Follow these comprehensive best practices for developing, maintaining, and deploying infrastructure code in the Alwayz infrastructure project.

## Project Structure & Directory Organization

### Infrastructure Directory Structure
```
terraform/
├── config/                           # Environment-specific configurations
│   ├── _defaults.yml                # Default values shared across environments
│   ├── alwayz-aws-dev-infra.yml     # AWS dev environment config
│   ├── alwayz-aws-staging-infra.yml # AWS staging environment config
│   ├── alwayz-aws-prod-infra.yml    # AWS production environment config
│   ├── aws-data-dev-infra.yml       # AWS data dev environment config
│   ├── aws-data-prod-infra.yml      # AWS data prod environment config
│   ├── security-aws-core-infra.yml  # Security core infrastructure config
│   └── security-aws-prod-infra.yml  # Security prod infrastructure config
└── infra/                           # Infrastructure modules by provider
    ├── aws/                         # AWS-specific infrastructure
    │   ├── main.tf                  # Primary AWS resources
    │   ├── variables.tf             # Input variables
    │   ├── outputs.tf               # Output values
    │   ├── locals.tf                # Local values
    │   ├── providers.tf             # AWS provider config
    │   ├── terraform.tf             # Terraform version constraints
    │   ├── data.tf                  # Data sources
    │   ├── vpc-network.tf           # VPC and networking
    │   ├── eks.tf                   # EKS cluster resources
    │   ├── rds.tf                   # Database resources
    │   ├── s3.tf                    # Storage resources
    │   ├── iam.tf                   # IAM roles and policies
    │   ├── route53.tf               # DNS resources
    │   ├── elasticache.tf           # Cache resources
    │   └── modules/                 # Local AWS modules
    ├── datadog/                     # Datadog monitoring infrastructure
    │   ├── main.tf                  # Primary Datadog resources
    │   ├── monitor-backend.tf       # Backend monitoring
    │   ├── slack.tf                 # Slack integrations
    │   ├── locals.tf                # Local values
    │   ├── variables.tf             # Input variables
    │   ├── monitoring/              # Monitoring configurations
    │   │   ├── monitoring.yaml      # Main monitoring config
    │   │   └── services/            # Service-specific monitors
    │   └── templates/               # Monitoring templates
    ├── github/                      # GitHub organization/repository management
    │   ├── main.tf                  # GitHub resources
    │   ├── variables.tf             # Input variables
    │   └── outputs.tf               # Output values
    └── sentry/                      # Sentry error tracking infrastructure
        ├── main.tf                  # Primary Sentry resources
        ├── alert.tf                 # Alert configurations
        ├── integration.tf           # Third-party integrations
        ├── organization.tf          # Sentry org management
        ├── project.tf               # Project configurations
        ├── team.tf                  # Team management
        ├── locals.tf                # Local values
        ├── variables.tf             # Input variables
        └── monitoring/              # Monitoring configurations
```

### Terraform Execution Flow
- **Plan Execution**: Run on Pull Request creation/updates
  - Uses `terraform plan` to show infrastructure changes
  - Executes from workspace root or with `-chdir=terraform/infra/<provider>`
  - Configuration loaded from `terraform/config/<environment>.yml`
  
- **Apply Execution**: Run on merge to main branch
  - Uses `terraform apply` to implement changes
  - Auto-approval enabled for main branch merges
  - Environment-specific approval gates for production

## Git & Commit Message Standards (Udacity Style)

### Commit Message Format
Follow the Udacity Git Commit Message Style Guide:

```
type: Subject line (50 characters or less)

Optional body explaining what and why, not how.
Wrap to 72 characters per line.

Optional footer for issue references.
```

### Commit Types
- **feat:** A new feature (infrastructure component, module, resource)
- **fix:** A bug fix (resource configuration, policy correction)
- **docs:** Changes to documentation (README, comments, inline docs)
- **style:** Formatting changes (terraform fmt, whitespace, etc.)
- **refactor:** Code restructuring without functional changes
- **test:** Adding or modifying tests (terratest, validation scripts)
- **chore:** Maintenance tasks (dependency updates, tool configs)

### Subject Line Rules
- Maximum 50 characters
- Start with capital letter
- No period at the end
- Use imperative mood ("Add" not "Added" or "Adds")
- Be descriptive and specific

### Examples for Infrastructure Changes
```bash
# Good commit messages
feat: Add EKS cluster with managed node groups for staging
fix: Correct S3 bucket policy for CloudTrail logging
docs: Update README with new module usage examples
refactor: Extract VPC configuration into reusable module
chore: Update AWS provider version to 5.34.0

# Bad commit messages
feat: stuff
fix: fix bug
update: changes
```

### Jira Integration
When working on Jira tickets, include the ticket number in:

**Commit Messages:**
```bash
feat: Add monitoring for RDS instances [INFRA-123]

Implement CloudWatch alarms and Datadog monitors for RDS
performance metrics including CPU utilization, disk space,
and connection count.

Resolves: INFRA-123
```

**Branch Names:**
```bash
feature/INFRA-123-add-rds-monitoring
hotfix/INFRA-456-fix-s3-permissions
chore/INFRA-789-update-provider-versions
```

## Code Style & Formatting

### General Formatting
- **ALWAYS** run `terraform fmt -recursive` before committing
- Use 2-space indentation for all Terraform files
- Align equals signs when multiple arguments appear on consecutive lines
- Use empty lines to separate logical groups of arguments
- Place meta-arguments (count, for_each, lifecycle) first in resource blocks
- Separate top-level blocks with one blank line

### File Organization Standards
Each Terraform directory should follow this structure:
```
├── terraform.tf      # Version constraints and required providers
├── providers.tf      # Provider configurations
├── variables.tf      # Input variables (required first, optional last)
├── locals.tf         # Local values and computed expressions
├── data.tf           # Data sources
├── main.tf           # Primary resources or module calls
├── outputs.tf        # Output values
└── README.md         # Documentation
```

### Logical File Separation (for complex infrastructures)
- `network.tf` - VPC, subnets, security groups, load balancers
- `compute.tf` - EC2, ECS, EKS, Lambda, Auto Scaling
- `storage.tf` - S3, EBS, EFS, backup configurations
- `database.tf` - RDS, ElastiCache, DynamoDB
- `monitoring.tf` - CloudWatch, Datadog monitors, alarms
- `security.tf` - IAM roles, policies, KMS, certificates
- `dns.tf` - Route53 zones, records, health checks

## Variable and Configuration Management

### Variable Declaration Best Practices
```hcl
# Required variables (at top of variables.tf)
variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "region" {
  type        = string
  description = "AWS region for resource deployment"
  
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1)."
  }
}

# Optional variables (at bottom of variables.tf)
variable "instance_type" {
  type        = string
  description = "EC2 instance type for worker nodes"
  default     = "t3.medium"
  
  validation {
    condition = contains([
      "t3.small", "t3.medium", "t3.large",
      "m5.large", "m5.xlarge", "m5.2xlarge"
    ], var.instance_type)
    error_message = "Instance type must be from approved list."
  }
}

# Sensitive variables
variable "database_password" {
  type        = string
  description = "Master password for RDS instance"
  sensitive   = true
}
```

### Configuration File Management (`terraform/config/`)
Configuration files use YAML format and follow this pattern:
```yaml
# _defaults.yml - Shared defaults
common_tags:
  ManagedBy: "terraform"
  Project: "alwayz"
  Team: "platform"

backup_retention_days: 7
monitoring_enabled: true

# alwayz-aws-dev-infra.yml - Environment-specific overrides
environment: "dev"
region: "us-east-1"

vpc_cidr: "10.0.0.0/16"
availability_zones: ["us-east-1a", "us-east-1b"]

instance_type: "t3.small"
min_capacity: 1
max_capacity: 3

# Override tags for dev environment
common_tags:
  Environment: "dev"
  CostCenter: "engineering"
```

## Module Development Standards

### Module Design Principles
- **Single Responsibility**: Each module serves one clear purpose
- **Opinionated Defaults**: Provide sensible defaults for 80% use cases
- **Composition Over Inheritance**: Build complex infrastructure by combining simple modules
- **Environment Agnostic**: Modules should work across environments with input variables

### Module Interface Standards
```hcl
# Minimal required inputs (5-6 maximum)
variable "name" {
  type        = string
  description = "Name prefix for all resources in this module"
}

variable "environment" {
  type        = string
  description = "Environment name for resource tagging and naming"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where resources will be created"
}

# Optional inputs with sensible defaults
variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.medium"
}

variable "enable_monitoring" {
  type        = bool
  description = "Enable CloudWatch monitoring and alerting"
  default     = true
}

# Complex optional inputs
variable "additional_tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources"
  default     = {}
}
```

### Output Standards
```hcl
output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  sensitive   = false
}

# Sensitive outputs
output "database_connection_string" {
  description = "Database connection string with credentials"
  value       = "postgresql://${aws_db_instance.main.username}:${var.database_password}@${aws_db_instance.main.endpoint}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
  sensitive   = true
}
```

## Provider-Specific Best Practices

### AWS Provider Configuration
```hcl
terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.34"
    }
  }
  
  backend "remote" {
    organization = "levit"
    
    workspaces {
      name = var.workspace_name
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
}
```

### Datadog Provider Configuration
```hcl
terraform {
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.29"
    }
  }
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = "https://api.datadoghq.com/"
}
```

### Sentry Provider Configuration
```hcl
terraform {
  required_providers {
    sentry = {
      source  = "jianyuan/sentry"
      version = "~> 0.11"
    }
  }
}

provider "sentry" {
  token = var.sentry_auth_token
  base_url = "https://sentry.io/"
}
```

## Security & Compliance

### Secrets Management
- **NEVER** hardcode secrets in Terraform files
- Use AWS Secrets Manager or SSM Parameter Store for sensitive values
- Mark sensitive variables with `sensitive = true`
- Use random providers for generating passwords and keys

```hcl
# Good: Using AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "${var.environment}/rds/master-password"
}

# Good: Using random provider
resource "random_password" "db_password" {
  length  = 32
  special = true
  
  keepers = {
    db_instance_id = aws_db_instance.main.id
  }
}

# Good: Using SSM Parameter Store
data "aws_ssm_parameter" "api_key" {
  name            = "/${var.environment}/api-keys/external-service"
  with_decryption = true
}
```

### IAM Best Practices
- Follow principle of least privilege
- Use specific resource ARNs instead of wildcards
- Implement condition blocks for additional security
- Regular review and rotation of access keys

```hcl
# Good: Specific permissions with conditions
data "aws_iam_policy_document" "s3_access" {
  statement {
    effect = "Allow"
    
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    
    resources = [
      "${aws_s3_bucket.main.arn}/*"
    ]
    
    condition {
      test     = "StringEquals"
      variable = "s3:ExistingObjectTag/Environment"
      values   = [var.environment]
    }
  }
}
```

### Resource Tagging Strategy
```hcl
locals {
  common_tags = {
    Environment     = var.environment
    Project         = "alwayz"
    ManagedBy      = "terraform"
    Team           = var.team_name
    CostCenter     = var.cost_center
    BackupRequired = var.backup_required
    MonitoringLevel = var.monitoring_level
    CreatedDate    = timestamp()
    
    # Compliance tags
    DataClassification = var.data_classification
    ComplianceScope   = var.compliance_scope
  }
}

resource "aws_instance" "web" {
  # ... configuration ...
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-web-${var.environment}"
    Type = "web-server"
    BackupSchedule = "daily"
  })
}
```

## Validation & Testing

### Pre-commit Validation Pipeline
```bash
# Required validation before commit
terraform fmt -check -recursive
terraform validate
tflint --recursive
tfsec .
checkov -d . --framework terraform
```

### Testing Strategy
- Use Terratest for integration testing
- Test modules in isolation before integration
- Validate outputs match expected values
- Test disaster recovery procedures

### CI/CD Integration
- Validation runs on every PR
- Plan execution on PR creation/update
- Apply execution on merge to main
- Environment-specific approval gates

## Monitoring & Observability

### Infrastructure Monitoring
```hcl
# CloudWatch alarms for AWS resources
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.name}-high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    InstanceId = aws_instance.main.id
  }
  
  tags = local.common_tags
}

# Datadog monitors
resource "datadog_monitor" "high_error_rate" {
  name    = "[${var.environment}] High Error Rate - ${var.service_name}"
  type    = "metric alert"
  message = "Error rate is above threshold @slack-infrastructure"
  
  query = "avg(last_5m):avg:trace.http.request.errors{env:${var.environment},service:${var.service_name}} by {service} > 0.1"
  
  monitor_thresholds {
    warning  = 0.05
    critical = 0.1
  }
  
  tags = ["env:${var.environment}", "service:${var.service_name}", "team:platform"]
}
```

## Documentation Standards

### README Requirements
Every module and configuration must include:

```markdown
# Module/Configuration Name
Brief description of what this creates and its purpose.

## Architecture
High-level architecture diagram or description.

## Usage
```hcl
module "example" {
  source = "./modules/example"
  
  name        = "my-app"
  environment = "dev"
  vpc_id      = module.vpc.vpc_id
}
```

## Requirements
| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| aws | ~> 5.34 |

## Providers
| Name | Version |
|------|---------|
| aws | ~> 5.34 |

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Resource name prefix | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |

## Outputs
| Name | Description |
|------|-------------|
| cluster_id | EKS cluster identifier |

## Examples
See the [examples](./examples) directory for working examples.

## Contributing
1. Follow the established coding standards
2. Add tests for new functionality
3. Update documentation
4. Submit PR with detailed description
```

## Emergency Procedures

### Rollback Strategy
- Use Terraform state backup for emergency rollbacks
- Implement resource deletion protection for critical infrastructure
- Maintain environment promotion pipeline for safe deployments
- Document emergency contact procedures

### Incident Response
- Infrastructure changes during incidents require approval
- Use `terraform plan` to verify changes before apply
- Document all emergency changes in incident reports
- Post-incident review of infrastructure modifications

Remember: Infrastructure as Code is permanent and affects production systems. Always follow these practices to ensure reliability, security, and maintainability of the Alwayz infrastructure.
```

이제 PR 템플릿도 Jira 통합을 포함하도록 업데이트하겠습니다:

```markdown:.github/PULL_REQUEST_TEMPLATE.md
## Summary
<!-- Provide a brief description of what this PR accomplishes -->

## Jira Ticket
<!-- Link to the related Jira ticket -->
**Ticket:** [INFRA-XXX](https://levit.height.app/T-XXX)

## Type of Change
<!-- Mark the relevant option with an "x" -->
- [ ] 🚀 **feat:** New feature (infrastructure component, module, resource)
- [ ] 🐛 **fix:** Bug fix (resource configuration, policy correction)
- [ ] 📚 **docs:** Documentation changes (README, comments, inline docs)
- [ ] 🎨 **style:** Formatting changes (terraform fmt, whitespace)
- [ ] ♻️ **refactor:** Code restructuring without functional changes
- [ ] ✅ **test:** Adding or modifying tests (terratest, validation)
- [ ] 🔧 **chore:** Maintenance tasks (dependency updates, tool configs)

## Infrastructure Changes
<!-- Describe the infrastructure changes being made -->

### Resources Added/Modified/Removed
<!-- List the specific resources being changed -->
- [ ] AWS resources (specify which services: EC2, RDS, S3, etc.)
- [ ] Datadog monitors/dashboards
- [ ] Sentry projects/alerts
- [ ] GitHub repositories/settings

### Affected Environments
<!-- Mark which environments are affected -->
- [ ] Development (`alwayz-aws-dev-infra`)
- [ ] Staging (`alwayz-aws-staging-infra`)
- [ ] Production (`alwayz-aws-prod-infra`)
- [ ] Data Development (`aws-data-dev-infra`)
- [ ] Data Production (`aws-data-prod-infra`)
- [ ] Security Core (`security-aws-core-infra`)
- [ ] Security Production (`security-aws-prod-infra`)

## Configuration Changes
<!-- If modifying terraform/config/*.yml files -->
- [ ] Updated environment configuration files
- [ ] Modified default values in `_defaults.yml`
- [ ] Added new configuration parameters

## Testing
<!-- Describe how the changes were tested -->
- [ ] `terraform fmt -check -recursive` passed
- [ ] `terraform validate` passed  
- [ ] `tflint --recursive` passed
- [ ] `tfsec .` passed
- [ ] `terraform plan` reviewed and approved
- [ ] Integration tests (if applicable)

## Security Considerations
<!-- Address any security implications -->
- [ ] No sensitive data hardcoded in configuration
- [ ] IAM permissions follow least privilege principle
- [ ] Encryption enabled for data at rest and in transit
- [ ] Security groups follow restrictive access patterns
- [ ] No public access unless explicitly required

## Rollback Plan
<!-- Describe how to rollback these changes if needed -->
- [ ] Changes can be rolled back via Terraform
- [ ] No data migration required
- [ ] Dependencies documented
- [ ] Emergency contact procedures updated

## Documentation
<!-- Ensure proper documentation -->
- [ ] README updated (if applicable)
- [ ] Inline code comments added for complex logic
- [ ] Architecture diagrams updated (if applicable)
- [ ] Runbook/operational docs updated

## Breaking Changes
<!-- Mark if this introduces breaking changes -->
- [ ] This PR contains breaking changes
- [ ] Migration guide provided
- [ ] Stakeholders notified

<!-- If breaking changes, explain the impact and migration path -->

## Additional Notes
<!-- Any additional information, concerns, or considerations -->

---

## Checklist Before Requesting Review
- [ ] I have performed a self-review of my code
- [ ] I have followed the Udacity commit message style guide
- [ ] I have tested these changes in a development environment
- [ ] I have updated documentation as needed
- [ ] I have considered the security implications
- [ ] I have a rollback plan documented
- [ ] All CI checks are passing

## Reviewers
<!-- Tag relevant team members for review -->
@platform-team @devops-team

---
**Note:** This PR will trigger a `terraform plan` on the affected workspaces. The plan output will be commented on this PR automatically.
```

마지막으로 commit 메시지 예제와 브랜치 naming 가이드를 추가한 문서도 생성하겠습니다:

```markdown:.github/COMMIT_MESSAGE_GUIDE.md
# Git Commit Message Guide (Udacity Style)

This document outlines the commit message standards for the Alwayz Infrastructure repository.

## Format

```
type: Subject line (50 characters or less)

Optional body explaining what and why, not how.
Wrap to 72 characters per line.

Optional footer for issue references.
```

## Types

- **feat:** A new feature (infrastructure component, module, resource)
- **fix:** A bug fix (resource configuration, policy correction)
- **docs:** Changes to documentation (README, comments, inline docs)
- **style:** Formatting changes (terraform fmt, whitespace, etc.)
- **refactor:** Code restructuring without functional changes
- **test:** Adding or modifying tests (terratest, validation scripts)
- **chore:** Maintenance tasks (dependency updates, tool configs)

## Examples

### Infrastructure Changes
```bash
feat: Add EKS cluster with managed node groups [INFRA-123]

Implement production-ready EKS cluster with:
- Managed node groups for auto-scaling
- IRSA for pod-level permissions
- VPC CNI add-on for networking
- EBS CSI driver for persistent storage

Resolves: INFRA-123
```

```bash
fix: Correct S3 bucket policy for CloudTrail logging [INFRA-456]

Update bucket policy to allow CloudTrail service to write logs.
Previous policy was missing the necessary permissions for
the CloudTrail service principal.

Resolves: INFRA-456
```

### Configuration Changes
```bash
chore: Update Datadog provider version to 3.29 [INFRA-789]

Upgrade provider to support new monitor types and improve
reliability for synthetic tests.

Breaking changes handled by updating monitor configurations
to use new resource attributes.

Resolves: INFRA-789
```

### Documentation Updates
```bash
docs: Add troubleshooting guide for EKS connectivity

Include common issues and solutions for:
- kubectl connectivity problems
- IRSA permission errors
- Node group scaling issues
```

## Branch Naming

Use the following patterns for branch names:

### Feature Branches
```bash
feature/INFRA-123-add-eks-cluster
feature/INFRA-456-implement-datadog-monitoring
```

### Bug Fix Branches
```bash
fix/INFRA-789-s3-bucket-permissions
hotfix/INFRA-999-critical-security-patch
```

### Chore/Maintenance Branches
```bash
chore/INFRA-111-update-provider-versions
chore/INFRA-222-cleanup-unused-resources
```

### Documentation Branches
```bash
docs/update-readme-examples
docs/add-troubleshooting-guide
```

## Jira Integration

### In Commit Messages
Always include the Jira ticket number in square brackets:
```bash
feat: Add monitoring dashboards [INFRA-123]
```

### In Branch Names
Include the ticket number in the branch name:
```bash
feature/INFRA-123-monitoring-dashboards
```

### In Footer
Reference the ticket in the footer:
```bash
feat: Add monitoring dashboards [INFRA-123]

Implement comprehensive monitoring for all services
including error rates, latency, and availability metrics.

Resolves: INFRA-123
See also: INFRA-124, INFRA-125
```

## Best Practices

1. **Be Specific**: Clearly describe what changed and why
2. **Use Imperative Mood**: "Add" not "Added" or "Adds"
3. **Reference Issues**: Always link to relevant Jira tickets
4. **Explain Why**: Focus on the reason for the change, not just what changed
5. **Keep Subject Short**: 50 characters or less for the subject line
6. **Wrap Body Text**: 72 characters per line in the body

## Bad Examples

❌ **Too vague:**
```bash
fix: stuff
update: changes
feat: new thing
```

❌ **Too long subject:**
```bash
feat: Add comprehensive monitoring solution with Datadog integration including custom dashboards and alert management
```

❌ **No ticket reference:**
```bash
feat: Add EKS cluster
```

❌ **Wrong mood:**
```bash
feat: Added EKS cluster
feat: Adding EKS cluster
```

## Good Examples

✅ **Clear and specific:**
```bash
feat: Add EKS cluster with managed node groups [INFRA-123]
fix: Correct IAM permissions for RDS backup [INFRA-456]
docs: Update module usage examples in README
```

✅ **Proper formatting:**
```bash
feat: Implement blue-green deployment for API [INFRA-789]

Add Application Load Balancer target group switching to enable
zero-downtime deployments. Includes health checks and automatic
rollback on failure detection.

This reduces deployment risk and improves service availability
during updates.

Resolves: INFRA-789
Related: INFRA-790
```

Remember: Good commit messages help your team understand the history and context of changes, making maintenance and debugging much easier.
```

이제 모든 요구사항이 반영된 종합적인 룰셋이 완성되었습니다:

1. ✅ **Udacity 스타일 commit 메시지 컨벤션** - 상세한 가이드와 예제 포함
2. ✅ **프로젝트 디렉토리 구조** - terraform/infra/{aws,datadog,github,sentry}, terraform/config 구조 정의
3. ✅ **Terraform 실행 플로우** - PR에서 plan, merge에서 apply, -chdir 옵션 사용법 포함
4. ✅ **PR 템플릿 개선** - Jira 티켓 통합, 체크리스트, 보안 고려사항 포함
5. ✅ **추가 가이드** - commit 메시지와 브랜치 naming 상세 가이드

이 룰셋을 통해 팀 전체가 일관된 방식으로 인프라스트럭처 코드를 작성하고 관리할 수 있습니다. 