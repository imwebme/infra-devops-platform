# RDS Subnet Groups
resource "aws_db_subnet_group" "data-db-subnet-group" {
  count = try(local.config["dx_data"]["enabled"], false) ? 1 : 0

  name       = "data-db-subnet-group"
  subnet_ids = local.private_data_subnet_ids

  tags = merge(local.tags, {
    Name = "data-db-subnet-group"
  })
}

resource "aws_db_subnet_group" "main" {
  for_each = { for db in try(local.config.rds.databases, []) : db.identifier => db }

  name       = "${local.prefix}-${each.value.identifier}-subnet-group"
  subnet_ids = local.private_data_subnet_ids

  tags = merge(local.tags, {
    Name = "${local.prefix}-${each.value.identifier}-subnet-group"
  })
}

# RDS Parameter Groups
resource "aws_db_parameter_group" "postgresql" {
  for_each = {
    for db in try(local.config.rds.databases, []) : db.identifier => db
    if db.engine == "postgres"
  }

  family = "postgres${each.value.engine_version}"
  name   = "${local.prefix}-${each.value.identifier}-pg${each.value.engine_version}"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "log_lock_waits"
    value = "1"
  }

  parameter {
    name  = "idle_in_transaction_session_timeout"
    value = "300000"
  }

  parameter {
    name  = "statement_timeout"
    value = "7200000"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  tags = merge(local.tags, {
    Name = "${local.prefix}-${each.value.identifier}-pg${each.value.engine_version}"
  })
}

resource "aws_rds_cluster_parameter_group" "aurora_postgresql" {
  for_each = {
    for db in try(local.config.rds.databases, []) : db.identifier => db
    if db.engine == "aurora-postgresql"
  }

  family = "aurora-postgresql${each.value.engine_version}"
  name   = "${local.prefix}-${each.value.identifier}-aurorapg${each.value.engine_version}"

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "log_lock_waits"
    value = "1"
  }

  parameter {
    name  = "idle_in_transaction_session_timeout"
    value = "300000"
  }

  parameter {
    name  = "statement_timeout"
    value = "7200000"
  }

  tags = merge(local.tags, {
    Name = "${local.prefix}-${each.value.identifier}-aurorapg${each.value.engine_version}"
  })
}

resource "aws_rds_cluster_parameter_group" "aurora_mysql" {
  for_each = {
    for db in try(local.config.rds.databases, []) : db.identifier => db
    if db.engine == "aurora-mysql"
  }

  family = "aurora-mysql${each.value.engine_version}"
  name   = "${local.prefix}-${each.value.identifier}-auroramy${each.value.engine_version}"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "1"
  }

  parameter {
    name  = "innodb_lock_wait_timeout"
    value = "300"
  }

  tags = merge(local.tags, {
    Name = "${local.prefix}-${each.value.identifier}-auroramy${each.value.engine_version}"
  })
}

# RDS Security Groups
resource "aws_security_group" "rds" {
  for_each = { for db in try(local.config.rds.databases, []) : db.identifier => db }

  name_prefix = "${local.prefix}-${each.value.identifier}-rds-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = each.value.port
    to_port     = each.value.port
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.prefix}-${each.value.identifier}-rds"
  })
}

# Get existing password from Secrets Manager (only for demo accounts with RDS)
data "aws_secretsmanager_secret_version" "db_admin" {
  count     = try(local.config.lookup_demo_resources, false) && length(try(local.config.rds.databases, [])) > 0 ? 1 : 0
  secret_id = "demo/${local.env}/db/admin"
}

locals {
  db_admin_secrets  = length(data.aws_secretsmanager_secret_version.db_admin) > 0 ? jsondecode(data.aws_secretsmanager_secret_version.db_admin[0].secret_string) : {}
  db_admin_password = lookup(local.db_admin_secrets, "example-org_admin", "")
}

# Aurora Clusters
resource "aws_rds_cluster" "aurora" {
  for_each = {
    for db in try(local.config.rds.databases, []) : db.identifier => db
    if contains(["aurora-postgresql", "aurora-mysql"], db.engine)
  }

  cluster_identifier              = "${local.prefix}-${each.value.identifier}"
  engine                          = each.value.engine
  engine_version                  = each.value.engine_version
  database_name                   = each.value.database_name
  master_username                 = "example-org_admin"
  master_password                 = local.db_admin_password
  backup_retention_period         = try(each.value.backup_retention_period, 7)
  preferred_backup_window         = try(each.value.backup_window, "03:00-04:00")
  preferred_maintenance_window    = try(each.value.maintenance_window, "sun:04:00-sun:05:00")
  db_cluster_parameter_group_name = each.value.engine == "aurora-postgresql" ? aws_rds_cluster_parameter_group.aurora_postgresql[each.key].name : aws_rds_cluster_parameter_group.aurora_mysql[each.key].name
  db_subnet_group_name            = aws_db_subnet_group.main[each.key].name
  vpc_security_group_ids          = [aws_security_group.rds[each.key].id]
  storage_encrypted               = true
  deletion_protection             = try(each.value.deletion_protection, true)
  skip_final_snapshot             = try(each.value.skip_final_snapshot, false)
  final_snapshot_identifier       = try(each.value.skip_final_snapshot, false) ? null : "${local.prefix}-${each.value.identifier}-final-snapshot"

  dynamic "serverlessv2_scaling_configuration" {
    for_each = try(each.value.serverless_v2, null) != null ? [each.value.serverless_v2] : []
    content {
      max_capacity = serverlessv2_scaling_configuration.value.max_capacity
      min_capacity = serverlessv2_scaling_configuration.value.min_capacity
    }
  }

  tags = merge(local.tags, {
    Name = "${local.prefix}-${each.value.identifier}"
  })
}

# Aurora Cluster Instances
resource "aws_rds_cluster_instance" "aurora" {
  for_each = {
    for instance in flatten([
      for db in try(local.config.rds.databases, []) : [
        for i in range(try(db.instance_count, 1)) : {
          key            = "${db.identifier}-${i}"
          cluster_key    = db.identifier
          identifier     = "${db.identifier}-${i}"
          instance_class = db.instance_class
          engine         = db.engine
        }
      ] if contains(["aurora-postgresql", "aurora-mysql"], db.engine)
    ]) : instance.key => instance
  }

  identifier         = "${local.prefix}-${each.value.identifier}"
  cluster_identifier = aws_rds_cluster.aurora[each.value.cluster_key].id
  instance_class     = each.value.instance_class
  engine             = each.value.engine

  tags = merge(local.tags, {
    Name = "${local.prefix}-${each.value.identifier}"
  })
}

# RDS Instances (non-Aurora)
resource "aws_db_instance" "standalone" {
  for_each = {
    for db in try(local.config.rds.databases, []) : db.identifier => db
    if !contains(["aurora-postgresql", "aurora-mysql"], db.engine)
  }

  identifier                = "${local.prefix}-${each.value.identifier}"
  engine                    = each.value.engine
  engine_version            = each.value.engine_version
  instance_class            = each.value.instance_class
  allocated_storage         = each.value.allocated_storage
  max_allocated_storage     = try(each.value.max_allocated_storage, null)
  storage_type              = try(each.value.storage_type, "gp3")
  storage_encrypted         = true
  db_name                   = each.value.database_name
  username                  = "example-org_admin"
  password                  = local.db_admin_password
  parameter_group_name      = each.value.engine == "postgres" ? aws_db_parameter_group.postgresql[each.key].name : null
  db_subnet_group_name      = aws_db_subnet_group.main[each.key].name
  vpc_security_group_ids    = [aws_security_group.rds[each.key].id]
  backup_retention_period   = try(each.value.backup_retention_period, 7)
  backup_window             = try(each.value.backup_window, "03:00-04:00")
  maintenance_window        = try(each.value.maintenance_window, "sun:04:00-sun:05:00")
  deletion_protection       = try(each.value.deletion_protection, true)
  skip_final_snapshot       = try(each.value.skip_final_snapshot, false)
  final_snapshot_identifier = try(each.value.skip_final_snapshot, false) ? null : "${local.prefix}-${each.value.identifier}-final-snapshot"
  port                      = each.value.port

  tags = merge(local.tags, {
    Name = "${local.prefix}-${each.value.identifier}"
  })
}

# Import existing RDS resources (commented out - uncomment and modify as needed)
# terraform import aws_rds_cluster.aurora["existing-cluster"] existing-cluster-identifier
# terraform import aws_rds_cluster_instance.aurora["existing-instance-0"] existing-instance-identifier
# terraform import aws_db_instance.standalone["existing-instance"] existing-instance-identifier