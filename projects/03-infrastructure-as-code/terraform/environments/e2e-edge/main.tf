provider "aws" {
  region = var.aws_region
}

module "edge" {
  source                       = "../../modules/edge"
  project_prefix               = var.project_prefix
  environment                  = "e2e"
  frontend_bucket_name         = var.frontend_bucket_name
  frontend_bucket_arn          = var.frontend_bucket_arn
  alb_dns_name                 = var.alb_dns_name
  listener_arn                 = var.listener_arn
  target_group_arn             = var.target_group_arn
  origin_header_parameter_name = var.origin_header_parameter_name
  origin_header_value          = var.origin_header_value
}
