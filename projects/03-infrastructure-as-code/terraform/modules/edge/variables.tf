variable "project_prefix" { type = string }
variable "frontend_bucket_name" { type = string }
variable "frontend_bucket_arn" { type = string }
variable "alb_dns_name" { type = string }
variable "listener_arn" { type = string }
variable "target_group_arn" { type = string }
variable "origin_header_value" {
  type      = string
  sensitive = true
}
