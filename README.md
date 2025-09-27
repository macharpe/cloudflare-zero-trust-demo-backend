# Terraform Backend Infrastructure

**Purpose**: Persistent backend infrastructure for storing Terraform state for the Cloudflare Zero Trust Demo project.

**Safety**: This infrastructure remains persistent even when the demo infrastructure is destroyed, ensuring state files are never lost.

## Overview

This project creates a dedicated AWS S3 + DynamoDB backend for Terraform state management. It is completely separate from the main demo infrastructure to prevent accidental destruction.

### Architecture

```
Backend Infrastructure (Persistent)
├── S3 Bucket: tf-state-cf-zero-trust-XXXXXXXX
│   ├── Versioning: Enabled
│   ├── Encryption: AES256
│   ├── Lifecycle: 30-day version retention
│   └── Public Access: Blocked
├── DynamoDB Table: tf-state-lock-cf-zero-trust
│   ├── Billing Mode: Pay-per-request
│   ├── Encryption: Enabled
│   └── PITR: Disabled (cost optimization)
└── IAM Policy: terraform-state-access-cf-zero-trust
    ├── S3 bucket access
    └── DynamoDB lock access
```

## Cost Analysis

**Estimated Monthly Costs** (eu-central-1):
- S3 Storage (~1-5MB): < $0.01
- S3 Requests (~50 ops): < $0.01
- DynamoDB (~100 ops): < $0.01
- **Total: ~$0.03-0.10/month ($0.36-1.20/year)**

## Deployment

### Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.12.0 installed

### Step 1: Deploy Backend Infrastructure

```bash
# Navigate to backend project
cd /Users/macharpe/Documents/4-github/cloudflare-zero-trust-demo-backend

# Initialize Terraform
terraform init

# Review planned resources
terraform plan

# Deploy backend infrastructure
terraform apply
```

### Step 2: Configure Main Demo Project

After successful deployment, update your main demo project's `provider.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "tf-state-cf-zero-trust-XXXXXXXX"  # From output
    key            = "demo/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "tf-state-lock-cf-zero-trust"
    encrypt        = true
  }
}
```

### Step 3: Migrate Demo State

```bash
# In your main demo project directory
cd /Users/macharpe/Documents/4-github/terraform-cloudflare-zero-trust-demo

# Backup current state
cp tfstate/terraform.tfstate tfstate/terraform.tfstate.backup-$(date +%Y%m%d-%H%M%S)

# Migrate to remote backend
terraform init -migrate-state
# Answer 'yes' when prompted
```

## Configuration

### Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `eu-central-1` | AWS region for backend |
| `dynamodb_table_name` | `tf-state-lock-cf-zero-trust` | DynamoDB table name |
| `state_version_retention_days` | `30` | S3 version retention |
| `project_name` | `cloudflare-zero-trust-demo` | Project identifier |
| `environment` | `demo` | Environment tag |

### Cost Optimization Features

- **Pay-per-request DynamoDB**: No provisioned capacity charges
- **30-day version retention**: Automatic cleanup of old state versions
- **No point-in-time recovery**: Disabled to reduce costs
- **Standard S3 storage**: Most cost-effective for small files

## Security Features

- **S3 Encryption**: AES256 server-side encryption
- **Public Access Blocked**: No public bucket access
- **DynamoDB Encryption**: Encryption at rest enabled
- **IAM Policy**: Least-privilege access to state resources
- **Lifecycle Protection**: `prevent_destroy` on critical resources

## Outputs

The backend project provides several outputs for easy integration:

- `s3_bucket_name`: S3 bucket name for state storage
- `dynamodb_table_name`: DynamoDB table for locking
- `backend_configuration_snippet`: Ready-to-use backend config
- `project_summary`: Complete cost and feature summary

## Maintenance

### Monitoring Costs

```bash
# Check S3 costs
aws s3api get-bucket-tagging --bucket <bucket-name>

# Check DynamoDB usage
aws dynamodb describe-table --table-name tf-state-lock-cf-zero-trust
```

### State Troubleshooting

```bash
# Unlock stuck state
terraform force-unlock <LOCK_ID>

# List state versions
aws s3api list-object-versions --bucket <bucket-name> --prefix demo/
```

### Backup Strategy

State files are automatically versioned in S3. To create additional backups:

```bash
# Download current state
aws s3 cp s3://<bucket-name>/demo/terraform.tfstate ./state-backup-$(date +%Y%m%d).tfstate
```

## Safety Guarantees

✅ **Separate Project**: Cannot be destroyed by demo `terraform destroy`
✅ **Prevent Destroy**: Lifecycle rules protect critical resources
✅ **Versioning**: Automatic state file history retention
✅ **Encryption**: Data encrypted at rest and in transit
✅ **Access Control**: IAM policy limits access scope

## File Structure

```
cloudflare-zero-trust-demo-backend/
├── main.tf              # Core infrastructure
├── variables.tf         # Input variables with validation
├── outputs.tf           # Resource outputs for integration
├── terraform.tfvars     # Configuration values
├── README.md           # This documentation
├── .gitignore          # Git ignore patterns
└── terraform.tfstate   # Local state for backend itself
```

## Troubleshooting

### Common Issues

1. **Permission Errors**: Verify AWS credentials and IAM permissions
2. **Bucket Name Conflicts**: S3 bucket names must be globally unique (random suffix added)
3. **Region Mismatches**: Ensure consistent AWS region configuration
4. **State Locks**: Use `terraform force-unlock` if operations are stuck

### Support

For issues specific to this backend infrastructure, check:
- AWS CloudTrail logs for API call failures
- Terraform state list: `terraform state list`
- Resource status: `terraform refresh`

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.12.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws) | ~> 6.0 |
| <a name="requirement_random"></a> [random](#requirement_random) | ~> 3.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider_aws) | ~> 6.0 |
| <a name="provider_random"></a> [random](#provider_random) | ~> 3.4 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_metric_alarm.dynamodb_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_dynamodb_table.terraform_state_lock](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_iam_policy.terraform_state_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_s3_bucket.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_notification.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_public_access_block.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [random_id.backend_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tags"></a> [additional_tags](#input_additional_tags) | Additional tags to apply to all backend resources | `map(string)` | `{}` | no |
| <a name="input_aws_region"></a> [aws_region](#input_aws_region) | AWS region for backend infrastructure deployment | `string` | `"eu-central-1"` | no |
| <a name="input_create_iam_policy"></a> [create_iam_policy](#input_create_iam_policy) | Whether to create an IAM policy for Terraform state access | `bool` | `true` | no |
| <a name="input_dynamodb_point_in_time_recovery"></a> [dynamodb_point_in_time_recovery](#input_dynamodb_point_in_time_recovery) | Enable point-in-time recovery for DynamoDB table (adds cost but provides backup) | `bool` | `false` | no |
| <a name="input_dynamodb_table_name"></a> [dynamodb_table_name](#input_dynamodb_table_name) | Name of the DynamoDB table for Terraform state locking | `string` | `"tf-state-lock-cf-zero-trust"` | no |
| <a name="input_enable_monitoring"></a> [enable_monitoring](#input_enable_monitoring) | Enable CloudWatch monitoring for backend resources | `bool` | `false` | no |
| <a name="input_enable_s3_encryption"></a> [enable_s3_encryption](#input_enable_s3_encryption) | Enable server-side encryption on the S3 bucket | `bool` | `true` | no |
| <a name="input_enable_s3_versioning"></a> [enable_s3_versioning](#input_enable_s3_versioning) | Enable versioning on the S3 bucket | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input_environment) | Environment name for resource tagging | `string` | `"demo"` | no |
| <a name="input_owner"></a> [owner](#input_owner) | Owner of the backend infrastructure | `string` | `"macharpe"` | no |
| <a name="input_project_name"></a> [project_name](#input_project_name) | Name of the project using this backend | `string` | `"cloudflare-zero-trust-demo"` | no |
| <a name="input_s3_bucket_prefix"></a> [s3_bucket_prefix](#input_s3_bucket_prefix) | Prefix for S3 bucket name (will be combined with random suffix) | `string` | `"tf-state-cf-zero-trust"` | no |
| <a name="input_state_version_retention_days"></a> [state_version_retention_days](#input_state_version_retention_days) | Number of days to retain old versions of Terraform state files | `number` | `30` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_region"></a> [aws_region](#output_aws_region) | AWS region where backend infrastructure is deployed |
| <a name="output_backend_configuration_snippet"></a> [backend_configuration_snippet](#output_backend_configuration_snippet) | Backend configuration snippet for the main demo project |
| <a name="output_dynamodb_table_arn"></a> [dynamodb_table_arn](#output_dynamodb_table_arn) | ARN of the DynamoDB table for state locking |
| <a name="output_dynamodb_table_name"></a> [dynamodb_table_name](#output_dynamodb_table_name) | Name of the DynamoDB table for state locking |
| <a name="output_iam_policy_arn"></a> [iam_policy_arn](#output_iam_policy_arn) | ARN of the IAM policy for Terraform state access (if created) |
| <a name="output_project_summary"></a> [project_summary](#output_project_summary) | Summary of backend infrastructure configuration and costs |
| <a name="output_s3_bucket_arn"></a> [s3_bucket_arn](#output_s3_bucket_arn) | ARN of the S3 bucket for Terraform state storage |
| <a name="output_s3_bucket_name"></a> [s3_bucket_name](#output_s3_bucket_name) | Name of the S3 bucket for Terraform state storage |
| <a name="output_s3_bucket_region"></a> [s3_bucket_region](#output_s3_bucket_region) | AWS region where the S3 bucket is deployed |
<!-- END_TF_DOCS -->

---

**⚠️ Important**: This infrastructure should remain persistent throughout the lifecycle of your demo project. Only destroy it when permanently decommissioning the demo environment.