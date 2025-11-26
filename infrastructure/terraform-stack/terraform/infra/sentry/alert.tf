resource "sentry_issue_alert" "service" {
  for_each = {
    for idx, alert in local.sentry_alerts :
    "${idx}-${alert.slug}-${alert.type}" => alert
    if alert.type == "issue"
  }

  organization = sentry_organization.example-org.slug
  project      = sentry_project.service[each.value.slug].id
  name         = each.value.name

  action_match = each.value.action_match
  filter_match = each.value.filter_match
  frequency    = each.value.frequency

  conditions = jsonencode(each.value.conditions_json)

  filters = jsonencode(each.value.filters_json)

  actions = jsonencode([
    for action_index, action in each.value.actions_json : {
      id         = action.id
      workspace  = data.sentry_organization_integration.slack.id
      channel    = try(data.external.slack_channel_name["${each.value.slug}-${split(each.key, "-")[0]}-${action.channel_id}-${action_index}"].result.channel_name, "모니터링_인프라_테스트")
      channel_id = action.channel_id
      notes = lookup(each.value, "mention", true) != false ? join(" ", [
        for owner in each.value.owners :
        format("<@%s>", try(data.external.slack_id[owner.email].result.slack_id, ""))
        if try(data.external.slack_id[owner.email].result.slack_id, "") != ""
      ]) : ""
      tags = action.tags
    }
  ])
}
