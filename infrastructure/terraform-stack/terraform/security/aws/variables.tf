variable "tags" {
  description = "모든 보안 모듈에 공통으로 적용될 태그"
  type        = map(string)
  default     = {
    ManagedBy   = "terraform"
    Team        = "ops"
    Service     = "aws-security-governance"
    Owner       = "kjg@iexample-org.com"
    Category    = "security"
  }
}

variable "environment" {
  description = "AWS 리소스가 배포될 환경을 지정합니다. 허용값: dev, staging, prod, security-core"
  type        = string
  default     = "prod"
}

variable "org" {
  description = "AWS 리소스를 소유하는 조직의 이름입니다. 리소스 네이밍과 태깅에 사용됩니다. (예: example-org)"
  type        = string
  default     = "example-org"
}

variable "cloudtrail_slack_webhook_url" {
  description = "Slack Webhook URL for CloudTrail 알림 (GitHub Secret: CLOUDTRAIL_SLACK_WEBHOOK_URL)"
  type        = string
  default     = null
  sensitive   = true
}
