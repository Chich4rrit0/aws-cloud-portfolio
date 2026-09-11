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
