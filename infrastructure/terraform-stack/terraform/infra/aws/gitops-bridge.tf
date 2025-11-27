################################################################################
# EKS Blueprints Addons
################################################################################
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Using GitOps Bridge (Skip Helm Install in Terraform)
  create_kubernetes_resources = false

  # EKS Blueprints Addons
  enable_cert_manager                 = var.addons.enable_cert_manager
  enable_aws_efs_csi_driver           = var.addons.enable_aws_efs_csi_driver
  enable_aws_fsx_csi_driver           = var.addons.enable_aws_fsx_csi_driver
  enable_aws_cloudwatch_metrics       = var.addons.enable_aws_cloudwatch_metrics
  enable_aws_privateca_issuer         = var.addons.enable_aws_privateca_issuer
  enable_cluster_autoscaler           = var.addons.enable_cluster_autoscaler
  enable_external_dns                 = var.addons.enable_external_dns
  enable_external_secrets             = var.addons.enable_external_secrets
  enable_aws_load_balancer_controller = var.addons.enable_aws_load_balancer_controller
  enable_fargate_fluentbit            = var.addons.enable_fargate_fluentbit
  enable_aws_for_fluentbit            = var.addons.enable_aws_for_fluentbit
  enable_aws_node_termination_handler = var.addons.enable_aws_node_termination_handler
  enable_karpenter                    = var.addons.enable_karpenter
  enable_velero                       = var.addons.enable_velero
  enable_aws_gateway_api_controller   = var.addons.enable_aws_gateway_api_controller

  karpenter = {
    repository_username = data.aws_ecrpublic_authorization_token.token.user_name
    repository_password = data.aws_ecrpublic_authorization_token.token.password
  }
  karpenter_enable_spot_termination          = true
  karpenter_enable_instance_profile_creation = true
  karpenter_node = {
    iam_role_use_name_prefix = false
  }

  external_dns_route53_zone_arns = try(local.config.eks.enabled, false) ? [
    module.public_zones.route53_zone_zone_arn["${local.domain}"],
    module.private_zones.route53_zone_zone_arn["${local.domain}"]
  ] : []

  tags = local.tags
}

locals {

  cluster_metadata = merge(
    module.eks_blueprints_addons.gitops_metadata,
    {
      aws_cluster_name = module.eks.cluster_name
      aws_region       = var.region
      aws_account_id   = data.aws_caller_identity.current.account_id
      aws_vpc_id       = module.vpc.vpc_id
    },
    {
      eks_cluster_domain = local.domain,
      environment        = local.env
    }
  )

  cluster_labels = merge(
    var.addons,
    { environment = local.env },
    { kubernetes_version = var.kubernetes_version },
    { aws_cluster_name = module.eks.cluster_name }
  )

}

################################################################################
# GitOps Bridge: Metadata for GitOps (ArgoCD installation moved to GitHub Workflow)
################################################################################
# Note: ArgoCD installation is now handled by GitHub Workflow
# This section only provides metadata for GitOps configuration
