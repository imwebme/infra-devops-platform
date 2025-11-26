################################################################################
# VPC Module
################################################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = local.prefix
  cidr = local.vpc_cidr

  azs            = local.azs
  public_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  private_subnets = concat(
    [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k + 4)],
    [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k + 8)]
  )
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 6, k + 48)]
  # elasticache_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 12)]
  # redshift_subnets    = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 16)]
  # intra_subnets       = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 20)]

  public_subnet_names = [for k, v in local.azs : join(":", [join("-", [local.prefix, "subnet", "public", "net"]), v])]
  private_subnet_names = concat(
    [for k, v in local.azs : join(":", [join("-", [local.prefix, "subnet", "private", "net"]), v])],
    [for k, v in local.azs : join(":", [join("-", [local.prefix, "subnet", "private", "eks"]), v])]
  )
  database_subnet_names = [for k, v in local.azs : join(":", [join("-", [local.prefix, "subnet", "private", "data"]), v])]

  create_database_subnet_group  = false
  manage_default_network_acl    = false
  manage_default_route_table    = false
  manage_default_security_group = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway     = local.nat_gateway.enabled
  single_nat_gateway     = local.nat_gateway.enabled && !local.nat_gateway.per_az
  one_nat_gateway_per_az = local.nat_gateway.enabled && local.nat_gateway.per_az

  enable_vpn_gateway = false

  enable_dhcp_options              = true
  dhcp_options_domain_name         = "ap-northeast-2.compute.internal"
  dhcp_options_domain_name_servers = ["AmazonProvidedDNS"]

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  enable_flow_log = false
  # create_flow_log_cloudwatch_log_group = true
  # create_flow_log_cloudwatch_iam_role  = true
  # flow_log_max_aggregation_interval    = 60

  tags = local.tags
  vpc_tags = {
    Name : join("-", [local.prefix, "vpc"]),
    Group : "ops-infra",
    NodeType : join("-", ["ops-infra", local.prefix, "vpc"]),
    Env : local.prefix
  }
  public_route_table_tags = {
    Name : join("-", [local.prefix, "rt", "public", "net"]),
    Group : "ops-infra",
    NodeType : join("-", ["ops-infra", local.prefix, "rt", "public", "net"]),
    Env : local.prefix
  }
  # private_route_table_tags = { Name : join("-", [local.prefix, "rt", "private", "net"]) }
  igw_tags = {
    Name : join("-", [local.prefix, "igw"]),
    Group : "ops-infra",
    NodeType : join("-", ["ops-infra", local.prefix, "igw"]),
    Env : local.prefix
  }
  nat_eip_tags = {
    Name : join("-", [local.prefix, "nat-eip"]),
    Group : "ops-infra",
    NodeType : join("-", ["ops-infra", local.prefix, "nat-eip"]),
    Env : local.prefix
  }
  nat_gateway_tags = {
    Name : join("-", [local.prefix, "nat-gateway"]),
    Group : "ops-infra",
    NodeType : join("-", ["ops-infra", local.prefix, "nat-gateway"]),
    Env : local.prefix
  }
  dhcp_options_tags = {
    Name : join("-", [local.prefix, "dhcp"]),
    Group : "ops-infra",
    NodeType : join("-", ["ops-infra", local.prefix, "dhcp"]),
    Env : local.prefix
  }
}
