# variable "argocd_admin_password" {
#   type        = string
#   description = "The password to use for the `admin` Argo CD user."
# }

variable "enable_git_ssh" {
  description = "Use git ssh to access all git repos using format git@github.com:<org>"
  type        = bool
  default     = false
}
variable "ssh_key_path" {
  description = "SSH key path for git access"
  type        = string
  default     = "~/.ssh/id_rsa"
}
variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "172.0.0.0/16"
}
variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}
variable "addons" {
  description = "Kubernetes addons"
  type        = any
  default = {
    # aws
    enable_cert_manager                 = true
    enable_aws_ebs_csi_resources        = true # generate gp2 and gp3 storage classes for ebs-csi
    enable_aws_cloudwatch_metrics       = false
    enable_external_secrets             = true
    enable_aws_load_balancer_controller = true
    enable_aws_for_fluentbit            = false
    enable_karpenter                    = true
    enable_aws_ingress_nginx            = true # inginx configured with AWS NLB
    # oss
    enable_metrics_server = true
    enable_kyverno        = true
    # Enable if want argo manage argo from gitops
    enable_argocd = true

    enable_aws_efs_csi_driver                    = true
    enable_aws_fsx_csi_driver                    = false
    enable_aws_privateca_issuer                  = false
    enable_cluster_autoscaler                    = true
    enable_external_dns                          = true
    enable_fargate_fluentbit                     = false
    enable_aws_node_termination_handler          = false
    enable_velero                                = false
    enable_aws_gateway_api_controller            = false
    enable_aws_secrets_store_csi_driver_provider = false
    enable_ack_apigatewayv2                      = false
    enable_ack_dynamodb                          = false
    enable_ack_s3                                = false
    enable_ack_rds                               = false
    enable_ack_prometheusservice                 = false
    enable_ack_emrcontainers                     = false
    enable_ack_sfn                               = false
    enable_ack_eventbridge                       = false

    enable_argo_rollouts                   = true
    enable_argo_events                     = false
    enable_argo_workflows                  = false
    enable_cluster_proportional_autoscaler = false
    enable_gatekeeper                      = false
    enable_gpu_operator                    = false
    enable_ingress_nginx                   = false
    enable_kube_prometheus_stack           = false
    enable_prometheus_adapter              = false
    enable_secrets_store_csi_driver        = false
    enable_vpa                             = false
  }
}

variable "gitops_org_username" {
  description = "Git org system account"
  type        = string
  sensitive   = true
}

variable "gitops_org_password" {
  description = "PAT of Git org system account"
  type        = string
  sensitive   = true
}

variable "argocd_slack_token" {
  description = "ArgoCD slack token"
  type        = string
  sensitive   = true
}

variable "github_clientid" {
  description = "Github client id"
  type        = string
  sensitive   = true
}

variable "github_clientsecret" {
  description = "Github client secret"
  type        = string
  sensitive   = true
}

variable "AWS_SECRET_ACCESS_KEY" {
  default = ""
}

variable "AWS_ACCESS_KEY_ID" {
  default = ""
}

variable "rds_pw" {
  type      = string
  sensitive = true
  default   = "default_password"
}

variable "rds_user" {
  type    = string
  default = "admin"
}

variable "mlflow_postgresql_password" {
  type      = string
  sensitive = true
  default   = "default_password"
}

variable "mlflow_postgresql_username" {
  type    = string
  default = "admin"
}