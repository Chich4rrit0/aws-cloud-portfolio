variable "aws_region" {
  description = "AWS region for the isolated lab reconstruction."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "Project 03 is intentionally scoped to us-east-1."
  }
}

variable "project_prefix" {
  description = "Short lowercase prefix for isolated Project 03 resource names."
  type        = string
  default     = "portfolio-p03"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_prefix))
    error_message = "project_prefix must contain lowercase letters, numbers or hyphens only."
  }
}

variable "environment" {
  description = "Environment label used for tags and names."
  type        = string
  default     = "lab"

  validation {
    condition     = var.environment == "lab"
    error_message = "The approved Project 03 environment is lab."
  }
}

variable "vpc_cidr" {
  description = "CIDR for the isolated Project 03 VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zone_a" {
  description = "First verified availability-zone label for this AWS account."
  type        = string
}

variable "availability_zone_b" {
  description = "Second verified availability-zone label for this AWS account."
  type        = string
}

variable "cloudfront_origin_prefix_list_id" {
  description = "Regional CloudFront origin-facing managed prefix-list ID, supplied only for an approved plan."
  type        = string
}

variable "database_password_parameter_name" {
  description = "SSM SecureString path only; never its value."
  type        = string
  default     = "/portfolio/project-03/database/password"
}

variable "database_master_username" {
  description = "RDS master username for a future isolated deployment."
  type        = string
  default     = "portfolio_master"
}

variable "database_master_password" {
  description = "Sensitive RDS master password, supplied only at an approved deployment time."
  type        = string
  sensitive   = true
}

variable "application_database_password_parameter_name" {
  description = "SecureString path for the application database user password."
  type        = string
  default     = "/portfolio/project-03/database/password"
}

variable "application_artifact_key" {
  description = "Approved private S3 release key for a future deployment."
  type        = string
  default     = "releases/REPLACE_WITH_APPROVED_RELEASE.zip"
}

variable "cloudfront_origin_header_value" {
  description = "Sensitive origin-only header, supplied only for an approved deployment."
  type        = string
  sensitive   = true
}

variable "cloudfront_origin_header_parameter_name" {
  description = "SecureString parameter name for the CloudFront-to-ALB origin header."
  type        = string
  default     = "/portfolio/project-03/cloudfront/origin-header"
}
