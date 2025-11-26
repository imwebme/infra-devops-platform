resource "datadog_monitor" "error_monitor" {
  for_each = { for svc in local.monitoring_services : "${svc.service}_${svc.monitor_type}" => svc }

  name = lookup({
    error_log            = "${each.value.service} 에러 모니터",
    error_tracking_trace = "${each.value.service} {{ span.type }} 에러 모니터"
    api_latency          = "${each.value.service} API 지연(${each.value.duration}ms 이상) 모니터",
    alb_target_4xx       = "${each.value.service} ALB Target 4xx 에러 모니터"
    alb_target_5xx       = "${each.value.service} ALB Target 5xx 에러 모니터"
    alb_5xx              = "${each.value.service} ALB 5xx 에러 모니터",
    alb_4xx              = "${each.value.service} ALB 4xx 에러 모니터",
    custom_alert         = "${each.value.name}"
  }, each.value.monitor_type, "${each.value.service} 모니터")

  type = lookup({
    error_log            = "log alert",
    error_tracking_trace = "error-tracking alert"
    api_latency          = "trace-analytics alert",
    alb_target_5xx       = "metric alert"
    alb_target_4xx       = "metric alert"
    alb_5xx              = "metric alert",
    alb_4xx              = "metric alert",
    custom_alert         = "${each.value.type}",
  }, each.value.monitor_type, "log alert")

  query = lookup({
    error_log            = "logs(\"service:${each.value.service} env:prod status:error\").index(\"*\").rollup(\"count\").last(\"5m\") > ${each.value.threshold}",
    error_tracking_trace = "error-tracking-traces(\"env:prod -resource_name:\"GET /health-check\" service:${each.value.service} status:error type:(web OR http)\").impact().rollup(\"count\").by(\"@issue.id\").last(\"5m\") > ${each.value.threshold}",
    api_latency          = "trace-analytics(\"@duration:>${each.value.duration}ms -resource_name:\"<anonymous>\" -resource_name:(POST OR PUT OR OPTION OR GET OR DELETE) service:${each.value.service}* env:prod\").rollup(\"count\").by(\"service,resource_name\").last(\"1m\") > ${each.value.threshold}",
    alb_target_5xx       = "sum(last_5m):sum:aws.applicationelb.httpcode_target_5xx{loadbalancer:app/${each.value.loadbalancer}*}.as_count() > ${each.value.threshold}",
    alb_target_4xx       = "sum(last_5m):sum:aws.applicationelb.httpcode_target_4xx{!status_code:409,loadbalancer:app/${each.value.loadbalancer}*}.as_count() > ${each.value.threshold}",
    alb_5xx              = "sum(last_5m):sum:aws.applicationelb.httpcode_elb_5xx{loadbalancer:app/${each.value.loadbalancer}*, env:prod} by {host}.as_count() > ${each.value.threshold}",
    alb_4xx              = "sum(last_5m):sum:aws.applicationelb.httpcode_elb_4xx{loadbalancer:app/${each.value.loadbalancer}*, env:prod} by {host}.as_count() > ${each.value.threshold}",
    custom_alert         = "${each.value.query}"
  }, each.value.monitor_type, "")

  message = templatefile(
    lookup({
      error_log            = "${path.module}/templates/monitor_error_log.tpl",
      error_tracking_trace = "${path.module}/templates/monitor_error_tracking_trace.tpl"
      api_latency          = "${path.module}/templates/monitor_api_latency.tpl",
      alb_target_5xx       = "${path.module}/templates/monitor_alb_target_5xx.tpl"
      alb_target_4xx       = "${path.module}/templates/monitor_alb_target_4xx.tpl"
      alb_5xx              = "${path.module}/templates/monitor_alb_5xx.tpl",
      alb_4xx              = "${path.module}/templates/monitor_alb_4xx.tpl",
      custom_alert         = "${path.module}/templates/${each.value.message_template}"
    }, each.value.monitor_type, "${path.module}/templates/monitor_error_log.tpl"),
    {
      service        = each.value.service
      owners         = join(", ", [for o in each.value.owners : "<@${o.slack_id}>"])
      slack_channels = join(" ", [for c in each.value.slack_channels : "@slack-Levit-${c}"])
      duration       = each.value.duration
    }
  )

  tags = [
    "service:${each.value.service}",
    "env:prod"
  ]

  notify_no_data    = false
  renotify_interval = 0

  escalation_message = ""
  priority           = 3

  notify_audit = false
  include_tags = true
}

resource "datadog_synthetics_test" "synthetics" {
  for_each = { for svc in local.synthetics_monitors : "${svc.service}_${svc.name}" => svc }

  type    = each.value.type
  subtype = each.value.subtype
  name    = each.value.name
  status  = each.value.status
  message = templatefile(
    "${path.module}/templates/monitor_synthetics.tpl",
    {
      service        = each.value.service
      url            = each.value.request_definition.url
      owners         = join(", ", [for o in each.value.owners : "<@${o.slack_id}>"])
      slack_channels = join(" ", [for c in each.value.slack_channels : "@slack-Levit-${c}"])
    }
  )

  locations = each.value.locations

  request_definition {
    method = each.value.request_definition.method
    url    = each.value.request_definition.url
  }

  dynamic "assertion" {
    for_each = each.value.assertions
    content {
      type     = assertion.value.type
      operator = assertion.value.operator
      target   = assertion.value.target
      property = lookup(assertion.value, "property", null)
    }
  }

  options_list {
    tick_every = each.value.options_list.tick_every
    retry {
      count    = each.value.options_list.retry.count
      interval = each.value.options_list.retry.interval
    }
    monitor_options {
      renotify_interval = each.value.options_list.monitor_options.renotify_interval
      escalation_message = templatefile(
        "${path.module}/templates/monitor_synthetics_renotify.tpl",
        {
          service        = each.value.service
          url            = each.value.request_definition.url
          owners         = join(", ", [for o in each.value.owners : "<@${o.slack_id}>"])
          slack_channels = join(" ", [for c in each.value.slack_channels : "@slack-Levit-${c}"])
        }
      )
    }
  }

  tags = [
    "service:${each.value.service}",
    "env:prod"
  ]
}
