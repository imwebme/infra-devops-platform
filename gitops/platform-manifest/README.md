# DevOps GitOps Manifest

A comprehensive GitOps repository for managing multi-cluster infrastructure addons and core workloads across EKS clusters.

## Overview

This repository serves as the central control plane for DevOps infrastructure management, providing:
- **Multi-cluster addon deployment** via ArgoCD ApplicationSets
- **Infrastructure-as-Code** for core services (cert-manager, ingress-nginx, monitoring)
- **Database workload management** (MongoDB, PostgreSQL, Redis)
- **Security tooling** (external-secrets, karpenter, robusta)

Built on the [GitOps Bridge](https://github.com/gitops-bridge-dev/gitops-bridge) framework.

## Repository Structure

### Core Directories

* **bootstraps/** - ArgoCD ApplicationSet definitions for automated deployment
  - `addons/` - Infrastructure addon ApplicationSets (helm-external, helm-internal, raw-internal)
  - `administrations/` - Administrative tools and global resources
  - `workloads/` - Database and application workload ApplicationSets

* **charts/** - Internal Helm charts for custom addons and workloads
  - `addons/` - Infrastructure addon charts
  - `workloads/` - Database and application charts

* **environments/** - Environment-specific base configurations
  - `base/` - Default values for all environments
  - Per-environment overrides for resource allocation and settings

* **configs/** - Cluster-specific configurations and values
  - `{cluster-name}/` - Individual cluster settings and overrides

* **clusters/** - Legacy cluster-specific resources (deprecated in favor of configs/)

* **global/** - Global resources (namespaces, CRDs, priority-classes)

## Cluster Architecture

**Supported Clusters:**
- `demo-dev-eks`, `demo-prod-eks` - Main application clusters
- `data-dev-eks`, `data-prod-eks` - Data processing clusters
- `security-prod-eks` - Security and compliance cluster

**ApplicationSet Pattern:**
- Cluster-specific deployment via `aws_cluster_name` matching
- Automated values file inheritance (base → environment → cluster)
- Priority-based resource allocation (core-addons > common-addons > monitoring-addons)

```
├── bootstraps/
│   ├── addons/
│   │   ├── addons-helm-external-appset.yaml
│   │   ├── addons-helm-internal-appset.yaml
│   │   └── addons-raw-internal-appset.yaml
│   ├── administrations/
│   │   ├── admins-appset.yaml
│   │   └── globals-appset.yaml
│   └── workloads/
│       ├── workloads-db-*-appset.yaml
│       └── workloads-helm-*-appset.yaml
├── charts/
│   ├── addons/
│   │   ├── aws-ebs-csi/
│   │   ├── prometheus-mongodb-exporter/
│   │   └── prometheus-pgbouncer-exporter/
│   └── workloads/
│       ├── base-cronjobs/
│       ├── db-cw-summary/
│       └── db-pgbouncer/
├── configs/
│   ├── demo-dev-eks/
│   ├── demo-prod-eks/
│   ├── data-dev-eks/
│   ├── data-prod-eks/
│   └── security-prod-eks/
├── environments/
│   └── base/
│       ├── addons/
│       └── workloads/
├── global/
│   ├── namespaces/
│   ├── priority-classes/
│   └── storage-class/
└── scripts/
    └── automation tools
```

## Getting Started

### Prerequisites
- ArgoCD installed in control plane cluster
- Cluster labels configured with `aws_cluster_name`
- External Secrets Operator for secret management

### Deployment

1. **Bootstrap ArgoCD ApplicationSets:**
   ```bash
   kubectl apply -f bootstraps/addons/
   kubectl apply -f bootstraps/workloads/
   ```

2. **Verify ApplicationSet Creation:**
   ```bash
   kubectl get applicationset -n argocd
   ```

3. **Monitor Application Deployment:**
   ```bash
   kubectl get application -n argocd
   ```

### Adding New Addons

1. Create Helm chart in `charts/addons/{addon-name}/`
2. Add base values in `environments/base/addons/{addon-name}.yaml`
3. Configure cluster-specific values in `configs/{cluster}/addons/{addon-name}.yaml`
4. ApplicationSet will automatically deploy to matching clusters

## Monitoring & Troubleshooting

- **ApplicationSet Status:** `kubectl describe applicationset -n argocd`
- **Application Sync Status:** `argocd app list`
- **Resource Health:** `argocd app get {app-name}`

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

This DevOps GitOps manifest was designed and implemented by Kim YongHyun and Kim YoungJae for multi-cluster infrastructure addon and workload management.