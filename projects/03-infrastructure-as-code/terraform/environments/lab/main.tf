# With no backend block, Terraform uses its default local state backend; state files
# are ignored by Git and will never be committed.

module "network" {
  source = "../../modules/network"

  project_prefix     = var.project_prefix
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = [var.availability_zone_a, var.availability_zone_b]
}

module "security" {
  source = "../../modules/security"

  project_prefix                   = var.project_prefix
  environment                      = var.environment
  aws_region                       = var.aws_region
  vpc_id                           = module.network.vpc_id
  cloudfront_origin_prefix_list_id = var.cloudfront_origin_prefix_list_id
  database_password_parameter_name = var.database_password_parameter_name
}

module "data" {
  source = "../../modules/data"

  project_prefix              = var.project_prefix
  environment                 = var.environment
  private_database_subnet_ids = module.network.private_database_subnet_ids
  database_security_group_id  = module.security.database_security_group_id
  database_master_username    = var.database_master_username
  database_master_password    = var.database_master_password
}

module "storage" {
  source = "../../modules/storage"

  project_prefix = var.project_prefix
  environment    = var.environment
  aws_region     = var.aws_region
}

module "compute" {
  source = "../../modules/compute"

  project_prefix                               = var.project_prefix
  environment                                  = var.environment
  vpc_id                                       = module.network.vpc_id
  public_edge_subnet_ids                       = module.network.public_edge_subnet_ids
  public_application_subnet_ids                = module.network.public_application_subnet_ids
  load_balancer_security_group_id              = module.security.load_balancer_security_group_id
  application_security_group_id                = module.security.application_security_group_id
  ec2_instance_profile_name                    = module.security.ec2_instance_profile_name
  ec2_role_name                                = module.security.ec2_role_name
  artifact_bucket_name                         = module.storage.artifact_bucket_name
  artifact_bucket_arn                          = module.storage.artifact_bucket_arn
  artifact_key                                 = var.application_artifact_key
  database_endpoint_address                    = module.data.endpoint_address
  application_database_password_parameter_name = var.application_database_password_parameter_name
}
