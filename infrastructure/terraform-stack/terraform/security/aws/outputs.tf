output "cloudtrail_id" {
  description = "CloudTrail 트레일 ID"
  value       = module.cloudtrail.cloudtrail_id
}

output "cloudtrail_arn" {
  description = "CloudTrail 트레일 ARN"
  value       = module.cloudtrail.cloudtrail_arn
}

output "cloudtrail_s3_bucket" {
  description = "CloudTrail 로그 S3 버킷 이름"
  value       = module.cloudtrail.s3_bucket_id
}

output "sonarqube_rds_endpoint" {
  description = "SonarQube RDS endpoint"
  value       = module.sonarqube.rds_endpoint
}

output "sonarqube_secret_arn" {
  description = "SonarQube database credentials secret ARN"
  value       = module.sonarqube.secret_arn
}
