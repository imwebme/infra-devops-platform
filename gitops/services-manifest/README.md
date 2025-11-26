# Alwayz GitOps Manifest

GitOps repository for managing Alwayz service applications across multiple environments with automated deployment and configuration management.

## Overview

This repository provides:
- **Application Deployment**: Automated deployment of Alwayz services (API, BFF, Admin)
- **Environment Management**: Unified configuration across dev, staging, and prod
- **ECR Integration**: Automatic image updates via ArgoCD Image Updater
- **Slack Notifications**: Real-time deployment status alerts

Built on the [GitOps Bridge](https://github.com/gitops-bridge-dev/gitops-bridge) framework.

## Repository Structure

### Core Directories

* **bootstraps/** - ArgoCD ApplicationSet definitions
  - `workloads-demo-services-helm-appset.yaml` - Main business applications
  - `workloads-demo-scrapers-helm-appset.yaml` - Data collection services
  - `workloads-demo-cronjobs-helm-appset.yaml` - Batch jobs and scheduled tasks

* **charts/** - Helm charts for Alwayz applications
  - `workloads/` - Service deployment templates and common configuration patterns

* **environments/** - Environment-specific configurations
  - `base/` - Default values and common settings
  - `{env}/` - Environment-specific overrides (dev, staging, prod)

* **configs/** - Service-specific configurations
  - `{env}/workloads/` - Per-environment service definitions
  - ECR repository mappings and deployment settings

* **global/** - Global resources
  - `namespaces/` - Namespace definitions (demo-services, demo-scrapers, demo-cronjobs)
  - `priority-classes/` - Pod priority configurations
  - `service-accounts/` - Service account definitions

## Service Architecture

**Namespaces:**
- `demo-services` - Main business applications (API, BFF, Admin)
- `demo-scrapers` - Data collection and processing services
- `demo-cronjobs` - Batch jobs and scheduled tasks

**Deployment Features:**
- **Auto Image Updates**: ECR tag pattern matching (`^\\d+.*-.*$`)
- **Resource Optimization**: Environment-specific resource allocation
- **HPA Integration**: Horizontal Pod Autoscaling based on CPU/memory
- **Ingress Management**: ALB integration with external-dns

```
├── bootstraps/
│   ├── workloads-demo-services-helm-appset.yaml
│   ├── workloads-demo-scrapers-helm-appset.yaml
│   ├── workloads-demo-cronjobs-helm-appset.yaml
│   ├── addons-helm-external-appset.yaml
│   └── addons-helm-internal-appset.yaml
├── charts/
│   └── workloads/
│       ├── base-helm/
│       ├── base-cronjobs/
│       └── base-scraper/
├── configs/
│   ├── dev/
│   │   ├── addons/
│   │   └── workloads/
│   ├── staging/
│   │   ├── addons/
│   │   └── workloads/
│   └── prod/
│       ├── addons/
│       └── workloads/
├── environments/
│   ├── base/
│   │   └── workloads/
│   ├── dev/
│   │   ├── addons/
│   │   └── workloads/
│   ├── staging/
│   │   └── workloads/
│   └── prod/
│       └── workloads/
├── global/
│   ├── namespaces/
│   ├── priority-classes/
│   └── service-accounts/
└── scripts/
    └── automation tools
```

## Adding New Services

### 1. Service Definition
Create service configuration in `configs/{env}/workloads/demo-services/{service-name}.yaml`:

```yaml
application_name: my-service
chart_name: my-service
chart_version: 0.0.1
slack_channel: C082JSFBL7L
type: active  # active, batch, worker
source: nodejs
source_repo: https://github.com/wetripod/my-service
```

### 2. Base Values
Add default configuration in `environments/base/workloads/demo-services/{service-name}-values.yaml`:

```yaml
deployment:
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi
  port: 3000

hpa:
  enabled: true
  minReplicas: 1
  maxReplicas: 3
```

### 3. Environment-Specific Values
Configure per-environment settings in `environments/{env}/workloads/demo-services/{type}/{service-name}-values.yaml`

## Monitoring & Alerts

- **Slack Integration**: Deployment notifications via configured channels
- **ArgoCD Dashboard**: Application status and sync history
- **Datadog APM**: Application performance monitoring
- **Resource Monitoring**: HPA metrics and resource utilization

## License & Copyright

Copyright (c) 2024 **Kim YongHyun** (https://github.com/hulkong) and **Developer 2**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Authors

Created and maintained by:
- **Developer 1**
  - GitHub: [@hulkong](https://github.com/hulkong)
  - Email: cdfgogo0615@naver.com
  - Phone: 010-2763-9988
- **Developer 2**
  - GitHub: [@kimyoungjae96](https://github.com/kimyoungjae96)
  - Email: sskim5421@gmail.com
  - Phone: 010-5427-8851

### Acknowledgments

This Alwayz service GitOps manifest was designed and implemented by Kim YongHyun and Kim YoungJae for application deployment and management.