#======================================================
# Terraform Backend Infrastructure
# Purpose: Persistent S3 + DynamoDB backend for Cloudflare Zero Trust Demo
# Safety: This infrastructure persists even when demo is destroyed
#======================================================

terraform {
  required_version = ">= 1.12.0"

  # Local backend for the backend infrastructure itself
  backend "local" {
    path = "terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "cloudflare-zero-trust-demo-backend"
      Environment = "persistent"
      Purpose     = "terraform-state-management"
      Owner       = "macharpe"
      ManagedBy   = "terraform"
    }
  }
}

#======================================================
# Random Suffix for Global Uniqueness
#======================================================
resource "random_id" "backend_suffix" {
  byte_length = 4
}

#======================================================
# S3 Bucket for Terraform State Storage
#======================================================
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.s3_bucket_prefix}-${random_id.backend_suffix.hex}"

  lifecycle {
    prevent_destroy = true # Extra protection against accidental deletion
  }

  tags = merge(
    {
      Name        = "Terraform State Bucket"
      Description = "Stores Terraform state for Cloudflare Zero Trust Demo"
    },
    var.additional_tags
  )
}

# Enable versioning for state file history
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption for security
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block all public access for security
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle configuration to manage costs
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  depends_on = [aws_s3_bucket_versioning.terraform_state]
  bucket     = aws_s3_bucket.terraform_state.id

  rule {
    id     = "state_file_lifecycle"
    status = "Enabled"

    # Apply to all objects in bucket
    filter {
      prefix = ""
    }

    # Delete old versions to control costs
    noncurrent_version_expiration {
      noncurrent_days = var.state_version_retention_days
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# Optional: Notification configuration for monitoring
resource "aws_s3_bucket_notification" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  # You can add SNS/SQS notifications here if needed
  # For now, we'll keep it simple
}

#======================================================
# DynamoDB Table for State Locking
#======================================================
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST" # Most cost-effective for demo usage
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Encryption at rest
  server_side_encryption {
    enabled = true
  }

  # Disable point-in-time recovery to save costs (not critical for state locking)
  point_in_time_recovery {
    enabled = var.dynamodb_point_in_time_recovery
  }

  lifecycle {
    prevent_destroy = true # Extra protection against accidental deletion
  }

  tags = merge(
    {
      Name        = "Terraform State Lock Table"
      Description = "Provides state locking for Terraform operations"
    },
    var.additional_tags
  )
}

#======================================================
# IAM Policy for Terraform State Access (Optional)
#======================================================
resource "aws_iam_policy" "terraform_state_access" {
  count       = var.create_iam_policy ? 1 : 0
  name        = "terraform-state-access-cf-zero-trust"
  path        = "/"
  description = "IAM policy for Terraform state bucket and DynamoDB access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3StateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning"
        ]
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
      },
      {
        Sid    = "DynamoDBLockAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.terraform_state_lock.arn
      }
    ]
  })

  tags = merge(
    {
      Name        = "Terraform State Access Policy"
      Description = "Grants access to Terraform state resources"
    },
    var.additional_tags
  )
}

#======================================================
# CloudWatch Alarms for Monitoring (Optional)
#======================================================
resource "aws_cloudwatch_metric_alarm" "dynamodb_errors" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "terraform-state-lock-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "SystemErrors"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors DynamoDB errors for Terraform state locking"

  dimensions = {
    TableName = aws_dynamodb_table.terraform_state_lock.name
  }

  tags = merge(
    {
      Name = "Terraform State Lock Monitoring"
    },
    var.additional_tags
  )
}