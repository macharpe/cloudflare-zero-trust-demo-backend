#======================================================
# Backend Infrastructure Outputs
# Purpose: Provide resource information for main demo project
#======================================================

output "s3_bucket_name" {
  value       = aws_s3_bucket.terraform_state.bucket
  description = "Name of the S3 bucket for Terraform state storage"
  sensitive   = false
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "ARN of the S3 bucket for Terraform state storage"
  sensitive   = false
}

output "s3_bucket_region" {
  value       = aws_s3_bucket.terraform_state.region
  description = "AWS region where the S3 bucket is deployed"
  sensitive   = false
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_state_lock.name
  description = "Name of the DynamoDB table for state locking"
  sensitive   = false
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.terraform_state_lock.arn
  description = "ARN of the DynamoDB table for state locking"
  sensitive   = false
}

output "aws_region" {
  value       = var.aws_region
  description = "AWS region where backend infrastructure is deployed"
  sensitive   = false
}

output "iam_policy_arn" {
  value       = var.create_iam_policy ? aws_iam_policy.terraform_state_access[0].arn : null
  description = "ARN of the IAM policy for Terraform state access (if created)"
  sensitive   = false
}

output "backend_configuration_snippet" {
  value       = <<-EOT
    # Add this backend configuration to your main project's provider.tf:

    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.bucket}"
        key            = "demo/terraform.tfstate"
        region         = "${var.aws_region}"
        dynamodb_table = "${aws_dynamodb_table.terraform_state_lock.name}"
        encrypt        = true
      }
    }
  EOT
  description = "Backend configuration snippet for the main demo project"
  sensitive   = false
}

output "project_summary" {
  value       = <<-EOT
    Backend Infrastructure Summary:
    ==============================
    S3 Bucket: ${aws_s3_bucket.terraform_state.bucket}
    DynamoDB Table: ${aws_dynamodb_table.terraform_state_lock.name}
    AWS Region: ${var.aws_region}
    Project: ${var.project_name}
    Environment: ${var.environment}
    Owner: ${var.owner}

    Estimated Monthly Cost: ~$0.03-0.10 USD
    Estimated Annual Cost: ~$0.36-1.20 USD

    Features Enabled:
    - S3 Versioning: ${var.enable_s3_versioning ? "Yes" : "No"}
    - S3 Encryption: ${var.enable_s3_encryption ? "Yes" : "No"}
    - DynamoDB PITR: ${var.dynamodb_point_in_time_recovery ? "Yes" : "No"}
    - IAM Policy: ${var.create_iam_policy ? "Yes" : "No"}
    - CloudWatch Monitoring: ${var.enable_monitoring ? "Yes" : "No"}

    State Retention: ${var.state_version_retention_days} days
  EOT
  description = "Summary of backend infrastructure configuration and costs"
  sensitive   = false
}