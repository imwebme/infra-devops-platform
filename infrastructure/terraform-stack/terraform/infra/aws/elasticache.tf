locals {
  is_elasticache_enabled = length(keys(local.elasticache)) > 0
}

resource "aws_elasticache_replication_group" "this" {
  for_each = local.elasticache

  replication_group_id       = lookup(each.value, "name", join("-", [local.prefix, "redis", each.key]))
  description                = lookup(each.value, "description", "example description")
  cluster_mode               = lookup(each.value, "cluster_mode", "compatible")
  node_type                  = lookup(each.value, "node_type", "cache.t4g.small")
  engine                     = lookup(each.value, "engine", "redis")
  engine_version             = lookup(each.value, "engine_version", "7.1")
  port                       = lookup(each.value, "port", 6379)
  auto_minor_version_upgrade = lookup(each.value, "auto_minor_version_upgrade", false)
  automatic_failover_enabled = lookup(each.value, "automatic_failover_enabled", true)
  apply_immediately          = lookup(each.value, "apply_immediately", true)
  data_tiering_enabled       = lookup(each.value, "data_tiering_enabled", false)
  maintenance_window         = lookup(each.value, "maintenance_window", "sat:07:30-sat:08:30")
  multi_az_enabled           = lookup(each.value, "multi_az_enabled", true)
  snapshot_retention_limit   = lookup(each.value, "snapshot_retention_limit", 1)
  snapshot_window            = lookup(each.value, "snapshot_window", "02:00-03:00")
  num_cache_clusters         = lookup(each.value, "num_cache_clusters", null)
  num_node_groups            = lookup(each.value, "num_node_groups", null) # shard count
  replicas_per_node_group    = lookup(each.value, "replicas_per_node_group", null)
  at_rest_encryption_enabled = lookup(each.value, "at_rest_encryption_enabled", true)
  security_group_ids         = lookup(each.value, "security_group_ids", [aws_security_group.elasticache[0].id])
  subnet_group_name          = lookup(each.value, "subnet_group_name", aws_elasticache_subnet_group.elasticache[0].name)
  transit_encryption_enabled = lookup(each.value, "transit_encryption_enabled", false)
  parameter_group_name = lookup(
    each.value,
    "parameter_group_name",
    lookup(each.value, "cluster_mode", "compatible") == "enabled" ?
    aws_elasticache_parameter_group.elasticache[each.value.family].name :
    aws_elasticache_parameter_group.elasticache["${each.value.family}-standard"].name
  )
  snapshot_name = lookup(each.value, "snapshot_name", null)

  dynamic "log_delivery_configuration" {
    for_each = lookup(each.value, "log_delivery_configuration", [
      {
        destination      = aws_cloudwatch_log_group.elasticache[0].name
        destination_type = "cloudwatch-logs"
        log_format       = "json"
        log_type         = "engine-log"
      },
      {
        destination      = aws_cloudwatch_log_group.elasticache[0].name
        destination_type = "cloudwatch-logs"
        log_format       = "text"
        log_type         = "slow-log"
      }
    ])
    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = log_delivery_configuration.value.log_type
    }
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_cloudwatch_log_group" "elasticache" {
  count = local.is_elasticache_enabled ? 1 : 0

  name = join("-", [local.prefix, "elasticache", "loggroup"])

  tags = local.tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_security_group" "elasticache" {
  count = local.is_elasticache_enabled ? 1 : 0

  name        = join("-", [local.prefix, "elasticache", "sg"])
  description = "Allow elasticache inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow Redis inbound traffic"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 또는 필요에 맞게 특정 CIDR 블록을 지정합니다.
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_elasticache_subnet_group" "elasticache" {
  count = local.is_elasticache_enabled ? 1 : 0

  name = join("-", [local.prefix, "elasticache", "subnetgroup"])

  subnet_ids = local.private_data_subnet_ids

  tags = local.tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_elasticache_parameter_group" "elasticache" {
  for_each = merge({
    for family in ["redis7", "valkey7", "valkey8"] : "${family}" => {
      family = family
      mode   = "cluster"
      parameters = {
        "cluster-enabled" = "yes"
        "timeout"         = "300"
        "tcp-keepalive"   = "60"
      }
    }
    },
    {
      for family in ["redis7", "valkey7", "valkey8"] : "${family}-standard" => {
        family = family
        mode   = "standard"
        parameters = {
          "cluster-enabled" = "no"
          "timeout"         = "300"
          "tcp-keepalive"   = "60"
        }
      }
  })

  name   = join("-", [local.prefix, "elasticache", "parametergroup", each.key])
  family = each.value.family

  dynamic "parameter" {
    for_each = each.value.parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = local.tags

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_appautoscaling_target" "elasticache" {
  for_each = {
    for name, config in local.elasticache : name => config
    if lookup(lookup(config, "scheduled_scaling", {}), "enabled", false)
  }

  max_capacity       = 8
  min_capacity       = 4
  resource_id        = "replication-group/${aws_elasticache_replication_group.this[each.key].id}"
  scalable_dimension = "elasticache:replication-group:NodeGroups"
  service_namespace  = "elasticache"
}

resource "aws_appautoscaling_scheduled_action" "elasticache" {
  for_each = {
    for item in flatten([
      for name, config in local.elasticache : [
        {
          cluster_name = name
          action_name  = "ScheduledMemoryScaleOut"
          schedule     = lookup(lookup(lookup(config, "scheduled_scaling", {}), "scale_out", {}), "schedule", "cron(0 6 * * ? *)")
          min_capacity = 8
          max_capacity = 8
          start_time   = "2025-04-13T06:00:00+09:00"
          end_time     = "2027-04-13T06:00:00+09:00"
        },
        {
          cluster_name = name
          action_name  = "ScheduledMemoryScaleIn"
          schedule     = lookup(lookup(lookup(config, "scheduled_scaling", {}), "scale_in", {}), "schedule", "cron(0 10 * * ? *)")
          min_capacity = 4
          max_capacity = 4
          start_time   = "2025-04-13T10:00:00+09:00"
          end_time     = "2027-04-13T10:00:00+09:00"
        }
      ]
      if lookup(lookup(config, "scheduled_scaling", {}), "enabled", false)
    ]) : "${item.cluster_name}-${item.action_name}" => item
  }

  name               = each.value.action_name
  service_namespace  = aws_appautoscaling_target.elasticache[each.value.cluster_name].service_namespace
  resource_id        = aws_appautoscaling_target.elasticache[each.value.cluster_name].resource_id
  scalable_dimension = aws_appautoscaling_target.elasticache[each.value.cluster_name].scalable_dimension
  schedule           = each.value.schedule
  timezone           = "Asia/Seoul"
  start_time         = each.value.start_time
  end_time           = each.value.end_time

  scalable_target_action {
    min_capacity = each.value.min_capacity
    max_capacity = each.value.max_capacity
  }
}
