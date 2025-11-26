data "local_file" "defaults" {
  # filename = "${path.module}/config/_defaults.yml"
  filename = "../../config/_defaults.yml"
}

data "local_file" "config" {
  # filename = "${path.module}/config/${terraform.workspace}.yml"
  filename = "../../config/${terraform.workspace}.yml"
}

locals {
  defaults   = yamldecode(data.local_file.defaults.content)
  env_config = yamldecode(data.local_file.config.content)

  config = merge(
    local.defaults,
    {
      for k, v in local.env_config : k => (
        k == "ecr" || k == "frontend" ? (
          # ecr 키에 대해 환경 설정에서 명시적으로 빈 배열([])이 지정된 경우
          # defaults의 값과 상관없이 빈 배열을 사용
          v == [] ? tolist([]) : distinct(concat(try(local.defaults[k], []), try(v, [])))
        ) : v
      )
    }
  )
}

locals {
  org                    = lookup(local.config, "org", "")
  category               = lookup(local.config, "category", "")
  env                    = lookup(local.config, "env", "dev")
  prefix                 = join("-", compact([local.org, local.category, local.env]))
  secondary_level_domain = local.config["secondary_level_domain"]
  domain                 = join(".", compact([local.category, local.env, local.secondary_level_domain]))
  azs                    = slice(data.aws_availability_zones.available.names, 0, 4)
  git_private_ssh_key    = var.ssh_key_path # Update with the git ssh key to be used by ArgoCD

  cloudfront                   = lookup(local.config, "cloudfront", {})
  s3_configs                   = lookup(local.config, "s3", {})
  frontend_service_names       = lookup(local.config, "frontend", [])
  vpc_cidr                     = lookup(local.config, "vpc_cidr", "10.0.0.0/16")
  nat_gateway                  = lookup(local.config, "nat_gateway", {})
  eks                          = lookup(local.config, "eks", {})
  repository_names             = lookup(local.config, "ecr", [])
  karpenter                    = lookup(local.config, "karpenter", {})
  coredns                      = lookup(local.config, "coredns", {})
  kube_proxy                   = lookup(local.config, "kube_proxy", {})
  aws_ebs_csi_driver           = lookup(local.config, "aws_ebs_csi_driver", {})
  aws_mountpoint_s3_csi_driver = lookup(local.config, "aws_mountpoint_s3_csi_driver", {})
  vpc_cni                      = lookup(local.config, "vpc_cni", {})
  eks_pod_identity_agent       = lookup(local.config, "eks_pod_identity_agent", {})
  elasticache                  = lookup(local.config, "elasticache", {})
  loki                         = lookup(local.config, "loki", {})
  service_roles                = lookup(local.config, "service_roles", {})
  managed_policies             = lookup(local.config, "managed_policies", {})
  pod_identity_associations    = lookup(local.config, "pod_identity_associations", {})

  github_org = lookup(local.config, "github_org", "")

  default_vpc_endpoints = local.config.vpc_endpoints.enabled ? {
    "${data.aws_region.current.name}" = {
      "s3" = {
        "service_name"        = "com.amazonaws.${data.aws_region.current.name}.s3",
        "type"                = "Gateway"
        "private_dns_enabled" = false
      },
      "eks-auth" = {
        "service_name"        = "com.amazonaws.${data.aws_region.current.name}.eks-auth",
        "type"                = "Interface"
        "private_dns_enabled" = true
        "subnet_ids"          = data.aws_subnets.private_eks.ids
      },
      "ecr-dkr" = {
        "service_name"        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr",
        "type"                = "Interface"
        "private_dns_enabled" = true
        "subnet_ids"          = data.aws_subnets.private_eks_abc_zones.ids
      },
      "ec2" = {
        "service_name"        = "com.amazonaws.${data.aws_region.current.name}.ec2",
        "type"                = "Interface"
        "private_dns_enabled" = true
        "subnet_ids"          = data.aws_subnets.private_eks.ids
      },
      "secretsmanager" = {
        "service_name"        = "com.amazonaws.${data.aws_region.current.name}.secretsmanager",
        "type"                = "Interface"
        "private_dns_enabled" = true
        "subnet_ids"          = data.aws_subnets.private_eks.ids
      },
      "guardduty" = {
        "service_name"        = "com.amazonaws.${data.aws_region.current.name}.guardduty-data",
        "type"                = "Interface"
        "private_dns_enabled" = true
        "subnet_ids"          = data.aws_subnets.private_eks_abc_zones.ids
      }
    }
  } : {}

  datadog_vpc_endpoints = {
    "us-east-1" = {
      "agent-http-intake.logs" = {
        "service_name"        = "com.amazonaws.vpce.us-east-1.vpce-svc-025a56b9187ac1f63"
        "type"                = "Interface"
        "private_dns_enabled" = false
        "subnet_ids"          = ["subnet-03a8cc22", "subnet-203a136d", "subnet-750e5d7b", "subnet-83933eb2", "subnet-9ade47fc", "subnet-9b9903c4"]
      }
      "http-intake.logs" = {
        "service_name"        = "com.amazonaws.vpce.us-east-1.vpce-svc-0e36256cb6172439d"
        "type"                = "Interface"
        "private_dns_enabled" = false
        "subnet_ids"          = ["subnet-03a8cc22", "subnet-203a136d", "subnet-750e5d7b", "subnet-83933eb2", "subnet-9ade47fc", "subnet-9b9903c4"]
      }
      "api" = {
        "service_name"        = "com.amazonaws.vpce.us-east-1.vpce-svc-064ea718f8d0ead77"
        "type"                = "Interface"
        "private_dns_enabled" = false
        "subnet_ids"          = ["subnet-03a8cc22", "subnet-203a136d", "subnet-750e5d7b", "subnet-83933eb2", "subnet-9ade47fc", "subnet-9b9903c4"]
      }
      "metrics.agent" = {
        "service_name"        = "com.amazonaws.vpce.us-east-1.vpce-svc-09a8006e245d1e7b8"
        "type"                = "Interface"
        "private_dns_enabled" = false
        "subnet_ids"          = ["subnet-03a8cc22", "subnet-203a136d", "subnet-750e5d7b", "subnet-83933eb2", "subnet-9ade47fc", "subnet-9b9903c4"]
      }
      "orchestrator" = {
        "service_name"        = "com.amazonaws.vpce.us-east-1.vpce-svc-0ad5fb9e71f85fe99"
        "type"                = "Interface"
        "private_dns_enabled" = false
        "subnet_ids"          = ["subnet-03a8cc22", "subnet-203a136d", "subnet-750e5d7b", "subnet-83933eb2", "subnet-9ade47fc", "subnet-9b9903c4"]
      }
      "process" = {
        "service_name"        = "com.amazonaws.vpce.us-east-1.vpce-svc-0ed1f789ac6b0bde1"
        "type"                = "Interface"
        "private_dns_enabled" = false
        "subnet_ids"          = ["subnet-03a8cc22", "subnet-203a136d", "subnet-750e5d7b", "subnet-83933eb2", "subnet-9ade47fc", "subnet-9b9903c4"]
      }
      "intake.profile" = {
        "service_name"        = "com.amazonaws.vpce.us-east-1.vpce-svc-022ae36a7b2472029"
        "type"                = "Interface"
        "private_dns_enabled" = false
        "subnet_ids"          = ["subnet-03a8cc22", "subnet-203a136d", "subnet-750e5d7b", "subnet-83933eb2", "subnet-9ade47fc", "subnet-9b9903c4"]
      }
      "trace.agent" = {
        "service_name"        = "com.amazonaws.vpce.us-east-1.vpce-svc-0355bb1880dfa09c2"
        "type"                = "Interface"
        "private_dns_enabled" = false
        "subnet_ids"          = ["subnet-03a8cc22", "subnet-203a136d", "subnet-750e5d7b", "subnet-83933eb2", "subnet-9ade47fc", "subnet-9b9903c4"]
      }
      "dbm-metrics-intake" = {
        "service_name"        = "com.amazonaws.vpce.us-east-1.vpce-svc-0ce70d55ec4af8501"
        "type"                = "Interface"
        "private_dns_enabled" = false
        "subnet_ids"          = ["subnet-03a8cc22", "subnet-203a136d", "subnet-750e5d7b", "subnet-83933eb2", "subnet-9ade47fc", "subnet-9b9903c4"]
      }
      "config" = {
        "service_name"        = "com.amazonaws.vpce.us-east-1.vpce-svc-01f21309e507e3b1d"
        "type"                = "Interface"
        "private_dns_enabled" = false
        "subnet_ids"          = ["subnet-03a8cc22", "subnet-203a136d", "subnet-750e5d7b", "subnet-83933eb2", "subnet-9ade47fc", "subnet-9b9903c4"]
      }
    }
  }

  # Datadog를 사용하는 환경에서만 Datadog VPC 엔드포인트 포함
  datadog_enabled_vpc_endpoints = local.config.datadog_private_link.enabled ? local.datadog_vpc_endpoints : {}

  vpc_endpoints = merge(
    local.default_vpc_endpoints,
    local.datadog_enabled_vpc_endpoints,
    try(local.config.vpc_endpoints["list"], {})
  )

  route53_public_zones = { for domain in try(local.config["route53_zones"]["public"], []) :
    domain => {
      comment = domain
      vpc     = []
      tags    = {}
    }
  }

  # Datadog private hosted zones (security-prod 환경에서만 생성)
  datadog_private_zones = try(local.config.datadog_private_link.enabled, false) && local.category == "security" && local.env == "prod" ? {
    "agent-http-intake.logs.datadoghq.com" = {
      comment = "Datadog Agent HTTP Intake Private Zone"
      vpc = [{
        vpc_id = module.vpc.vpc_id
      }]
      tags = { Type = "datadog-private-link" }
    }
    "http-intake.logs.datadoghq.com" = {
      comment = "Datadog HTTP Intake Private Zone"
      vpc = [{
        vpc_id = module.vpc.vpc_id
      }]
      tags = { Type = "datadog-private-link" }
    }
    "api.datadoghq.com" = {
      comment = "Datadog API Private Zone"
      vpc = [{
        vpc_id = module.vpc.vpc_id
      }]
      tags = { Type = "datadog-private-link" }
    }
    "metrics.agent.datadoghq.com" = {
      comment = "Datadog Metrics Agent Private Zone"
      vpc = [{
        vpc_id = module.vpc.vpc_id
      }]
      tags = { Type = "datadog-private-link" }
    }
    "orchestrator.datadoghq.com" = {
      comment = "Datadog Orchestrator Private Zone"
      vpc = [{
        vpc_id = module.vpc.vpc_id
      }]
      tags = { Type = "datadog-private-link" }
    }
    "process.datadoghq.com" = {
      comment = "Datadog Process Private Zone"
      vpc = [{
        vpc_id = module.vpc.vpc_id
      }]
      tags = { Type = "datadog-private-link" }
    }
    "intake.profile.datadoghq.com" = {
      comment = "Datadog Profile Intake Private Zone"
      vpc = [{
        vpc_id = module.vpc.vpc_id
      }]
      tags = { Type = "datadog-private-link" }
    }
    "trace.agent.datadoghq.com" = {
      comment = "Datadog Trace Agent Private Zone"
      vpc = [{
        vpc_id = module.vpc.vpc_id
      }]
      tags = { Type = "datadog-private-link" }
    }
    "dbm-metrics-intake.datadoghq.com" = {
      comment = "Datadog DBM Metrics Intake Private Zone"
      vpc = [{
        vpc_id = module.vpc.vpc_id
      }]
      tags = { Type = "datadog-private-link" }
    }
    "config.datadoghq.com" = {
      comment = "Datadog Config Private Zone"
      vpc = [{
        vpc_id = module.vpc.vpc_id
      }]
      tags = { Type = "datadog-private-link" }
    }
  } : {}

  # Datadog 도메인 목록 (security-prod에서만 사용)
  datadog_domains = [
    "agent-http-intake.logs.datadoghq.com",
    "http-intake.logs.datadoghq.com",
    "api.datadoghq.com",
    "metrics.agent.datadoghq.com",
    "orchestrator.datadoghq.com",
    "process.datadoghq.com",
    "intake.profile.datadoghq.com",
    "trace.agent.datadoghq.com",
    "dbm-metrics-intake.datadoghq.com",
    "config.datadoghq.com"
  ]

  # Datadog private link에 association할 VPC 목록 (config에서 가져옴)
  datadog_associated_vpc_ids = try(local.config.datadog_private_link.associated_vpc_ids, [])

  # 현재 환경의 도메인 (각 환경에서 1:1 매핑)
  current_env_domain = "${local.category}.${local.env}.iexample-org.com"

  # 기존 config 기반 private zones와 datadog zones 통합
  config_private_zones = { for domain in try(local.config["route53_zones"]["private"], []) :
    domain => {
      comment = domain
      vpc = [{
        vpc_id = module.vpc.vpc_id
      }]
      tags = {}
    }
  }

  route53_private_zones = merge(local.config_private_zones, local.datadog_private_zones)

  secretmanagers = merge(try(local.config.secretmanagers, {}), {
    "argocd" = {
      "ADMIN_PASSWORD" = random_password.argocd_admin_password.result
      "GITHUB_SECRET"  = random_password.github_secret.result
    }
  })

  tags = {
    Env       = local.prefix
    ManagedBy = "terraform"
  }

  private_data_subnet_ids = [
    for subnet in module.vpc.database_subnet_objects :
    subnet.id if can(subnet.tags.Name) && length(regexall("private-data", subnet.tags.Name)) > 0
  ]

  s3_configs_map = { for item in local.s3_configs :
    keys(item)[0] => values(item)[0]
  }
}

