variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "project_prefix" {
  type    = string
  default = "portfolio-p03-e2e"
}
variable "vpc_id" { type = string }
variable "public_edge_subnet_ids" { type = list(string) }
variable "public_application_subnet_ids" { type = list(string) }
variable "load_balancer_security_group_id" { type = string }
variable "application_security_group_id" { type = string }
variable "ec2_instance_profile_name" { type = string }
variable "ec2_role_name" { type = string }
variable "artifact_bucket_name" { type = string }
variable "artifact_bucket_arn" { type = string }
variable "artifact_key" { type = string }
variable "database_endpoint_address" { type = string }
variable "application_database_password_parameter_name" {
  type    = string
  default = "/portfolio/project-03-e2e/database/password"
}
