# ################################################################################
# # Cluster
# ################################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.15"


  cluster_name                   = join("-", [local.prefix, "eks"])
  cluster_version                = lookup(local.eks, "version", "1.33")
  cluster_endpoint_public_access = true


  # EKS Addons
  cluster_addons = {
    aws-ebs-csi-driver = {
      version           = lookup(local.aws_ebs_csi_driver, "version", "v1.39.0-eksbuild.1")
      resolve_conflicts = "OVERWRITE"
      preserve          = true

      configuration_values = jsonencode({
        node = {
          enableWindows     = false
          priorityClassName = "daemonset"
          tolerateAllTaints = false
          tolerations = [
            {
              key      = "MonitoringAddonsOnly"
              value    = "true"
              effect   = "NoSchedule"
              operator = "Equal"
            },
            {
              key      = "MongoDBOnly"
              value    = "true"
              effect   = "NoSchedule"
              operator = "Equal"
            },
            {
              key      = "mlops-service-bs"
              value    = "true"
              effect   = "NoSchedule"
              operator = "Equal"
            },
            {
              key      = "data-service-airflow"
              value    = "true"
              effect   = "NoSchedule"
              operator = "Equal"
            },
            {
              key      = "elk"
              value    = "true"
              effect   = "NoSchedule"
              operator = "Equal"
            },
            {
              key      = "eks.taints.example-org.data/service"
              value    = "mgmt"
              effect   = "NoSchedule"
              operator = "Equal"
            },
            {
              key      = "mlops-milvus"
              value    = "true"
              effect   = "NoSchedule"
              operator = "Equal"
            },
            {
              key      = "mlops-milvus-pulsar"
              value    = "true"
              effect   = "NoSchedule"
              operator = "Equal"
            }
          ]
        }
      })
    }


    aws-mountpoint-s3-csi-driver = {
      resolve_conflicts = "OVERWRITE"
      preserve          = true
      addon_version     = lookup(local.aws_mountpoint_s3_csi_driver, "version", "v1.14.1-eksbuild.1")

      configuration_values = jsonencode({
        node = {
          tolerations = [
            {
              key      = "DemoServicesOnly"
              value    = "true"
              effect   = "NoSchedule"
              operator = "Equal"
            },
            {
              key      = "mlops-service-bs"
              value    = "true"
              effect   = "NoSchedule"
              operator = "Equal"
            }
          ]
        }
      })
    }

    coredns = {
      resolve_conflicts = "OVERWRITE"
      preserve          = true
      version           = lookup(local.coredns, "version", "v1.11.3-eksbuild.2")
      configuration_values = jsonencode({
        replicaCount = local.coredns.replica
        tolerations = [
          {
            key      = "CoreAddonsOnly"
            value    = "true"
            effect   = "NoSchedule"
            operator = "Equal"
          }
        ]

        nodeSelector = {
          service = "core-addons"
        }

        topologySpreadConstraints = [
          {
            maxSkew           = 1
            topologyKey       = "topology.kubernetes.io/zone"
            whenUnsatisfiable = "ScheduleAnyway"
            labelSelector = {
              matchLabels = {
                k8s-app : "kube-dns"
              }
            }
          }
        ]

        affinity = {
          nodeAffinity = {
            requiredDuringSchedulingIgnoredDuringExecution = {
              nodeSelectorTerms = [
                {
                  matchExpressions = [
                    {
                      key      = "kubernetes.io/os"
                      operator = "In"
                      values   = ["linux"]
                    },
                    {
                      key      = "kubernetes.io/arch"
                      operator = "In"
                      values   = ["amd64"]
                    }
                  ]
              }]
            }
          }

          podAffinity = {
            requiredDuringSchedulingIgnoredDuringExecution = [{
              labelSelector = {
                matchExpressions = [
                  {
                    key      = "k8s-app"
                    operator = "NotIn"
                    values   = ["kube-dns"]
                  }
                ]
              }
              topologyKey = "kubernetes.io/hostname"
              }
            ]
          }

          podAntiAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [{
              podAffinityTerm = {
                labelSelector = {
                  matchExpressions = [
                    {
                      key      = "k8s-app"
                      operator = "In"
                      values   = ["kube-dns"]
                    }
                  ]
                }
                topologyKey = "kubernetes.io/hostname"
              }
              weight = 100
              }
            ]

            requiredDuringSchedulingIgnoredDuringExecution = [{
              labelSelector = {
                matchExpressions = [
                  {
                    key      = "k8s-app"
                    operator = "In"
                    values   = ["kube-dns"]
                  }
                ]
              }
              topologyKey = "kubernetes.io/hostname"
              }
            ]
          }
        }

        resources = {
          limits = {
            cpu    = "100m"
            memory = "150Mi"
          }
          requests = {
            cpu    = "100m"
            memory = "150Mi"
          }
        }
      })
    }

    kube-proxy = {
      version           = lookup(local.kube_proxy, "version", "v1.33.0-eksbuild.1")
      resolve_conflicts = "OVERWRITE"
      preserve          = true
    }

    vpc-cni = {
      version           = lookup(local.vpc_cni, "version", "v1.19.0-eksbuild.1")
      resolve_conflicts = "OVERWRITE"
      preserve          = true
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI           = "true"
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
          MINIMUM_IP_TARGET        = "20"
          WARM_ENI_TARGET          = "2"
          WARM_IP_TARGET           = "8"
        }
      })
    }

    eks-pod-identity-agent = {
      version           = lookup(local.eks_pod_identity_agent, "version", "v1.3.8-eksbuild.2")
      resolve_conflicts = "OVERWRITE"
      preserve          = true
      configuration_values = jsonencode({
        tolerations = [
          {
            effect   = "NoSchedule"
            operator = "Exists"
          },
          {
            key      = "CoreAddonsOnly"
            value    = "true"
            effect   = "NoSchedule"
            operator = "Equal"
          },
          {
            key      = "CommonAddonsOnly"
            value    = "true"
            effect   = "NoSchedule"
            operator = "Equal"
          },
          {
            key      = "DemoRecoOnly"
            value    = "true"
            effect   = "NoSchedule"
            operator = "Equal"
          },
          {
            key      = "DemoJobsOnly"
            value    = "true"
            effect   = "NoSchedule"
            operator = "Equal"
          },
          {
            key      = "LevitDataServices"
            value    = "true"
            effect   = "NoSchedule"
            operator = "Equal"
          }
        ]
      })
    }
  }


  vpc_id = module.vpc.vpc_id

  subnet_ids = [
    for subnet in module.vpc.private_subnet_objects :
    subnet.id if can(subnet.tags.Name) && length(regexall("private-eks", subnet.tags.Name)) > 0
  ]

  create_cluster_primary_security_group_tags = false

  create_kms_key = local.eks.kms
  cluster_encryption_config = local.eks.kms ? {
    "resources" : ["secrets"]
  } : {}

  eks_managed_node_groups = merge(
    # 기본 bottlerocket 노드그룹 (config에서 enable_bottlerocket_nodegroup로 제어)
    try(local.eks.enable_bottlerocket_nodegroup, true) ? {
      bottlerocket = {
        name                     = join("-", [local.prefix, "eks", "nodegroup", "mgmt"])
        cluster_version          = lookup(local.eks, "version", "1.33")
        use_name_prefix          = false
        iam_role_name            = join("-", [local.prefix, "eks", "nodegroup", "mgmt"])
        iam_role_use_name_prefix = false

        ami_type = "BOTTLEROCKET_x86_64"
        platform = "bottlerocket"

        instance_types = [
          "m5.xlarge"
        ]
        capacity_type = "ON_DEMAND"

        taints = [
          {
            key    = "CoreAddonsOnly"
            value  = "true"
            effect = "NO_SCHEDULE"
          }
        ]

        labels = {
          generated = "terraform"
          team      = "devops"
          service   = "core-addons"
        }

        min_size     = 2
        max_size     = 25
        desired_size = 5
        tags = {
          Group    = "core-addons"
          Team     = "devops"
          NodeType = "core-addons"
        }
      }
    } : {},
    # 새로운 노드그룹 (config에서 enable_new_nodegroup로 제어)
    try(local.eks.enable_new_nodegroup, false) ? {
      eks_managed_node_groups_new = {
        name                     = join("-", [local.prefix, "eks", "nodegroup", "mgmt", "new"])
        cluster_version          = lookup(local.eks, "version", "1.33")
        use_name_prefix          = false
        iam_role_name            = join("-", [local.prefix, "eks", "nodegroup", "mgmt", "new"])
        iam_role_use_name_prefix = false

        ami_type = "BOTTLEROCKET_x86_64"
        platform = "bottlerocket"

        instance_types = [
          "m5.xlarge"
        ]
        capacity_type = "ON_DEMAND"

        taints = [
          {
            key    = "CoreAddonsOnly"
            value  = "true"
            effect = "NO_SCHEDULE"
          }
        ]

        labels = {
          generated = "terraform"
          team      = "devops"
          service   = "core-addons"
        }

        min_size     = 2
        max_size     = 25
        desired_size = 5
        tags = {
          Group    = "core-addons"
          Team     = "devops"
          NodeType = "core-addons"
        }
      }
    } : {}
  )

  iam_role_name            = join("-", [local.prefix, "eks", "nodegroup"])
  iam_role_use_name_prefix = true

  # Terraform manages minimal required access only
  # Additional users/roles are managed by GitOps
  manage_aws_auth_configmap = true
  aws_auth_roles = flatten([
    lookup(local.eks.auth_config, "roles", []),
    [
      {
        rolearn  = module.eks_blueprints_addons.karpenter.node_iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes",
        ]
      }
    ]
  ])

  # Users are managed by GitOps - empty list prevents Terraform from managing users
  aws_auth_users = []

  tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = join("-", [local.prefix, "eks"])
    "csmSecurity"            = "true"
    "ClusterName"            = join("-", [local.prefix, "eks"])
  })

  create_cloudwatch_log_group = false
}

# Attach EKS node roles to the managed policies (only when managed_policies are defined)
resource "aws_iam_role_policy_attachment" "karpenter_ebs_role" {
  count      = try(local.config.eks.enabled, false) && contains(keys(local.managed_policies), "eks_nodes_ebs-access") ? 1 : 0
  role       = module.eks_blueprints_addons.karpenter.node_iam_role_name
  policy_arn = aws_iam_policy.managed_policies["eks_nodes_ebs-access"].arn
}

resource "aws_iam_role_policy_attachment" "athena-glue-lakeformation-s3-full-access" {
  count      = try(local.config.eks.enabled, false) && contains(keys(local.managed_policies), "karpenter_athena-glue-lakeformation-s3-full-access-policy") ? 1 : 0
  role       = module.eks_blueprints_addons.karpenter.node_iam_role_name
  policy_arn = aws_iam_policy.managed_policies["karpenter_athena-glue-lakeformation-s3-full-access-policy"].arn
}

resource "aws_iam_role_policy_attachment" "node_group_coreaddons_ebs_role" {
  count      = try(local.config.eks.enabled, false) && try(local.eks.enable_bottlerocket_nodegroup, true) && contains(keys(local.managed_policies), "eks_nodes_ebs-access") ? 1 : 0
  role       = module.eks.eks_managed_node_groups.bottlerocket.iam_role_name
  policy_arn = aws_iam_policy.managed_policies["eks_nodes_ebs-access"].arn
}

resource "aws_iam_role_policy_attachment" "node_group_coreaddons_new_ebs_role" {
  count      = try(local.config.eks.enabled, false) && try(local.eks.enable_new_nodegroup, false) && contains(keys(local.managed_policies), "eks_nodes_ebs-access") ? 1 : 0
  role       = module.eks.eks_managed_node_groups.eks_managed_node_groups_new.iam_role_name
  policy_arn = aws_iam_policy.managed_policies["eks_nodes_ebs-access"].arn
}


resource "aws_eks_pod_identity_association" "associations" {
  for_each = local.pod_identity_associations

  cluster_name    = module.eks.cluster_name
  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = aws_iam_role.service_roles[each.key].arn
}
