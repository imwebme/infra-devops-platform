data "aws_vpc" "security_prod" {
  filter {
    name   = "tag:Name"
    values = ["security-prod-vpc"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.security_prod.id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

data "aws_security_group" "eks_cluster" {
  filter {
    name   = "tag:Name"
    values = ["security-prod-eks-cluster"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.security_prod.id]
  }
}

resource "aws_db_subnet_group" "sonarqube" {
  name       = "sonarqube-subnet-group"
  subnet_ids = data.aws_subnets.private.ids

  tags = var.tags
}

resource "aws_security_group" "sonarqube_rds" {
  name_prefix = "sonarqube-rds-"
  vpc_id      = data.aws_vpc.security_prod.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [data.aws_security_group.eks_cluster.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "sonarqube-rds-sg"
  })
}

resource "random_password" "sonarqube_db_password" {
  length  = 16
  special = true
}

resource "aws_db_instance" "sonarqube" {
  identifier = "sonarqube-postgres"

  engine         = "postgres"
  engine_version = "15.8"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "sonarqube"
  username = "sonarqube"
  password = random_password.sonarqube_db_password.result

  vpc_security_group_ids = [aws_security_group.sonarqube_rds.id]
  db_subnet_group_name   = aws_db_subnet_group.sonarqube.name

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  performance_insights_enabled = false

  tags = merge(var.tags, {
    Name = "sonarqube-postgres"
  })
}

resource "aws_secretsmanager_secret" "sonarqube_postgres" {
  name        = "security-prod-eks/sonarqube/postgres"
  description = "SonarQube PostgreSQL credentials"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "sonarqube_postgres" {
  secret_id = aws_secretsmanager_secret.sonarqube_postgres.id
  secret_string = jsonencode({
    jdbc-url = "jdbc:postgresql://${aws_db_instance.sonarqube.endpoint}/${aws_db_instance.sonarqube.db_name}"
    username = aws_db_instance.sonarqube.username
    password = random_password.sonarqube_db_password.result
  })
}
