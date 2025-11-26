data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# Find the user currently in use by AWS
data "aws_caller_identity" "current" {}

data "aws_route53_zone" "secondary_level_domain" {
  name = local.secondary_level_domain
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

data "aws_kms_key" "s3-cloudfront-kms" {
  key_id = "d82113e7-037a-4e1d-84eb-5ce8244d1e3e"
}

data "aws_cloudfront_cache_policy" "cache-optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_acm_certificate" "iexample-org_wildcard" {
  provider    = aws.virginia
  domain      = "*.iexample-org.com"
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_route53_zone" "public_iexample-org_com" {
  name         = "iexample-org.com"
  private_zone = false
}

data "aws_route53_zone" "private_iexample-org_com" {
  name         = "iexample-org.com"
  private_zone = true
}

# 기존 VPC 데이터
data "aws_vpc" "default" {
  default = true
}

# Datadog VPC (us-east-1)
data "aws_vpc" "virginia" {
  provider = aws.virginia
  id       = "vpc-b52882c8"
}