resource "aws_s3_bucket" "this" {
  for_each      = local.s3_configs_map
  bucket        = each.key
  force_destroy = true
  tags          = local.tags
  lifecycle { ignore_changes = [tags] }
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = local.s3_configs_map
  bucket   = aws_s3_bucket.this[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = local.s3_configs_map
  bucket   = aws_s3_bucket.this[each.key].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_cloudfront_distribution" "s3" {
  for_each = { for k, v in local.s3_configs_map : k => v if try(v.cloudfront.enabled, false) }

  origin {
    domain_name              = aws_s3_bucket.this[each.key].bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.sign_request.id
    origin_id                = each.key
  }

  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
      locations        = ["IR", "SY", "SD", "HK", "MO", "BY", "VE", "PK", "TR", "CN", "RU", "KP"]
    }
  }
  enabled             = true
  is_ipv6_enabled     = true
  comment             = each.key
  default_root_object = "index.html"
  http_version        = "http2"

  aliases = ["${each.key}.iexample-org.com"]

  default_cache_behavior {
    cache_policy_id        = data.aws_cloudfront_cache_policy.cache-optimized.id
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = each.key
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  price_class = "PriceClass_200"

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.iexample-org_wildcard.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = local.tags

  lifecycle { ignore_changes = [ordered_cache_behavior, web_acl_id, tags] }
}

resource "aws_s3_bucket_policy" "this" {
  for_each = { for k, v in local.s3_configs_map : k => v if try(v.cloudfront.enabled, false) }
  bucket   = aws_s3_bucket.this[each.key].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.this[each.key].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3[each.key].arn
          }
        }
      }
    ]
  })
}

resource "aws_route53_record" "s3_public" {
  for_each = { for k, v in local.s3_configs_map : k => v if try(v.cloudfront.enabled, false) && try(v.route53.public, true) }

  zone_id = data.aws_route53_zone.public_iexample-org_com.zone_id
  name    = "${each.key}.iexample-org.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3[each.key].domain_name
    zone_id                = aws_cloudfront_distribution.s3[each.key].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "s3_private" {
  for_each = { for k, v in local.s3_configs_map : k => v if try(v.cloudfront.enabled, false) && try(v.route53.private, true) }

  zone_id = data.aws_route53_zone.private_iexample-org_com.zone_id
  name    = "${each.key}.iexample-org.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3[each.key].domain_name
    zone_id                = aws_cloudfront_distribution.s3[each.key].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "this" {
  for_each = { for k, v in local.s3_configs_map : k => v if try(v.storage_class, null) == "INTELLIGENT_TIERING" }

  bucket = aws_s3_bucket.this[each.key].id
  name   = each.key
  status = "Enabled"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }
  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}
