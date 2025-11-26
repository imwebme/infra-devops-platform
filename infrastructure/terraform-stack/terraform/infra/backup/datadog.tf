# locals {
#   vpc_endpoints_with_ips = { for name, endpoint in aws_vpc_endpoint.datadog : name => merge(endpoint, {
#     network_interfaces = { for id, ni in data.aws_network_interface.endpoint : id => ni.private_ips if contains(endpoint.network_interface_ids, id) },
#     private_ips        = flatten([for id, ni in data.aws_network_interface.endpoint : ni.private_ips if contains(endpoint.network_interface_ids, id)])
#   }) }
# }

# data "aws_network_interface" "endpoint" {
#   for_each = toset(flatten([for endpoint in aws_vpc_endpoint.datadog : endpoint.network_interface_ids]))
#   id       = each.key

#   provider = aws.virginia
# }

# data "aws_vpc" "virginia" {
#   default = true

#   provider = aws.virginia
# }

# data "aws_subnets" "virginia" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.virginia.id]
#   }

#   provider = aws.virginia
# }

# data "aws_security_group" "virginia" {
#   name   = "default"
#   vpc_id = data.aws_vpc.virginia.id

#   provider = aws.virginia
# }

# resource "aws_security_group_rule" "virginia" {
#   count = length(lookup(local.vpc_endpoints, "us-east-1", [])) > 0 ? 1 : 0

#   type              = "ingress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = data.aws_security_group.virginia.id

#   provider = aws.virginia
# }

# resource "aws_vpc_endpoint" "datadog" {
#   for_each            = try(local.vpc_endpoints["us-east-1"], {})
#   vpc_id              = data.aws_vpc.virginia.id
#   service_name        = each.value.service_name
#   vpc_endpoint_type   = each.value.type
#   private_dns_enabled = each.value.private_dns_enabled
#   subnet_ids          = each.value.type == "Interface" ? data.aws_subnets.virginia.ids : []
#   security_group_ids  = each.value.type == "Interface" ? [data.aws_security_group.virginia.id] : []
#   auto_accept         = true

#   tags = {
#     Name = format("%s-%s_%s", local.prefix, "vpc-endpoint", each.key)
#   }

#   provider = aws.virginia
# }

# data "aws_route53_zone" "datadog" {
#   name         = "datadoghq.com."
#   private_zone = true
#   vpc_id       = data.aws_vpc.virginia.id

#   depends_on = [module.zones]
# }

# resource "aws_route53_record" "datadog" {
#   for_each = local.vpc_endpoints_with_ips

#   zone_id = data.aws_route53_zone.datadog.zone_id
#   name    = "${each.key}.${data.aws_route53_zone.datadog.name}"
#   type    = "A"
#   ttl     = "5"

#   records = each.value.private_ips

#   depends_on = [module.zones]
# }
