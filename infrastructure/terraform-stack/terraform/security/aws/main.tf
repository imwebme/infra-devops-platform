terraform {
  cloud {
    organization = "example-org"
    hostname = "app.terraform.io"
    workspaces {
      name = "security-aws-core-infra"
    }
  }
}

locals {
  config = yamldecode(file("${path.module}/../../config/security-aws-core-infra.yml"))
  prefix = join("-", compact([local.config.org, local.config.category, local.config.env]))

  # 동적 태그 생성
  common_tags = merge(
    var.tags,
    {
      Name        = "${local.prefix}-cloudtrail"
      Environment = var.environment
      CostCenter  = "security-${var.environment}"
    }
  )
}

module "cloudtrail" {
  source = "./cloudtrail"

  name                          = "cloudtrail-trails-for-s3"
  s3_bucket_name                = local.config.cloudtrail.s3_bucket_name
  enable_logging                = true
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  # Slack 알림 관련 변수
  enable_slack_notification      = true
  cloudtrail_slack_webhook_url   = var.cloudtrail_slack_webhook_url
  slack_channel                  = "#aws-security-alerts"

  tags = local.common_tags
}

module "sonarqube" {
  source = "./sonarqube"

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-sonarqube"
  })
}
