resource "aws_ec2_tag" "subnet_private_eks_common_tag" {
  count       = length(data.aws_subnets.private_eks) > 0 ? length(data.aws_subnets.private_eks) : 0
  resource_id = element(data.aws_subnets.private_eks.ids, count.index)
  key         = "kubernetes.io/cluster/${join("-", [local.prefix, "eks"])}"
  value       = "shared"
}

resource "aws_ec2_tag" "subnet_private_eks_karpenter_tag" {
  count       = length(data.aws_subnets.private_eks) > 0 ? length(data.aws_subnets.private_eks) : 0
  resource_id = element(data.aws_subnets.private_eks.ids, count.index)
  key         = "karpenter.sh/discovery"
  value       = join("-", [local.prefix, "eks"])
}

resource "aws_ec2_tag" "subnet_public_eks_elb_tag" {
  count       = length(data.aws_subnets.public_net) > 0 ? length(data.aws_subnets.public_net) : 0
  resource_id = element(data.aws_subnets.public_net.ids, count.index)
  key         = "kubernetes.io/role/elb"
  value       = 1
}

resource "aws_ec2_tag" "subnet_private_eks_elb_tag" {
  count       = length(data.aws_subnets.private_net) > 0 ? length(data.aws_subnets.private_net) : 0
  resource_id = element(data.aws_subnets.private_net.ids, count.index)
  key         = "kubernetes.io/role/internal-elb"
  value       = 1
}
