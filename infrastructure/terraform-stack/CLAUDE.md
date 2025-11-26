# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Terraform-based infrastructure-as-code repository that manages AWS infrastructure and Kubernetes resources for the Alwayz platform. It uses Terraform Cloud for state management and GitHub Actions for CI/CD automation.

## Key Commands

### Terraform Operations
```bash
# Set workspace before any operations (REQUIRED)
export TF_WORKSPACE=demo-aws-{ENVIRONMENT}-infra
# Examples: demo-aws-dev-infra, demo-aws-staging-infra, demo-aws-prod-infra

# Initialize Terraform
terraform -chdir=terraform/infra/aws init

# Plan changes (local verification only)
terraform -chdir=terraform/infra/aws plan

# Format code
terraform -chdir=terraform/infra/aws fmt

# Validate configuration
terraform -chdir=terraform/infra/aws validate

# Test Terraform functions
terraform -chdir=terraform/infra/aws console
```

### Important Notes
- **Apply is restricted**: `terraform apply` is blocked locally - all infrastructure changes must go through PR merge process
- **State management**: State files are managed in Terraform Cloud, not locally
- **Authentication**: Requires `terraform login` with API token stored in `~/.terraform.d/credentials.tfrc.json`

## Architecture Overview

### Directory Structure
- `terraform/infra/aws/` - Main AWS infrastructure definitions (VPC, EKS, RDS, etc.)
- `terraform/infra/datadog/` - Datadog monitoring configurations
- `terraform/infra/sentry/` - Sentry error tracking configurations
- `terraform/security/aws/` - Security-focused infrastructure (CloudTrail, SonarQube)
- `terraform/config/` - Environment-specific configuration files (.yml)
- `.github/workflows/` - GitHub Actions CI/CD pipelines
- `scripts/` - Utility scripts for operations and maintenance

### Core Infrastructure Components

#### EKS Cluster
- Module: `terraform-aws-modules/eks/aws` v19.15
- GitOps Bridge pattern with ArgoCD for Kubernetes deployments
- EKS Blueprints Addons for standard components (cert-manager, external-dns, AWS LB Controller, etc.)
- Karpenter for node autoscaling
- Multiple node groups with specific taints/tolerations

#### Networking
- Multi-zone VPC with public/private subnets
- VPC peering for cross-account/region connectivity
- VPC endpoints for AWS services
- Route53 for DNS management (public and private zones)

#### Data Layer
- RDS Aurora MySQL clusters with multi-AZ deployment
- ElastiCache Redis for caching
- S3 buckets for various storage needs
- ECR repositories for container images

#### Security & Compliance
- AWS Secrets Manager for sensitive data
- IAM roles with IRSA (IAM Roles for Service Accounts)
- CloudTrail for audit logging
- SonarQube for code quality analysis

### Terraform Cloud Integration
- Organization: `example-org`
- Workspaces tagged with: `["demo", "aws", "devops"]`
- Remote state management
- PR-based workflow:
  1. Create feature branch
  2. Open PR → triggers `terraform plan`
  3. Code review + approval
  4. Merge → triggers `terraform apply`

### Environment Management
Environments are managed through Terraform Cloud workspaces:
- Development: `demo-aws-dev-infra`
- Staging: `demo-aws-staging-infra`
- Production: `demo-aws-prod-infra`
- Security: `security-aws-core-infra`, `security-aws-prod-infra`
- Data: `aws-data-dev-infra`, `aws-data-prod-infra`

Each environment has corresponding:
- Config file in `terraform/config/`
- GitHub Actions workflow in `.github/workflows/`

### Key Terraform Patterns

#### Module Usage
- Heavy use of official AWS modules (eks, vpc, rds, etc.)
- Custom modules in `terraform/infra/aws/modules/` for specific needs
- Version pinning for all providers and modules

#### GitOps Bridge
- EKS addons managed declaratively but deployed via ArgoCD
- `create_kubernetes_resources = false` to skip Helm installations
- IAM roles and policies created by Terraform, used by GitOps

#### Configuration Management
- Environment-specific configs in YAML files
- Terraform locals for computed values and environment detection
- Extensive use of data sources for existing resources

### Critical Files
- `terraform/infra/aws/main.tf` - Provider configuration and Terraform Cloud setup
- `terraform/infra/aws/eks.tf` - EKS cluster definition
- `terraform/infra/aws/gitops-bridge.tf` - EKS Blueprints addons configuration
- `terraform/infra/aws/variables.tf` - Input variables and addon flags
- `terraform/infra/aws/locals.tf` - Computed values and environment detection