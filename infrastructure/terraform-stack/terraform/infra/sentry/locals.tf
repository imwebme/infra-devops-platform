data "local_file" "sentry" {
  filename = "${path.module}/monitoring/monitoring.yaml"
}

data "external" "slack_id" {
  for_each = {
    for o in distinct(flatten([
      for frontend in try(local.sentry_config.owners.frontend, []) : frontend.owner
    ])) : o.email => o
  }
  program = ["python3", "${path.module}/externals/get_slack_id.py"]
  query = {
    email = each.value.email
  }
}

data "external" "slack_channel_name" {
  for_each = {
    for query in local.slack_channel_queries : query.key => query
  }
  program = ["python3", "${path.module}/externals/get_slack_channel_id.py"]
  query = {
    channel_id = each.value.channel_id
  }
}

locals {
  sentry_config = yamldecode(data.local_file.sentry.content)
  sentry_alerts = flatten([
    for frontend in try(local.sentry_config.owners.frontend, []) : [
      for alert in try(frontend.alerts, []) : merge({
        slug            = frontend.project.slug
        owners          = frontend.owner
        alerts          = frontend.alerts
        project         = frontend.project
        conditions_json = alert.conditions_json
        filters_json    = alert.filters_json
        actions_json    = alert.actions_json
      }, alert)
    ]
  ])
}

locals {
  slack_channel_queries = flatten([
    for alert_index, alert in local.sentry_alerts : [
      for action_index, action in alert.actions_json : {
        key          = "${alert.slug}-${alert_index}-${action.channel_id}-${action_index}"
        action_index = action_index
        channel_id   = action.channel_id
      }
    ] if alert.type == "issue"
  ])
}