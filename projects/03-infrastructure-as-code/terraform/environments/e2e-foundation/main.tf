provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project       = "aws-cloud-portfolio"
      ProjectNumber = "03"
      Environment   = "e2e"
      ManagedBy     = "terraform"
    }
  }
}

module "network" {
  source             = "../../modules/network"
  project_prefix     = var.project_prefix
  environment        = "e2e"
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "security" {
  source                           = "../../modules/security"
  project_prefix                   = var.project_prefix
  environment                      = "e2e"
  aws_region                       = var.aws_region
  vpc_id                           = module.network.vpc_id
  cloudfront_origin_prefix_list_id = var.cloudfront_origin_prefix_list_id
  database_password_parameter_name = var.application_password_parameter_name
}

module "data" {
  source                      = "../../modules/data"
  project_prefix              = var.project_prefix
  environment                 = "e2e"
  private_database_subnet_ids = module.network.private_database_subnet_ids
  database_security_group_id  = module.security.database_security_group_id
  database_master_username    = var.database_master_username
  database_master_password    = var.database_master_password
}

module "storage" {
  source         = "../../modules/storage"
  project_prefix = var.project_prefix
  environment    = "e2e"
  aws_region     = var.aws_region
}
