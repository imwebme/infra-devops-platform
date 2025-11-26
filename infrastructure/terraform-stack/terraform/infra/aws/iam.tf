# Create IAM roles for service pods
resource "aws_iam_role" "service_roles" {
  for_each = local.service_roles

  name               = "${local.prefix}-eks-pod-identity-${each.value.name}"
  assume_role_policy = file("${path.module}/policies/base/pod-identity-assume-role.json")
}

# Attach inline policies to service roles
resource "aws_iam_role_policy" "service_role_policies" {
  for_each = merge([
    for role_key, role in local.service_roles : {
      for policy in role.policies : "${role_key}_${policy.name}" => {
        role_key    = role_key
        role_name   = role.name
        policy_name = policy.name
        policy_file = policy.file
      }
    }
  ]...)

  name   = each.value.policy_name
  role   = aws_iam_role.service_roles[each.value.role_key].id
  policy = file("${path.module}/policies/${each.value.policy_file}")
}

# Create managed policies for EKS nodes
resource "aws_iam_policy" "managed_policies" {
  for_each = merge([
    for role_key, role in local.managed_policies : {
      for policy in role.policies : "${role_key}_${policy.name}" => {
        role_key    = role_key
        policy_name = policy.name
        policy_file = policy.file
      }
    }
  ]...)

  name        = "${local.prefix}-${each.value.role_key}-${each.value.policy_name}"
  description = "Managed policy for ${each.value.role_key} ${each.value.policy_name}"
  policy      = file("${path.module}/policies/${each.value.policy_file}")
}
