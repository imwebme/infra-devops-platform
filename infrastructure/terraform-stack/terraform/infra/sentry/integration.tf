data "sentry_organization_integration" "slack" {
  organization = sentry_organization.example-org.slug

  provider_key = "slack"
  name         = "Levit"
}