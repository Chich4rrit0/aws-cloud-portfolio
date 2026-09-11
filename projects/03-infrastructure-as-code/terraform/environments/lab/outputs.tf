output "terraform_state_mode" {
  description = "State remains local until a separate remote-backend decision is approved."
  value       = "local-default-backend"
}

output "deployment_scope" {
  description = "Confirms that this root configuration is for the isolated Project 03 lab."
  value       = "project-03-${var.environment}-${var.aws_region}"
}

output "network" {
  description = "Non-sensitive outputs consumed by the remaining Terraform modules."
  value = {
    vpc_id                        = module.network.vpc_id
    public_edge_subnet_ids        = module.network.public_edge_subnet_ids
    public_application_subnet_ids = module.network.public_application_subnet_ids
    private_database_subnet_ids   = module.network.private_database_subnet_ids
  }
}

output "security" {
  description = "Non-sensitive security and runtime-identity outputs for dependent modules."
  value = {
    load_balancer_security_group_id = module.security.load_balancer_security_group_id
    application_security_group_id   = module.security.application_security_group_id
    database_security_group_id      = module.security.database_security_group_id
    ec2_instance_profile_name       = module.security.ec2_instance_profile_name
  }
}
