variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_prefix" {
  type    = string
  default = "portfolio-p03-e2e"
}

variable "frontend_bucket_name" { type = string }
variable "frontend_bucket_arn" { type = string }
variable "alb_dns_name" { type = string }
variable "listener_arn" { type = string }
variable "target_group_arn" { type = string }

variable "origin_header_parameter_name" {
  type    = string
  default = "/portfolio/project-03-e2e/cloudfront/origin-header"
}

variable "origin_header_value" {
  type      = string
  sensitive = true
}
