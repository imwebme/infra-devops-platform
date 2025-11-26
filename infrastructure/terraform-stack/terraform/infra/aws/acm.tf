resource "aws_acm_certificate" "domain" {
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
  for_each = {
    for dvo in aws_acm_certificate.domain.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = module.public_zones.route53_zone_zone_id["${local.domain}"]
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "domain" {
  certificate_arn         = aws_acm_certificate.domain.arn
  validation_record_fqdns = [for record in aws_route53_record.domain_cert_validation : record.fqdn]
}

resource "aws_acm_certificate" "domain_us_east_1" {
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
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.domain_us_east_1.arn
  validation_record_fqdns = [for record in aws_route53_record.domain_cert_validation : record.fqdn]
}