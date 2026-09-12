output "runtime" {
  value = { alb_dns_name = module.compute.load_balancer_dns_name, listener_arn = module.compute.listener_arn, target_group_arn = module.compute.target_group_arn }
}
