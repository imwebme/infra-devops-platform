terraform {
  cloud {

    organization = "example-org"

    workspaces {
      name = "devops-sentry"
    }
  }

  required_providers {
    sentry = {
      source = "jianyuan/sentry"
      version = "0.14.6"
    }
  }
}

provider "sentry" {
  token = var.sentry_auth_token
}