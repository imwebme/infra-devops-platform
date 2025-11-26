resource "datadog_integration_slack_channel" "channels" {
  for_each = local.slack_channels_map

  account_name = each.value.account_name
  channel_name = each.value.channel_name

  display {
    message  = true
    notified = true
    snapshot = true
    tags     = true
  }
}