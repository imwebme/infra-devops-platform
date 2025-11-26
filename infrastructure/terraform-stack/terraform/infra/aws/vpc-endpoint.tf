resource "aws_vpc_endpoint" "this" {
  # for_each = try(local.vpc_endpoints[data.aws_region.current.name], {})
  for_each = { for k, v in lookup(local.vpc_endpoints, data.aws_region.current.name, {}) : k => v if length(lookup(local.vpc_endpoints, data.aws_region.current.name, {})) > 0 }

  vpc_id              = module.vpc.vpc_id
  service_name        = each.value.service_name
  vpc_endpoint_type   = each.value.type
  private_dns_enabled = each.value.private_dns_enabled

  # Interface 타입: ENI 생성 + private DNS 사용 (라우팅 테이블 불필요)
  subnet_ids         = each.value.type == "Interface" ? each.value.subnet_ids : []
  security_group_ids = each.value.type == "Interface" ? [module.eks.node_security_group_id] : []

  # Gateway 타입: 라우팅 테이블 규칙 필요 (S3, DynamoDB 등)
  route_table_ids = each.value.type == "Gateway" ? concat(module.vpc.private_route_table_ids, module.vpc.public_route_table_ids) : []
  auto_accept     = true

  tags = {
    Name = format("%s-%s_%s", local.prefix, "vpc-endpoint", each.key)
  }
}

# Datadog VPC Endpoints in us-east-1 (Cross-region)
resource "aws_vpc_endpoint" "datadog_virginia" {
  provider = aws.virginia
  for_each = try(local.config.datadog_private_link.enabled, false) && local.category == "security" && local.env == "prod" ? lookup(local.vpc_endpoints, "us-east-1", {}) : {}

  vpc_id              = data.aws_vpc.virginia.id
  service_name        = each.value.service_name
  vpc_endpoint_type   = each.value.type
  private_dns_enabled = each.value.private_dns_enabled

  # Interface 타입: ENI 생성 (Datadog VPC의 실제 운영 subnet/SG 사용)
  subnet_ids = each.value.type == "Interface" ? [
    "subnet-03a8cc22", "subnet-203a136d", "subnet-750e5d7b",
    "subnet-83933eb2", "subnet-9ade47fc", "subnet-9b9903c4"
  ] : []
  security_group_ids = each.value.type == "Interface" ? ["sg-8bec6e87"] : []

  auto_accept = true

  tags = {
    Name = format("%s-datadog-vpc-endpoint-%s", local.prefix, each.key)
    Type = "datadog-private-link"
  }
}
