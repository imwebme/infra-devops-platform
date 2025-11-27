module "public_zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 2.0"

  zones = local.route53_public_zones

  tags = {
    zone = "public"
  }
}

# Create NS record in parent zone to delegate subdomain (only when parent zone exists)
resource "aws_route53_record" "public_nameserver" {
  count           = try(local.config.lookup_existing_route53_zone, false) ? 1 : 0
  allow_overwrite = false
  name            = module.public_zones.route53_zone_name["${local.domain}"]
  ttl             = 300
  type            = "NS"
  zone_id         = data.aws_route53_zone.secondary_level_domain[0].id

  records = module.public_zones.route53_zone_name_servers["${local.domain}"]

  depends_on = [module.public_zones]
}


module "private_zones" {
  source = "./modules/zones"

  zones = local.route53_private_zones

  tags = {
    zone = "private"
  }
}

# 1. Datadog private zones - Cross-environment VPC associations (security-prod에서만)
resource "aws_route53_zone_association" "datadog_vpc_association_cross_env" {
  for_each = local.category == "security" && local.env == "prod" && try(local.config.datadog_private_link.enabled, false) ? {
    for combination in flatten([
      for domain in local.datadog_domains : [
        for vpc_id in local.datadog_associated_vpc_ids : {
          domain = domain
          vpc_id = vpc_id
        }
      ]
    ]) : "${combination.domain}-${combination.vpc_id}" => combination
  } : {}

  zone_id    = module.private_zones.route53_zone_zone_id[each.value.domain]
  vpc_id     = each.value.vpc_id
  vpc_region = "ap-northeast-2"
}

# 2. Datadog private zones - Security-prod VPC association (security-prod에서만)
resource "aws_route53_zone_association" "datadog_vpc_association" {
  for_each = local.category == "security" && local.env == "prod" && try(local.config.datadog_private_link.enabled, false) ? {
    for domain in local.datadog_domains : domain => {
      domain = domain
      vpc_id = module.vpc.vpc_id
    }
  } : {}

  zone_id    = module.private_zones.route53_zone_zone_id[each.value.domain]
  vpc_id     = each.value.vpc_id
  vpc_region = "ap-northeast-2"
}

# 3. 환경별 private zones - 현재 환경 VPC와 1:1 association (모든 환경에서)
resource "aws_route53_zone_association" "env_specific_vpc_association" {
  for_each = contains(keys(module.private_zones.route53_zone_zone_id), local.current_env_domain) ? {
    "${local.current_env_domain}" = {
      domain = local.current_env_domain
      vpc_id = module.vpc.vpc_id
    }
  } : {}

  zone_id    = module.private_zones.route53_zone_zone_id[each.value.domain]
  vpc_id     = each.value.vpc_id
  vpc_region = "ap-northeast-2"
}

# 4. Datadog VPC Endpoint와 Route53 레코드 연결 (security-prod에서만)
resource "aws_route53_record" "datadog_vpc_endpoint_records" {
  for_each = try(local.config.datadog_private_link.enabled, false) && local.category == "security" && local.env == "prod" ? {
    for domain, endpoint_key in {
      "agent-http-intake.logs.datadoghq.com" = "agent-http-intake.logs"
      "http-intake.logs.datadoghq.com"       = "http-intake.logs"
      "api.datadoghq.com"                    = "api"
      "metrics.agent.datadoghq.com"          = "metrics.agent"
      "orchestrator.datadoghq.com"           = "orchestrator"
      "process.datadoghq.com"                = "process"
      "intake.profile.datadoghq.com"         = "intake.profile"
      "trace.agent.datadoghq.com"            = "trace.agent"
      "dbm-metrics-intake.datadoghq.com"     = "dbm-metrics-intake"
      "config.datadoghq.com"                 = "config"
    } : domain => endpoint_key
    # Datadog Virginia VPC endpoint가 실제로 존재하는 경우에만 포함
    if contains(keys(aws_vpc_endpoint.datadog_virginia), endpoint_key)
  } : {}

  zone_id = module.private_zones.route53_zone_zone_id[each.key]
  name    = each.key
  type    = "A"

  alias {
    name                   = aws_vpc_endpoint.datadog_virginia[each.value].dns_entry[0].dns_name
    zone_id                = aws_vpc_endpoint.datadog_virginia[each.value].dns_entry[0].hosted_zone_id
    evaluate_target_health = true
  }

  depends_on = [module.private_zones, aws_vpc_endpoint.datadog_virginia]
}