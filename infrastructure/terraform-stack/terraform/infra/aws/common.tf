resource "aws_ec2_tag" "subnet_private_data_emr_tag" {
  count       = length(data.aws_subnets.private_data) > 0 ? length(data.aws_subnets.private_data) : 0
  resource_id = element(data.aws_subnets.private_data.ids, count.index)
  key         = "for-use-with-amazon-emr-managed-policies"
  value       = true
}
