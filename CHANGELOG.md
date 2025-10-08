# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.1] - 2025-10-08

### Fixed

- Remove hardcoded personal file paths from README.md deployment instructions
- Replace absolute paths with generic project directory names for better portability
- Use `s3_bucket_prefix` variable instead of hardcoded prefix in S3 bucket name
- Merge `additional_tags` variable into all resource tags for proper tag propagation

## [1.0.0] - 2025-09-27

### Added

- Initial Terraform backend infrastructure for Cloudflare Zero Trust Demo
- AWS S3 bucket with versioning and encryption for state storage
- DynamoDB table for state locking and consistency
- Comprehensive cost optimization settings with 30-day version retention
- Security-focused configuration with least privilege access
- IAM policy for Terraform state access
- GitHub Actions workflow for automated documentation generation using terraform-docs
- GitHub Actions workflow for security scanning using Semgrep
- Terraform-docs integration for automated README documentation
- Comprehensive `.gitignore` file for Terraform projects
- Example `terraform.tfvars.example` file for easy setup
- Cost analysis and deployment instructions in README
- Support for monitoring and alerting (optional)

### Security

- S3 bucket encryption with AES256
- DynamoDB encryption at rest enabled
- Public access blocked on S3 bucket
- Lifecycle protection on critical resources
- Secure GitHub Actions with pinned commit SHAs instead of version tags

### Documentation

- Comprehensive README with architecture diagrams
- Cost analysis and monthly estimates
- Step-by-step deployment instructions
- Troubleshooting guide
- Security features documentation
- Auto-generated Terraform documentation

[Unreleased]: https://github.com/macharpe/cloudflare-zero-trust-demo-backend/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/macharpe/cloudflare-zero-trust-demo-backend/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/macharpe/cloudflare-zero-trust-demo-backend/releases/tag/v1.0.0
