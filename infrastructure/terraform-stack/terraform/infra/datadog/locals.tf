data "local_file" "monitoring" {
  filename = "./monitoring/monitoring.yaml"
}

data "external" "slack_id" {
  for_each = {
    for o in distinct(flatten([
      for backend in try(local.monitoring_config.owners.backend, []) : backend.owner
    ])) : o.email => o
  }
  program = ["python3", "${path.module}/externals/get_slack_id.py"]
  query = {
    email = each.value.email
  }
}

locals {
  monitoring_config = yamldecode(data.local_file.monitoring.content)
  monitoring_services = flatten([
    for backend in try(local.monitoring_config.owners.backend, []) : [
      for monitor in try(backend.monitors, []) : merge({
        service      = backend.service
        monitor_type = lookup(monitor, "monitor_type", "")
        type         = lookup(monitor, "type", "")
        threshold    = lookup(monitor, "threshold", 5)
        loadbalancer = lookup(monitor, "loadbalancer", "")
        owners = [for o in backend.owner : {
          name     = o.name
          email    = o.email
          slack_id = data.external.slack_id[o.email].result.slack_id
        }]
        slack_channels = backend.slack_channels
        private        = lookup(monitor, "private", false)
        duration       = lookup(monitor, "duration", 1)

        query            = lookup(monitor, "query", null)
        name             = lookup(monitor, "name", null)
        message_template = lookup(monitor, "message_template", "")
      })
    ]
  ])

  synthetics_monitors = flatten([
    for backend in try(local.monitoring_config.owners.backend, []) : [
      for monitor in try(backend.synthetics, []) : {
        service            = backend.service
        name               = monitor.name
        type               = monitor.type
        subtype            = monitor.subtype
        status             = monitor.status
        locations          = monitor.locations
        request_definition = monitor.request_definition
        assertions         = monitor.assertions
        options_list       = monitor.options_list
        owners = [for o in backend.owner : {
          name     = o.name
          email    = o.email
          slack_id = data.external.slack_id[o.email].result.slack_id
        }]
        slack_channels = backend.slack_channels
      }
    ]
  ])

  # 모든 서비스의 slack_channels를 flatten 후 중복 제거
  slack_channels = distinct(flatten([
    for team, services in local.monitoring_config.owners : [
      for svc in services : svc.slack_channels
    ]
  ]))

  # Datadog Slack Integration 리소스용 맵 생성
  slack_channels_map = {
    for channel in local.slack_channels : channel => {
      account_name = "Levit" # 필요시 변수화
      channel_name = channel
    }
  }
}
