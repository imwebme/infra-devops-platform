# ACM certificates - only create when EKS is enabled (Phase 2+)
resource "aws_acm_certificate" "domain" {
  count             = try(local.config.eks.enabled, false) ? 1 : 0
  domain_name       = join("", ["*.", module.public_zones.route53_zone_name["${local.domain}"]])
  validation_method = "DNS"

  subject_alternative_names = ["*.${local.domain}"]

  tags = {}

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [module.public_zones, module.private_zones]
}

resource "aws_route53_record" "domain_cert_validation" {
  for_each = try(local.config.eks.enabled, false) ? {
    for dvo in aws_acm_certificate.domain[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id = module.public_zones.route53_zone_zone_id["${local.domain}"]
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "domain" {
  count                   = try(local.config.eks.enabled, false) ? 1 : 0
  certificate_arn         = aws_acm_certificate.domain[0].arn
  validation_record_fqdns = [for record in aws_route53_record.domain_cert_validation : record.fqdn]
}

resource "aws_acm_certificate" "domain_us_east_1" {
  count             = try(local.config.eks.enabled, false) ? 1 : 0
  provider          = aws.virginia
  domain_name       = join("", ["*.", module.public_zones.route53_zone_name["${local.domain}"]])
  validation_method = "DNS"

  subject_alternative_names = ["*.${local.domain}"]

  tags = {}

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [module.public_zones, module.private_zones]
}

resource "aws_acm_certificate_validation" "domain_us_east_1" {
  count                   = try(local.config.eks.enabled, false) ? 1 : 0
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.domain_us_east_1[0].arn
  validation_record_fqdns = [for record in aws_route53_record.domain_cert_validation : record.fqdn]
}