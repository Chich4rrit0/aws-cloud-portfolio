variable "project_prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string

  validation {
    condition     = can(cidrsubnet(var.vpc_cidr, 8, 21)) && split("/", var.vpc_cidr)[1] == "16"
    error_message = "The Project 03 network topology requires a valid /16 VPC CIDR."
  }
}

variable "availability_zones" {
  description = "Exactly two verified AZ labels in the selected AWS account."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Exactly two availability zones are required."
  }
}
