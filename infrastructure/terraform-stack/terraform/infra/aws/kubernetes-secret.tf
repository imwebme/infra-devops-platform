################################################################################
# GitOps Bridge: Private ssh keys for git
################################################################################
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  depends_on = [module.eks]
}

resource "kubernetes_secret" "git_secrets" {
  for_each = var.enable_git_ssh ? {
    git-addons = {
      type          = "git"
      url           = local.github_org
      sshPrivateKey = file(pathexpand(local.git_private_ssh_key))
    }
    git-workloads = {
      type          = "git"
      url           = local.github_org
      sshPrivateKey = file(pathexpand(local.git_private_ssh_key))
    }
  } : {}
  metadata {
    name      = each.key
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }
  data       = each.value
  depends_on = [kubernetes_namespace.argocd]
}


################################################################################
# GitOps Bridge: Repository connection using Credential templates
################################################################################
resource "kubernetes_secret" "git_repo_credential_templates" {
  metadata {
    name      = "repo-credential-templates"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }

  data = {
    username = var.gitops_org_username
    password = var.gitops_org_password
    url      = local.github_org
  }

  type       = "Opaque"
  depends_on = [kubernetes_namespace.argocd]
}


################################################################################
# GitOps Bridge: Credential of ArgoCD Vault Plugin
################################################################################
resource "kubernetes_secret" "argocd_vault_plugin_credentials" {
  metadata {
    name      = "argocd-vault-plugin-credentials"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  data = {
    AVP_TYPE   = "awssecretsmanager"
    AWS_REGION = var.region
  }

  type       = "Opaque"
  depends_on = [kubernetes_namespace.argocd]
}


################################################################################
# GitOps Bridge: Credential of ArgoCD Image Updater
################################################################################
resource "kubernetes_secret" "argocd_image_updater_credentials" {
  metadata {
    name      = "git-creds"
    namespace = kubernetes_namespace.argocd.metadata[0].name
  }

  data = {
    username = var.gitops_org_username
    password = var.gitops_org_password
  }

  type       = "Opaque"
  depends_on = [kubernetes_namespace.argocd]
}

################################################################################
# GitOps Bridge: In-cluster secret with dynamic metadata
################################################################################
resource "kubernetes_secret" "in_cluster" {
  metadata {
    name      = "in-cluster"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = merge(
      local.cluster_labels,
      {
        "argocd.argoproj.io/secret-type" = "cluster"
        "aws_cluster_name"               = module.eks.cluster_name
        "cluster_name"                   = "in-cluster"
        "environment"                    = local.env
        "kubernetes_version"             = var.kubernetes_version
      }
    )
    annotations = merge(
      local.cluster_metadata,
      {
        "cluster_name"       = "in-cluster"
        "environment"        = local.env
        "eks_cluster_domain" = local.domain
      }
    )
  }

  data = {
    name   = "in-cluster"
    server = "https://kubernetes.default.svc"
    config = <<-EOT
      {
        "tlsClientConfig": {
          "insecure": false
        }
      }
    EOT
  }

  type       = "Opaque"
  depends_on = [kubernetes_namespace.argocd]
}






