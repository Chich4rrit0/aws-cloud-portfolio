# With no backend block, Terraform uses its default local state backend; state files
# are ignored by Git and will never be committed.

module "network" {
  source = "../../modules/network"

  project_prefix     = var.project_prefix
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = [var.availability_zone_a, var.availability_zone_b]
}
