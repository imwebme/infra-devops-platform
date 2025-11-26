variable "region" {
  description = "AWS 리전 (기본값: ap-northeast-2 서울)"
  type        = string
  default     = "ap-northeast-2"
}

variable "name" {
  description = "CloudTrail 트레일의 이름"
  type        = string
}

variable "s3_bucket_name" {
  description = "CloudTrail 로그를 저장할 S3 버킷 이름"
  type        = string
}

variable "enable_logging" {
  description = "CloudTrail 로깅 활성화 여부"
  type        = bool
  default     = true
}

variable "is_multi_region_trail" {
  description = "모든 리전의 이벤트를 로깅할지 여부"
  type        = bool
  default     = true
}

variable "include_global_service_events" {
  description = "IAM, CloudFront 등 글로벌 서비스 이벤트 포함 여부"
  type        = bool
  default     = true
}

variable "enable_log_file_validation" {
  description = "CloudTrail 로그 파일 무결성 검증 활성화 여부"
  type        = bool
  default     = true
}

variable "tags" {
  description = "CloudTrail 리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}

# CloudTrail 특화 태그
variable "cloudtrail_tags" {
  description = "CloudTrail 특화 태그"
  type        = map(string)
  default     = {
    Sensitivity = "high"
    Compliance  = "isms"
    DataType    = "audit-logs"
    CostCenter  = "security-audit"
    Backup      = "required"
    Retention   = "2-years"
    Group       = "ops-security"
  }
}

# KMS 암호화 설정
variable "enable_kms" {
  description = "KMS 암호화 사용 여부"
  type        = bool
  default     = true
}

# 로그 보존 기간
variable "log_retention_days" {
  description = "CloudTrail 로그 보존 기간 (일) - ISMS 기준 최소 1년(365일), 권장 2년(731일)"
  type        = number
  default     = 731
}

# SNS 알림 설정
variable "enable_sns_notification" {
  description = "CloudTrail 로그 SNS 알림 활성화 여부"
  type        = bool
  default     = false
}

variable "sns_topic_name" {
  description = "알림을 보낼 SNS 토픽 이름 (enable_sns_notification이 true일 때 사용)"
  type        = string
  default     = null
}

# Slack 알림 설정
variable "enable_slack_notification" {
  description = "Slack 알림 활성화 여부"
  type        = bool
  default     = false
}

variable "cloudtrail_slack_webhook_url" {
  description = "Slack Incoming Webhook URL (GitHub Secret: CLOUDTRAIL_SLACK_WEBHOOK_URL)"
  type        = string
  default     = null
  sensitive   = true
}

variable "slack_channel" {
  description = "알림을 보낼 Slack 채널명"
  type        = string
  default     = "#모니터링_서비스보안_이상탐지"
}

variable "notification_events" {
  description = "알림을 받을 CloudTrail 이벤트 유형 목록"
  type        = list(string)
  default     = [
    "AWS API Call via CloudTrail",
    "AWS Console Sign In via CloudTrail",
    "AWS Root Account Usage",
    "IAM Policy Changes",
    "Security Group Changes",
    "Network ACL Changes"
  ]
}
