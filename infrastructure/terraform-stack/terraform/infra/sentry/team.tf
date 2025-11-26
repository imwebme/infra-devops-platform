# resource "sentry_team" "example-org" {
#   name         = "terraform-test"
#   slug         = "terraform-test"
#   organization = sentry_organization.example-org.slug
# }