output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = module.vpc.default_security_group_id
}

output "default_network_acl_id" {
  description = "The ID of the default network ACL"
  value       = module.vpc.default_network_acl_id
}

output "default_route_table_id" {
  description = "The ID of the default route table"
  value       = module.vpc.default_route_table_id
}

output "vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value       = module.vpc.vpc_instance_tenancy
}

output "vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value       = module.vpc.vpc_enable_dns_support
}

output "vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value       = module.vpc.vpc_enable_dns_hostnames
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value       = module.vpc.vpc_main_route_table_id
}

output "vpc_ipv6_association_id" {
  description = "The association ID for the IPv6 CIDR block"
  value       = module.vpc.vpc_ipv6_association_id
}

output "vpc_ipv6_cidr_block" {
  description = "The IPv6 CIDR block"
  value       = module.vpc.vpc_ipv6_cidr_block
}

output "vpc_secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks of the VPC"
  value       = module.vpc.vpc_secondary_cidr_blocks
}

output "vpc_owner_id" {
  description = "The ID of the AWS account that owns the VPC"
  value       = module.vpc.vpc_owner_id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = module.vpc.private_subnet_arns
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = module.vpc.private_subnets_cidr_blocks
}

output "private_subnets_ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of private subnets in an IPv6 enabled VPC"
  value       = module.vpc.private_subnets_ipv6_cidr_blocks
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "database_subnet_arns" {
  description = "List of ARNs of database subnets"
  value       = module.vpc.database_subnet_arns
}

output "database_subnets_cidr_blocks" {
  description = "List of cidr_blocks of database subnets"
  value       = module.vpc.database_subnets_cidr_blocks
}

output "database_subnets_ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of database subnets in an IPv6 enabled VPC"
  value       = module.vpc.database_subnets_ipv6_cidr_blocks
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = module.vpc.public_subnet_arns
}

output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = module.vpc.public_subnets_cidr_blocks
}

output "public_subnets_ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of public subnets in an IPv6 enabled VPC"
  value       = module.vpc.public_subnets_ipv6_cidr_blocks
}

output "outpost_subnets" {
  description = "List of IDs of outpost subnets"
  value       = module.vpc.outpost_subnets
}

output "outpost_subnet_arns" {
  description = "List of ARNs of outpost subnets"
  value       = module.vpc.outpost_subnet_arns
}

output "outpost_subnets_cidr_blocks" {
  description = "List of cidr_blocks of outpost subnets"
  value       = module.vpc.outpost_subnets_cidr_blocks
}

output "outpost_subnets_ipv6_cidr_blocks" {
  description = "List of IPv6 cidr_blocks of outpost subnets in an IPv6 enabled VPC"
  value       = module.vpc.outpost_subnets_ipv6_cidr_blocks
}

output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = module.vpc.private_route_table_ids
}

output "public_internet_gateway_route_id" {
  description = "ID of the internet gateway route"
  value       = module.vpc.public_internet_gateway_route_id
}

output "public_internet_gateway_ipv6_route_id" {
  description = "ID of the IPv6 internet gateway route"
  value       = module.vpc.public_internet_gateway_ipv6_route_id
}

output "private_nat_gateway_route_ids" {
  description = "List of IDs of the private nat gateway route"
  value       = module.vpc.private_nat_gateway_route_ids
}

output "private_ipv6_egress_route_ids" {
  description = "List of IDs of the ipv6 egress route"
  value       = module.vpc.private_ipv6_egress_route_ids
}

output "private_route_table_association_ids" {
  description = "List of IDs of the private route table association"
  value       = module.vpc.private_route_table_association_ids
}

output "public_route_table_association_ids" {
  description = "List of IDs of the public route table association"
  value       = module.vpc.public_route_table_association_ids
}

output "dhcp_options_id" {
  description = "The ID of the DHCP options"
  value       = module.vpc.dhcp_options_id
}

output "nat_ids" {
  description = "List of allocation ID of Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_ids
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

output "natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

output "igw_arn" {
  description = "The ARN of the Internet Gateway"
  value       = module.vpc.igw_arn
}

output "egress_only_internet_gateway_id" {
  description = "The ID of the egress only Internet Gateway"
  value       = module.vpc.egress_only_internet_gateway_id
}

output "vgw_id" {
  description = "The ID of the VPN Gateway"
  value       = module.vpc.vgw_id
}

output "vgw_arn" {
  description = "The ARN of the VPN Gateway"
  value       = module.vpc.vgw_arn
}

output "default_vpc_id" {
  description = "The ID of the Default VPC"
  value       = module.vpc.default_vpc_id
}

output "default_vpc_arn" {
  description = "The ARN of the Default VPC"
  value       = module.vpc.default_vpc_arn
}

output "default_vpc_cidr_block" {
  description = "The CIDR block of the Default VPC"
  value       = module.vpc.default_vpc_cidr_block
}

output "default_vpc_default_security_group_id" {
  description = "The ID of the security group created by default on Default VPC creation"
  value       = module.vpc.default_vpc_default_security_group_id
}

output "default_vpc_default_network_acl_id" {
  description = "The ID of the default network ACL of the Default VPC"
  value       = module.vpc.default_vpc_default_network_acl_id
}

output "default_vpc_default_route_table_id" {
  description = "The ID of the default route table of the Default VPC"
  value       = module.vpc.default_vpc_default_route_table_id
}

output "default_vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within Default VPC"
  value       = module.vpc.default_vpc_instance_tenancy
}

output "default_vpc_enable_dns_support" {
  description = "Whether or not the Default VPC has DNS support"
  value       = module.vpc.default_vpc_enable_dns_support
}

output "default_vpc_enable_dns_hostnames" {
  description = "Whether or not the Default VPC has DNS hostname support"
  value       = module.vpc.default_vpc_enable_dns_hostnames
}

output "default_vpc_main_route_table_id" {
  description = "The ID of the main route table associated with the Default VPC"
  value       = module.vpc.default_vpc_main_route_table_id
}

output "public_network_acl_id" {
  description = "ID of the public network ACL"
  value       = module.vpc.public_network_acl_id
}

output "public_network_acl_arn" {
  description = "ARN of the public network ACL"
  value       = module.vpc.public_network_acl_arn
}

output "private_network_acl_id" {
  description = "ID of the private network ACL"
  value       = module.vpc.private_network_acl_id
}

output "private_network_acl_arn" {
  description = "ARN of the private network ACL"
  value       = module.vpc.private_network_acl_arn
}

output "outpost_network_acl_id" {
  description = "ID of the outpost network ACL"
  value       = module.vpc.outpost_network_acl_id
}

output "outpost_network_acl_arn" {
  description = "ARN of the outpost network ACL"
  value       = module.vpc.outpost_network_acl_arn
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = <<-EOT
    export KUBECONFIG="/tmp/${module.eks.cluster_name}"
    aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}
  EOT
}

output "configure_argocd" {
  description = "Terminal Setup"
  value       = <<-EOT
    export KUBECONFIG="/tmp/${module.eks.cluster_name}"
    aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}
    export ARGOCD_OPTS="--port-forward --port-forward-namespace argocd --grpc-web"
    kubectl config set-context --current --namespace argocd
    argocd login --port-forward --username admin --password $(aws secretsmanager get-secret-value --secret-id ${join("/", compact([local.category, local.env, "argocd"]))} --region ${var.region} --output json | jq -r .SecretString | jq -r .ADMIN_PASSWORD)

    echo "ArgoCD Username: admin"
    echo "ArgoCD Password: $(aws secretsmanager get-secret-value --secret-id ${join("/", compact([local.category, local.env, "argocd"]))} --region ${var.region} --output json | jq -r .SecretString | jq -r .ADMIN_PASSWORD)"
    echo Port Forward: http://localhost:8080
    kubectl port-forward -n argocd svc/argo-cd-argocd-server 8080:80
    EOT
}
#echo "ArgoCD Password: $(kubectl get secrets argocd-initial-admin-secret -n argocd --template="{{index .data.password | base64decode}}")"
output "access_argocd" {
  description = "ArgoCD Access"
  value       = <<-EOT
    export KUBECONFIG="/tmp/${module.eks.cluster_name}"
    aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}
    echo "ArgoCD Username: admin"
    echo "ArgoCD Password: $(aws secretsmanager get-secret-value --secret-id ${join("/", compact([local.category, local.env, "argocd"]))} --region ${var.region} --output json | jq -r .SecretString | jq -r .ADMIN_PASSWORD)"
    echo "ArgoCD URL: https://$(kubectl get svc -n argocd argo-cd-argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
    EOT
}

output "route53_zone_zone_id" {
  description = "Zone ID of Route53 zone"
  value       = module.public_zones.route53_zone_zone_id
}

# RDS Outputs
output "rds_cluster_endpoints" {
  description = "Aurora cluster endpoints"
  value = {
    for k, v in aws_rds_cluster.aurora : k => {
      endpoint        = v.endpoint
      reader_endpoint = v.reader_endpoint
      port            = v.port
      database_name   = v.database_name
      master_username = v.master_username
    }
  }
  sensitive = true
}

output "rds_instance_endpoints" {
  description = "RDS instance endpoints"
  value = {
    for k, v in aws_db_instance.standalone : k => {
      endpoint = v.endpoint
      port     = v.port
      db_name  = v.db_name
      username = v.username
    }
  }
  sensitive = true
}

output "rds_security_group_ids" {
  description = "RDS security group IDs"
  value = {
    for k, v in aws_security_group.rds : k => v.id
  }
}

output "rds_subnet_group_names" {
  description = "RDS subnet group names"
  value = {
    for k, v in aws_db_subnet_group.main : k => v.name
  }
}

output "rds_parameter_group_names" {
  description = "RDS parameter group names"
  value = merge(
    {
      for k, v in aws_db_parameter_group.postgresql : k => v.name
    },
    {
      for k, v in aws_rds_cluster_parameter_group.aurora_postgresql : k => v.name
    },
    {
      for k, v in aws_rds_cluster_parameter_group.aurora_mysql : k => v.name
    }
  )
}

output "sonarqube_rds_endpoint" {
  description = "SonarQube RDS endpoint"
  value       = try(aws_db_instance.standalone["sonarqube"].endpoint, "")
  sensitive   = false
}

output "sonarqube_rds_port" {
  description = "SonarQube RDS port"
  value       = try(aws_db_instance.standalone["sonarqube"].port, "")
}

################################################################################
# GitOps Bootstrap Outputs
################################################################################
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "workspace_repo_url" {
  description = "GitOps workspace repository URL"
  value       = try(local.config.gitops.workspace_repo_url, "https://github.com/wetripod/alwayz-gitops-manifest")
}

output "gitops_config" {
  description = "GitOps configuration for automation"
  value = {
    cluster_name       = module.eks.cluster_name
    workspace_repo_url = try(local.config.gitops.workspace_repo_url, "https://github.com/wetripod/alwayz-gitops-manifest")
    environment        = local.env
    category           = local.category
    region             = var.region
    argocd_namespace   = "argocd"
  }
}

output "argocd_admin_password_bcrypt" {
  description = "ArgoCD admin password (bcrypt hashed) for Helm installation"
  value       = bcrypt_hash.argocd_admin_password.id
  sensitive   = true
}



