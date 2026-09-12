output "edge" {
  value = {
    distribution_id              = module.edge.distribution_id
    distribution_domain_name     = module.edge.distribution_domain_name
    origin_header_parameter_name = module.edge.origin_header_parameter_name
  }
}
