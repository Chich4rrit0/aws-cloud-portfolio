output "foundation" {
  description = "Non-secret values needed by the subsequent E2E stages."
  value = {
    vpc_id                        = module.network.vpc_id
    public_edge_subnet_ids        = module.network.public_edge_subnet_ids
    public_application_subnet_ids = module.network.public_application_subnet_ids
    database_security_group_id    = module.security.database_security_group_id
    application_security_group_id = module.security.application_security_group_id
    ec2_instance_profile_name     = module.security.ec2_instance_profile_name
    artifact_bucket_name          = module.storage.artifact_bucket_name
    frontend_bucket_name          = module.storage.frontend_bucket_name
    database_endpoint_address     = module.data.endpoint_address
  }
}
