resource "aws_secretsmanager_secret" "secrets" {
  for_each                = local.secretmanagers
  name                    = join("/", compact([local.org, local.category, local.env, each.key]))
  description             = "Secret for ${each.key}"
  recovery_window_in_days = 0 # Set to zero for this example to force delete during Terraform destroy
}

resource "aws_secretsmanager_secret_version" "secrets_version" {
  for_each      = local.secretmanagers
  secret_id     = aws_secretsmanager_secret.secrets[each.key].id
  secret_string = jsonencode(each.value)

  lifecycle {
    ignore_changes = [secret_string]
  }
}
