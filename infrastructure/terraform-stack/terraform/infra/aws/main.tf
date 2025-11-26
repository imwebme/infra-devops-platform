# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {

  cloud {
    organization = "imwebme"

    hostname = "app.terraform.io"
    workspaces {
      tags = ["imweb", "aws", "security"]
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.87.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.22.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
    bcrypt = {
      source  = "viktorradnai/bcrypt"
      version = ">= 0.1.2"
    }
    argocd = {
      source  = "oboukili/argocd"
      version = "6.0.3"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0.2"
    }
  }
  required_version = "~> 1.9.8"
}

provider "aws" {
  region = "ap-northeast-2"

  // This is necessary so that tags required for eks can be applied to the vpc without changes to the vpc wiping them out.
  // https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/resource-tagging
  ignore_tags {
    key_prefixes = [
      "kubernetes.io/",
      "karpenter.sh/",
      "for-use-with-amazon-emr-managed-policies"
    ]
  }

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Env         = local.prefix
      Environment = local.env
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

/*
The following 2 data resources are used get around the fact that we have to wait
for the EKS cluster to be initialised before we can attempt to authenticate.
*/

# data "aws_eks_cluster" "default" {
#   name = module.eks.cluster_name

#   depends_on = [module.eks]
# }

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.kubernetes.token
}

provider "argocd" {
  port_forward_with_namespace = "argocd"
  username                    = "admin"
  password                    = random_password.argocd_admin_password.result
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.argocd.token
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.helm.token
  }
}

provider "kubectl" {
  apply_retry_count      = 10
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false
  token                  = data.aws_eks_cluster_auth.kubectl.token
}
