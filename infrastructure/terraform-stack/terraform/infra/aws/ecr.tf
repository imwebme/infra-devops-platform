resource "aws_kms_key" "alwayz-ecr-kms-key" {
  description = "KMS key for ECR"
}

resource "aws_kms_alias" "alwayz-ecr-kms-alias" {
  # name          = "alias/${local.env}/ecr-kms-key"
  name          = join("/", compact(["alias", local.category, local.env, "ecr-kms-key"]))
  target_key_id = aws_kms_key.alwayz-ecr-kms-key.key_id
}

resource "aws_ecr_repository" "alwayz-repo" {
  for_each             = toset(local.repository_names)
  name                 = format("%s-ecr_%s", local.prefix, each.key)
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.alwayz-ecr-kms-key.arn
  }
}

resource "aws_ecr_lifecycle_policy" "alwayz-repo-lifecycle-policy" {
  for_each   = toset(local.repository_names)
  repository = aws_ecr_repository.alwayz-repo[each.key].name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 100 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 100
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}