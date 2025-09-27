#======================================================
# Backend Infrastructure Variables
#======================================================

variable "aws_region" {
  description = "AWS region for backend infrastructure deployment"
  type        = string
  default     = "eu-central-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must be in the format: us-east-1, eu-west-1, etc."
  }
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  type        = string
  default     = "tf-state-lock-cf-zero-trust"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.dynamodb_table_name))
    error_message = "DynamoDB table name can only contain letters, numbers, hyphens, underscores, and periods."
  }

  validation {
    condition     = length(var.dynamodb_table_name) >= 3 && length(var.dynamodb_table_name) <= 255
    error_message = "DynamoDB table name must be between 3 and 255 characters."
  }
}

variable "state_version_retention_days" {
  description = "Number of days to retain old versions of Terraform state files"
  type        = number
  default     = 30

  validation {
    condition     = var.state_version_retention_days >= 1 && var.state_version_retention_days <= 365
    error_message = "State version retention days must be between 1 and 365."
  }
}

variable "dynamodb_point_in_time_recovery" {
  description = "Enable point-in-time recovery for DynamoDB table (adds cost but provides backup)"
  type        = bool
  default     = false
}

variable "create_iam_policy" {
  description = "Whether to create an IAM policy for Terraform state access"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring for backend resources"
  type        = bool
  default     = false
}

variable "project_name" {
  description = "Name of the project using this backend"
  type        = string
  default     = "cloudflare-zero-trust-demo"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name can only contain lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "demo"

  validation {
    condition     = contains(["demo", "dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: demo, dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner of the backend infrastructure"
  type        = string
  default     = "macharpe"

  validation {
    condition     = length(var.owner) > 0
    error_message = "Owner cannot be empty."
  }
}

#======================================================
# Advanced Configuration Variables (Optional)
#======================================================

variable "s3_bucket_prefix" {
  description = "Prefix for S3 bucket name (will be combined with random suffix)"
  type        = string
  default     = "tf-state-cf-zero-trust"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.s3_bucket_prefix))
    error_message = "S3 bucket prefix must start and end with lowercase letters or numbers, and can contain hyphens."
  }

  validation {
    condition     = length(var.s3_bucket_prefix) >= 3 && length(var.s3_bucket_prefix) <= 50
    error_message = "S3 bucket prefix must be between 3 and 50 characters."
  }
}

variable "enable_s3_versioning" {
  description = "Enable versioning on the S3 bucket"
  type        = bool
  default     = true
}

variable "enable_s3_encryption" {
  description = "Enable server-side encryption on the S3 bucket"
  type        = bool
  default     = true
}

variable "additional_tags" {
  description = "Additional tags to apply to all backend resources"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key in keys(var.additional_tags) : can(regex("^[a-zA-Z0-9+\\-=._:/@\\s]+$", key))
    ])
    error_message = "Tag keys must contain only valid characters."
  }
}
