output "cloudtrail_id" {
  description = "The ID of the CloudTrail trail"
  value       = aws_cloudtrail.main.id
}

output "cloudtrail_arn" {
  description = "The ARN of the CloudTrail trail"
  value       = aws_cloudtrail.main.arn
}

output "cloudtrail_home_region" {
  description = "The home region of the CloudTrail trail"
  value       = aws_cloudtrail.main.home_region
}

output "s3_bucket_id" {
  description = "The ID of the S3 bucket used for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket used for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.arn
}
