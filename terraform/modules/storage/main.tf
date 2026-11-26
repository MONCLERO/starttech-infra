
# ----- AWS ACCOUNT ID ----- #

data "aws_caller_identity" "current" {}

# ----- RESOURCE NAMING ----- #

locals {
  bucket_name = "${var.frontend_bucket_prefix}-${data.aws_caller_identity.current.account_id}"

  common_tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

# ==================================================
# S3 FRONTEND BUCKET
# ==================================================

resource "aws_s3_bucket" "frontend" {
  bucket = local.bucket_name

  tags = merge(local.common_tags, {
    Name = local.bucket_name
  })
}

# ----- S3 VERSIONING ----- #

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ----- S3 SERVER-SIDE ENCRYPTION ----- #

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ----- S3 PUBLIC ACCESS BLOCK ----- #

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ----- S3 OBJECT OWNERSHIP ----- #

resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# ==================================================
# ECR BACKEND REPOSITORY
# ==================================================

resource "aws_ecr_repository" "backend" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  # Scan images automatically when they are pushed.
  image_scanning_configuration {
    scan_on_push = true
  }

  # Encrypt repository images at rest.
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.common_tags, {
    Name = var.ecr_repository_name
  })
}

# ----- ECR IMAGE LIFECYCLE POLICY ----- #

resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Retain only the latest 10 images"

        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
}
