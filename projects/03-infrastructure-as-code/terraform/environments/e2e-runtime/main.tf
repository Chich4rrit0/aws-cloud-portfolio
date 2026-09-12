provider "aws" { region = var.aws_region }
module "compute" {
  source                                       = "../../modules/compute"
  project_prefix                               = var.project_prefix
  environment                                  = "e2e"
  vpc_id                                       = var.vpc_id
  public_edge_subnet_ids                       = var.public_edge_subnet_ids
  public_application_subnet_ids                = var.public_application_subnet_ids
  load_balancer_security_group_id              = var.load_balancer_security_group_id
  application_security_group_id                = var.application_security_group_id
  ec2_instance_profile_name                    = var.ec2_instance_profile_name
  ec2_role_name                                = var.ec2_role_name
  artifact_bucket_name                         = var.artifact_bucket_name
  artifact_bucket_arn                          = var.artifact_bucket_arn
  artifact_key                                 = var.artifact_key
  database_endpoint_address                    = var.database_endpoint_address
  application_database_password_parameter_name = var.application_database_password_parameter_name
}
module "operations" {
  source                  = "../../modules/operations"
  project_prefix          = var.project_prefix
  environment             = "e2e"
  load_balancer_full_name = module.compute.load_balancer_full_name
  target_group_full_name  = module.compute.target_group_full_name
}
