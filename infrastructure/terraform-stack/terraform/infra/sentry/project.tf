resource "sentry_project" "service" {
  for_each = { for frontend in local.sentry_config.owners.frontend : frontend.project.slug => frontend }

  organization = sentry_organization.example-org.slug

  teams = each.value.project.teams
  name  = each.value.project.name
  slug  = each.value.project.slug

  platform    = each.value.project.platform
  resolve_age = each.value.project.resolve_age

  default_rules = each.value.project.default_rules

  filters = try(each.value.project.filters, {})

  fingerprinting_rules = try(each.value.project.fingerprinting_rules, null)

  grouping_enhancements = try(each.value.project.grouping_enhancements, null)
}