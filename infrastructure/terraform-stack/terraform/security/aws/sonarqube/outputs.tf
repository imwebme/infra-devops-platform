output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.sonarqube.endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.sonarqube.port
}

output "secret_arn" {
  description = "ARN of the secret containing database credentials"
  value       = aws_secretsmanager_secret.sonarqube_postgres.arn
}
