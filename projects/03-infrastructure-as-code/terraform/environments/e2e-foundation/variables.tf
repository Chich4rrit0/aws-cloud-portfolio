variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_prefix" {
  type    = string
  default = "portfolio-p03-e2e"
}

variable "vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "availability_zones" {
  type = list(string)
}

variable "cloudfront_origin_prefix_list_id" {
  type = string
}

variable "database_master_username" {
  type    = string
  default = "portfolio_master"
}

variable "database_master_password" {
  type      = string
  sensitive = true
}

variable "application_password_parameter_name" {
  type    = string
  default = "/portfolio/project-03-e2e/database/password"
}
