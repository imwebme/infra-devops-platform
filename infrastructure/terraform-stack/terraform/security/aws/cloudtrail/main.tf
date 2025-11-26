provider "aws" {
  region = var.region
}

locals {
  account_id            = "123456789012"
  region                = "ap-northeast-2"
  trail_name            = var.name
  cloudtrail_source_arn = "arn:aws:cloudtrail:${local.region}:${local.account_id}:trail/${local.trail_name}"
  tags                  = merge(var.tags, var.cloudtrail_tags)
}

# Resource for existing S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail" {
  bucket = var.s3_bucket_name
  tags   = local.tags

  # Import existing S3 bucket
  # terraform import aws_s3_bucket.cloudtrail <bucket-name>
}

# Ensure bucket policy allows CloudTrail to write logs
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck20150319"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = "arn:aws:s3:::${var.s3_bucket_name}"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = local.cloudtrail_source_arn
          }
        }
      },
      {
        Sid       = "AWSCloudTrailWrite20150319"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::${var.s3_bucket_name}/AWSLogs/${local.account_id}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = local.cloudtrail_source_arn
            "s3:x-amz-acl"  = "bucket-owner-full-control"
          }
        }
      }
    ]
  })

  # Import existing bucket policy
  # terraform import aws_s3_bucket_policy.cloudtrail <bucket-name>
}

# Resource for existing CloudTrail trail
resource "aws_cloudtrail" "main" {
  name                          = local.trail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = var.include_global_service_events
  is_multi_region_trail         = var.is_multi_region_trail
  enable_logging                = var.enable_logging
  enable_log_file_validation    = var.enable_log_file_validation
  kms_key_id                    = var.enable_kms ? aws_kms_key.cloudtrail.arn : null
  tags                          = local.tags

  advanced_event_selector {
    name = null
    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3::Object"]
    }
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
  }
  advanced_event_selector {
    name = null
    field_selector {
      field  = "resources.type"
      equals = ["AWS::Lambda::Function"]
    }
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
  }
  advanced_event_selector {
    name = null
    field_selector {
      field  = "resources.type"
      equals = ["AWS::CloudTrail::Channel"]
    }
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
  }
  advanced_event_selector {
    name = null
    field_selector {
      field  = "resources.type"
      equals = ["AWS::Cognito::IdentityPool"]
    }
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
  }
  advanced_event_selector {
    name = null
    field_selector {
      field  = "resources.type"
      equals = ["AWS::GuardDuty::Detector"]
    }
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
  }
  advanced_event_selector {
    name = null
    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3::AccessPoint"]
    }
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
  }
  advanced_event_selector {
    name = null
    field_selector {
      field  = "resources.type"
      equals = ["AWS::ServiceDiscovery::Service"]
    }
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
  }
  advanced_event_selector {
    name = null
    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3ObjectLambda::AccessPoint"]
    }
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
  }
  advanced_event_selector {
    name = null
    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3Outposts::Object"]
    }
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
  }
  advanced_event_selector {
    name = null
    field_selector {
      field  = "resources.type"
      equals = ["AWS::EC2::Snapshot"]
    }
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
  }
  advanced_event_selector {
    name = null
    field_selector {
      field  = "resources.type"
      equals = ["AWS::SageMaker::Endpoint"]
    }
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
  }
  advanced_event_selector {
    name = null
    field_selector {
      field  = "resources.type"
      equals = ["AWS::SageMaker::FeatureGroup"]
    }
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
  }
  advanced_event_selector {
    name = null
    field_selector {
      field  = "resources.type"
      equals = ["AWS::SageMaker::ExperimentTrialComponent"]
    }
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
  }
  advanced_event_selector {
    name = null
    field_selector {
      field  = "resources.type"
      equals = ["AWS::SSMMessages::ControlChannel"]
    }
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
  }
  advanced_event_selector {
    name = null
    field_selector {
      field  = "resources.type"
      equals = ["AWS::XRay::Trace"]
    }
    field_selector {
      field  = "eventCategory"
      equals = ["Data"]
    }
  }
  advanced_event_selector {
    name = null
    field_selector {
      field  = "eventCategory"
      equals = ["NetworkActivity"]
    }
    field_selector {
      field  = "eventSource"
      equals = ["ec2.amazonaws.com"]
    }
  }
  advanced_event_selector {
    name = null
    field_selector {
      field  = "eventCategory"
      equals = ["NetworkActivity"]
    }
    field_selector {
      field  = "eventSource"
      equals = ["cloudtrail.amazonaws.com"]
    }
  }
  advanced_event_selector {
    name = null
    field_selector {
      field  = "eventCategory"
      equals = ["NetworkActivity"]
    }
    field_selector {
      field  = "eventSource"
      equals = ["kms.amazonaws.com"]
    }
  }
  advanced_event_selector {
    name = null
    field_selector {
      field  = "eventCategory"
      equals = ["NetworkActivity"]
    }
    field_selector {
      field  = "eventSource"
      equals = ["secretsmanager.amazonaws.com"]
    }
  }
  advanced_event_selector {
    name = "관리 이벤트 선택기"
    field_selector {
      field  = "eventCategory"
      equals = ["Management"]
    }
    field_selector {
      field      = "eventSource"
      not_equals = ["kms.amazonaws.com", "rdsdata.amazonaws.com"]
    }
  }

  insight_selector {
    insight_type = "ApiCallRateInsight"
  }
  insight_selector {
    insight_type = "ApiErrorRateInsight"
  }
}
  
resource "aws_sns_topic" "cloudtrail_alerts" {
  count = var.enable_sns_notification ? 1 : 0
  name  = coalesce(var.sns_topic_name, "${local.trail_name}-alerts")
  tags  = local.tags
}

resource "aws_lambda_function" "slack_notification" {
  count         = var.enable_slack_notification ? 1 : 0
  filename      = "${path.module}/lambda/slack_notification.zip"
  function_name = "${local.trail_name}-slack-notification"
  role          = aws_iam_role.lambda_role[0].arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.cloudtrail_slack_webhook_url
      SLACK_CHANNEL    = var.slack_channel
    }
  }

  tags = local.tags
}

resource "aws_iam_role" "lambda_role" {
  count = var.enable_slack_notification ? 1 : 0
  name  = "${local.trail_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_sns_topic_subscription" "lambda" {
  count     = var.enable_slack_notification && var.enable_sns_notification ? 1 : 0
  topic_arn = aws_sns_topic.cloudtrail_alerts[0].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notification[0].arn
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  count             = var.enable_slack_notification ? 1 : 0
  name              = "/aws/lambda/${aws_lambda_function.slack_notification[0].function_name}"
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count      = var.enable_slack_notification ? 1 : 0
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_kms_key" "cloudtrail" {
  description             = "KMS key for CloudTrail log file encryption"
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 30
}