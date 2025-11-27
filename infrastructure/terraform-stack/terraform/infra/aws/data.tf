data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# Find the user currently in use by AWS
data "aws_caller_identity" "current" {}

# Only lookup if we have external DNS zone to reference (not for new accounts)
data "aws_route53_zone" "secondary_level_domain" {
  count = try(local.config.lookup_existing_route53_zone, false) ? 1 : 0
  name  = local.secondary_level_domain
}

data "aws_eks_cluster_auth" "kubernetes" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "argocd" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "helm" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "kubectl" {
  name = module.eks.cluster_name
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

data "aws_subnets" "public_net" {

  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*public-net*"]
  }

  depends_on = [module.vpc.public_subnets]
}

data "aws_subnets" "private_net" {

  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private-net*"]
  }

  depends_on = [module.vpc.private_subnets]
}

data "aws_subnets" "private_eks" {

  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private-eks*"]
  }

  depends_on = [module.vpc.private_subnets]
}

data "aws_subnets" "private_eks_abc_zones" {

  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private-eks*"]
  }
  filter {
    name   = "availability-zone"
    values = ["${data.aws_region.current.name}a", "${data.aws_region.current.name}b", "${data.aws_region.current.name}c"]
  }

  depends_on = [module.vpc.private_subnets]
}

data "aws_subnets" "private_data" {

  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private-data*"]
  }

  depends_on = [module.vpc.private_subnets]
}

# Only lookup KMS key for accounts that have it (demo environments)
data "aws_kms_key" "s3-cloudfront-kms" {
  count  = try(local.config.lookup_existing_kms_key, false) ? 1 : 0
  key_id = try(local.config.kms_key_id, "d82113e7-037a-4e1d-84eb-5ce8244d1e3e")
}

data "aws_cloudfront_cache_policy" "cache-optimized" {
  name = "Managed-CachingOptimized"
}

# Only lookup demo ACM certificate for demo accounts
data "aws_acm_certificate" "iexample-org_wildcard" {
  count       = try(local.config.lookup_demo_resources, false) ? 1 : 0
  provider    = aws.virginia
  domain      = "*.iexample-org.com"
  statuses    = ["ISSUED"]
  most_recent = true
}

# Only lookup demo Route53 zones for demo accounts
data "aws_route53_zone" "public_iexample-org_com" {
  count        = try(local.config.lookup_demo_resources, false) ? 1 : 0
  name         = "iexample-org.com"
  private_zone = false
}

data "aws_route53_zone" "private_iexample-org_com" {
  count        = try(local.config.lookup_demo_resources, false) ? 1 : 0
  name         = "iexample-org.com"
  private_zone = true
}

# 기존 VPC 데이터 (only if default VPC exists)
data "aws_vpc" "default" {
  count   = try(local.config.lookup_default_vpc, false) ? 1 : 0
  default = true
}

# Datadog VPC (us-east-1) - only for demo accounts with Datadog private link
data "aws_vpc" "virginia" {
  count    = try(local.config.lookup_demo_resources, false) ? 1 : 0
  provider = aws.virginia
  id       = try(local.config.virginia_vpc_id, "vpc-b52882c8")
}