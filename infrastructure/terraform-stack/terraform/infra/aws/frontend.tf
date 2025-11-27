resource "aws_s3_bucket" "demo-frontend" {
  for_each = toset(local.frontend_service_names)
  bucket   = format("%s-%s", each.key, local.env)

  force_destroy = true

  tags = local.tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_s3_bucket_policy" "demo-frontend_policy" {
  for_each = toset(local.frontend_service_names)
  bucket   = aws_s3_bucket.demo-frontend[each.key].id

  depends_on = [aws_s3_bucket_website_configuration.demo-frontend-configuration]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.demo-frontend[each.key].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution[each.key].arn
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:user/deploy-api"
        }
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.demo-frontend[each.key].arn,
          "${aws_s3_bucket.demo-frontend[each.key].arn}/*"
        ]
      }
    ]
  })
  lifecycle { ignore_changes = [policy] }
}

resource "aws_s3_bucket_lifecycle_configuration" "demo-frontend-lifecycle" {
  for_each = toset(local.frontend_service_names)
  bucket   = aws_s3_bucket.demo-frontend[each.key].id

  rule {
    id     = "delete-old-files"
    status = "Enabled"


    filter {
      prefix = "" # 모든 파일에 대해 적용
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

resource "aws_s3_bucket_website_configuration" "demo-frontend-configuration" {
  for_each = toset(local.frontend_service_names)
  bucket   = aws_s3_bucket.demo-frontend[each.key].id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_versioning" "demo-frontend-versioning" {
  for_each = toset(local.frontend_service_names)
  bucket   = aws_s3_bucket.demo-frontend[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse-kms" {
  for_each = toset(local.frontend_service_names)
  bucket   = aws_s3_bucket.demo-frontend[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = try(data.aws_kms_key.s3-cloudfront-kms[0].arn, "")
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled = true
  }
}



resource "aws_cloudfront_distribution" "s3_distribution" {
  for_each = toset(local.frontend_service_names)

  origin {
    domain_name              = aws_s3_bucket.demo-frontend[each.key].bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.sign_request.id
    origin_id                = format("%s-%s", each.key, local.env)
  }

  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
      locations        = ["IR", "SY", "SD", "HK", "MO", "BY", "VE", "PK", "TR", "CN", "RU", "KP"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${each.key} ${local.env}"
  default_root_object = "index.html"
  http_version        = "http2"

  aliases = ["${each.key}.${local.env}.iexample-org.com"]

  default_cache_behavior {
    cache_policy_id  = data.aws_cloudfront_cache_policy.cache-optimized.id
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = format("%s-%s", each.key, local.env)

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  price_class = "PriceClass_200"

  custom_error_response {
    error_code            = 403
    error_caching_min_ttl = 360000
    response_page_path    = "/"
    response_code         = 200
  }

  custom_error_response {
    error_code            = 404
    error_caching_min_ttl = 360000
    response_page_path    = "/"
    response_code         = 200
  }

  viewer_certificate {
    acm_certificate_arn      = try(aws_acm_certificate.domain_us_east_1[0].arn, "")
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [ordered_cache_behavior, web_acl_id, tags]
  }

}

resource "aws_route53_record" "route53_frontend" {
  for_each = toset(local.frontend_service_names)

  # zone_id = data.aws_route53_zone.local-domain[0].zone_id
  zone_id = module.public_zones.route53_zone_zone_id["${local.domain}"]
  name    = "${each.key}.${local.env}.iexample-org.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution[each.key].domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution[each.key].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "route53_frontend_private" {
  for_each = toset(local.frontend_service_names)

  zone_id = module.private_zones.route53_zone_zone_id["${local.domain}"]
  name    = "${each.key}.${local.env}.iexample-org.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution[each.key].domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution[each.key].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_origin_access_control" "sign_request" {
  name                              = local.cloudfront["origin_access_controls"]
  description                       = ""
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
