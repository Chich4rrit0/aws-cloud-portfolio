variable "project_prefix" { type = string }
variable "environment" { type = string }
variable "private_database_subnet_ids" { type = list(string) }
variable "database_security_group_id" { type = string }
variable "database_master_username" { type = string }
variable "database_master_password" {
  type      = string
  sensitive = true
}
