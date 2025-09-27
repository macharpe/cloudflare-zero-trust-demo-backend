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

**Estimated Monthly Costs** (US East-1):
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
    region         = "us-east-1"
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
| `aws_region` | `us-east-1` | AWS region for backend |
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
<!-- END_TF_DOCS -->

---

**⚠️ Important**: This infrastructure should remain persistent throughout the lifecycle of your demo project. Only destroy it when permanently decommissioning the demo environment.