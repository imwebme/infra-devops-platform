# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  cloud {
    organization = "example-org"

    hostname = "app.terraform.io"
    workspaces {
      name = "devops-datadog"
    }
  }

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
    bcrypt = {
      source  = "viktorradnai/bcrypt"
      version = ">= 0.1.2"
    }
    datadog = {
      source  = "DataDog/datadog"
      version = "3.66.0"
    }
  }
  required_version = "~> 1.9.8"
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
}
