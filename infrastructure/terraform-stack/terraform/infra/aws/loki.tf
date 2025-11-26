
# S3 Buckets with SSE-S3 encryption
resource "aws_s3_bucket" "loki-store" {
  count  = local.loki.enabled ? 1 : 0
  bucket = "alwayz-${local.env}-loki-store"
  tags = {
    Group = "loki"
    Team  = "devops"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket" "loki-chunks" {
  count  = local.loki.enabled ? 1 : 0
  bucket = "alwayz-${local.env}-loki-chunks"
  tags = {
    Group = "loki"
    Team  = "devops"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket" "loki-ruler" {
  count  = local.loki.enabled ? 1 : 0
  bucket = "alwayz-${local.env}-loki-ruler"
  tags = {
    Group = "loki"
    Team  = "devops"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket" "loki-admin" {
  count  = local.loki.enabled ? 1 : 0
  bucket = "alwayz-${local.env}-loki-admin"
  tags = {
    Group = "loki"
    Team  = "devops"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Versioning
resource "aws_s3_bucket_versioning" "loki-store-versioning" {
  count  = local.loki.enabled ? 1 : 0
  bucket = aws_s3_bucket.loki-store[0].id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_versioning" "loki-chunks-versioning" {
  count  = local.loki.enabled ? 1 : 0
  bucket = aws_s3_bucket.loki-chunks[0].id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_versioning" "loki-ruler-versioning" {
  count  = local.loki.enabled ? 1 : 0
  bucket = aws_s3_bucket.loki-ruler[0].id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_versioning" "loki-admin-versioning" {
  count  = local.loki.enabled ? 1 : 0
  bucket = aws_s3_bucket.loki-admin[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "loki-store-lifecycle" {
  count  = local.loki.enabled ? 1 : 0
  bucket = aws_s3_bucket.loki-store[0].id
  rule {
    id     = "delete-old-files"
    status = "Enabled"
    filter { prefix = "" }
    noncurrent_version_expiration { noncurrent_days = 7 }
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "loki-chunks-lifecycle" {
  count  = local.loki.enabled ? 1 : 0
  bucket = aws_s3_bucket.loki-chunks[0].id
  rule {
    id     = "delete-old-files"
    status = "Enabled"
    filter { prefix = "" }
    noncurrent_version_expiration { noncurrent_days = 7 }
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "loki-ruler-lifecycle" {
  count  = local.loki.enabled ? 1 : 0
  bucket = aws_s3_bucket.loki-ruler[0].id
  rule {
    id     = "delete-old-files"
    status = "Enabled"
    filter { prefix = "" }
    noncurrent_version_expiration { noncurrent_days = 7 }
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "loki-admin-lifecycle" {
  count  = local.loki.enabled ? 1 : 0
  bucket = aws_s3_bucket.loki-admin[0].id
  rule {
    id     = "delete-old-files"
    status = "Enabled"
    filter { prefix = "" }
    noncurrent_version_expiration { noncurrent_days = 7 }
  }
}